import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:asn1lib/asn1lib.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class EncryptionService {
  AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>? _clientKeyPair;
  encrypt.Key? _currentSymmetricKey;
  bool _isInitialized = false;

  static const String _privateKeyKey = 'private_key';
  static const String _publicKeyKey = 'public_key';

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Try to load existing key pair
    final prefs = await SharedPreferences.getInstance();
    final savedPrivateKey = prefs.getString(_privateKeyKey);
    final savedPublicKey = prefs.getString(_publicKeyKey);

    if (savedPrivateKey != null && savedPublicKey != null) {
      try {
        // Load existing keys
        _clientKeyPair = await _loadKeyPair(savedPrivateKey, savedPublicKey);
        _isInitialized = true;
        return;
      } catch (e) {
        // If loading fails, generate new keys
        print('Failed to load existing keys: $e');
      }
    }

    // Generate new key pair if none exists
    _clientKeyPair = await _generateRSAKeyPair();
    // Save the new key pair
    await _saveKeyPair(_clientKeyPair!);

    _isInitialized = true;
  }

  Future<void> _saveKeyPair(
    AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> keyPair,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    // Convert keys to PEM format
    final privateKeyPem = _encodePrivateKeyToPem(keyPair.privateKey);
    final publicKeyPem = _encodePublicKeyToPem(keyPair.publicKey);

    // Save to shared preferences
    await prefs.setString(_privateKeyKey, privateKeyPem);
    await prefs.setString(_publicKeyKey, publicKeyPem);
  }

  Future<AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>> _loadKeyPair(
    String privateKeyPem,
    String publicKeyPem,
  ) async {
    final privateKey = _decodePrivateKeyFromPem(privateKeyPem);
    final publicKey = _decodePublicKeyFromPem(publicKeyPem);

    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(
      publicKey,
      privateKey,
    );
  }

  // Add these helper methods for PEM encoding/decoding
  String _encodePublicKeyToPem(RSAPublicKey publicKey) {
    final asn1Sequence = ASN1Sequence();
    asn1Sequence.add(ASN1Integer(publicKey.modulus!));
    asn1Sequence.add(ASN1Integer(publicKey.exponent!));

    final bytes = asn1Sequence.encodedBytes;
    final base64 = base64Encode(bytes);
    return '''-----BEGIN RSA PUBLIC KEY-----\n$base64\n-----END RSA PUBLIC KEY-----''';
  }

  String _encodePrivateKeyToPem(RSAPrivateKey privateKey) {
    final asn1Sequence = ASN1Sequence();
    asn1Sequence.add(ASN1Integer(BigInt.from(0))); // Version
    asn1Sequence.add(ASN1Integer(privateKey.modulus!));
    asn1Sequence.add(ASN1Integer(privateKey.publicExponent!));
    asn1Sequence.add(ASN1Integer(privateKey.privateExponent!));
    asn1Sequence.add(ASN1Integer(privateKey.p!));
    asn1Sequence.add(ASN1Integer(privateKey.q!));
    asn1Sequence.add(
      ASN1Integer(privateKey.privateExponent! % (privateKey.p! - BigInt.one)),
    ); // dmp1
    asn1Sequence.add(
      ASN1Integer(privateKey.privateExponent! % (privateKey.q! - BigInt.one)),
    ); // dmq1
    asn1Sequence.add(
      ASN1Integer(privateKey.q!.modInverse(privateKey.p!)),
    ); // iqmp

    final bytes = asn1Sequence.encodedBytes;
    final base64 = base64Encode(bytes);
    return '''-----BEGIN RSA PRIVATE KEY-----\n${_formatBase64String(base64)}\n-----END RSA PRIVATE KEY-----''';
  }

  RSAPrivateKey _decodePrivateKeyFromPem(String pem) {
    // Remove headers and decode base64
    final lines = pem.split('\n');
    final keyB64 = lines.where((line) => !line.contains('--')).join('');
    final keyBytes = base64Decode(keyB64);

    // Parse ASN.1 sequence
    final asn1Parser = ASN1Parser(keyBytes);
    final topSequence = asn1Parser.nextObject() as ASN1Sequence;

    // Extract components
    final version = (topSequence.elements![0] as ASN1Integer).valueAsBigInteger;
    final modulus = (topSequence.elements![1] as ASN1Integer).valueAsBigInteger;
    final publicExponent =
        (topSequence.elements![2] as ASN1Integer).valueAsBigInteger;
    final privateExponent =
        (topSequence.elements![3] as ASN1Integer).valueAsBigInteger;
    final p = (topSequence.elements![4] as ASN1Integer).valueAsBigInteger;
    final q = (topSequence.elements![5] as ASN1Integer).valueAsBigInteger;

    return RSAPrivateKey(modulus!, privateExponent!, p, q);
  }

  RSAPublicKey _decodePublicKeyFromPem(String pem) {
    // Remove headers and decode base64
    final lines = pem.split('\n');
    final keyB64 = lines.where((line) => !line.contains('--')).join('');
    final keyBytes = base64Decode(keyB64);

    // Parse ASN.1 sequence
    final asn1Parser = ASN1Parser(keyBytes);
    final topSequence = asn1Parser.nextObject() as ASN1Sequence;

    // Extract components
    final modulus = (topSequence.elements![0] as ASN1Integer).valueAsBigInteger;
    final exponent =
        (topSequence.elements![1] as ASN1Integer).valueAsBigInteger;

    return RSAPublicKey(modulus!, exponent!);
  }

  String get clientPublicKeyPEM {
    if (_clientKeyPair == null) {
      throw Exception('EncryptionService not initialized');
    }
    return _encodePublicKeyToPem(_clientKeyPair!.publicKey);
  }

  AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> _generateRSAKeyPair() {
    final secureRandom = FortunaRandom();
    final seedSource = Random.secure();
    final seeds = List<int>.generate(32, (_) => seedSource.nextInt(256));
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    final keyParams = RSAKeyGeneratorParameters(BigInt.from(65537), 1024, 64);
    final parameterWithRandom = ParametersWithRandom(keyParams, secureRandom);

    final keyGenerator = RSAKeyGenerator();
    keyGenerator.init(parameterWithRandom);

    final pair = keyGenerator.generateKeyPair();

    // Cast the general key pair to our specific RSA key pair type
    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(
      pair.publicKey as RSAPublicKey,
      pair.privateKey as RSAPrivateKey,
    );
  }

  Future<void> setSymmetricKey(
    String encryptedKey,
    String serverPublicKeyPEM,
  ) async {
    if (_clientKeyPair == null) {
      throw Exception('EncryptionService not initialized');
    }

    try {
      // Decrypt the symmetric key using our private key
      final decryptedKey = _decryptWithPrivateKey(
        base64.decode(encryptedKey),
        _clientKeyPair!.privateKey,
      );

      // Store the symmetric key
      _currentSymmetricKey = encrypt.Key(decryptedKey);

      // Save encrypted key to secure storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('symmetric_key', encryptedKey);
    } catch (e) {
      throw Exception('Failed to set symmetric key: $e');
    }
  }

  String encryptPayload(String payload) {
    if (_currentSymmetricKey == null) {
      throw Exception(
        'No symmetric key available - please ensure initialization',
      );
    }

    try {
      final encrypter = encrypt.Encrypter(
        encrypt.Fernet(_currentSymmetricKey!),
      );
      final encrypted = encrypter.encrypt(payload);
      return encrypted.base64;
    } catch (e) {
      throw Exception('Failed to encrypt payload: $e');
    }
  }

  String decryptPayload(String encryptedPayload) {
    if (_currentSymmetricKey == null) {
      throw Exception(
        'No symmetric key available - please ensure initialization',
      );
    }

    try {
      final encrypter = encrypt.Encrypter(
        encrypt.Fernet(_currentSymmetricKey!),
      );
      final encrypted = encrypt.Encrypted.fromBase64(encryptedPayload);
      return encrypter.decrypt(encrypted);
    } catch (e) {
      throw Exception('Failed to decrypt payload: $e');
    }
  }

  Uint8List _decryptWithPrivateKey(
    Uint8List encrypted,
    RSAPrivateKey privateKey,
  ) {
    final cipher =
        RSAEngine()
          ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));

    return cipher.process(encrypted);
  }

  String _formatBase64String(String str) {
    const lineLength = 64;
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i += lineLength) {
      buffer.writeln(
        str.substring(
          i,
          i + lineLength > str.length ? str.length : i + lineLength,
        ),
      );
    }
    return buffer.toString();
  }
}
