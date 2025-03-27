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

class EncryptionService {
  late AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> _clientKeyPair;
  encrypt.Key? _currentSymmetricKey;

  Future<void> initialize() async {
    // Generate client key pair
    _clientKeyPair = await _generateRSAKeyPair();
  }

  String get clientPublicKeyPEM {
    return _encodePublicKeyToPem(_clientKeyPair.publicKey);
  }

  Future<AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>>
  _generateRSAKeyPair() async {
    final secureRandom = FortunaRandom();
    final seedSource = Random.secure();
    final seeds = List<int>.generate(32, (_) => seedSource.nextInt(256));
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    final keyParams = RSAKeyGeneratorParameters(BigInt.from(65537), 2048, 64);
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
    try {
      // Decrypt the symmetric key using our private key
      final decryptedKey = _decryptWithPrivateKey(
        base64.decode(encryptedKey),
        _clientKeyPair.privateKey,
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
      throw Exception('No symmetric key available');
    }

    final encrypter = encrypt.Encrypter(encrypt.Fernet(_currentSymmetricKey!));

    final encrypted = encrypter.encrypt(payload);
    return base64.encode(encrypted.bytes);
  }

  String decryptPayload(String encryptedPayload) {
    if (_currentSymmetricKey == null) {
      throw Exception('No symmetric key available');
    }

    final encrypter = encrypt.Encrypter(encrypt.Fernet(_currentSymmetricKey!));

    final encrypted = encrypt.Encrypted(base64.decode(encryptedPayload));
    return encrypter.decrypt(encrypted);
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

  String _encodePublicKeyToPem(RSAPublicKey publicKey) {
    final asn1Sequence = ASN1Sequence();
    asn1Sequence.add(ASN1Integer(publicKey.modulus!));
    asn1Sequence.add(ASN1Integer(publicKey.exponent!));

    final bytes = asn1Sequence.encodedBytes;
    final base64Data = base64Encode(bytes);

    return '''-----BEGIN PUBLIC KEY-----\n$base64Data\n-----END PUBLIC KEY-----''';
  }
}
