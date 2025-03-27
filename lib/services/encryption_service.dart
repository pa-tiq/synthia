import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:shared_preferences/shared_preferences.dart';

class EncryptionService {
  late AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> _clientKeyPair;
  encrypt.Key? _currentSymmetricKey;

  Future<void> initialize() async {
    // Generate client key pair
    _clientKeyPair = _generateRSAKeyPair();
  }

  String get clientPublicKeyPEM {
    return _encodePublicKeyToPem(_clientKeyPair.publicKey);
  }

  AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> _generateRSAKeyPair() {
    final keyGen =
        RSAKeyGenerator()..init(
          ParametersWithRandom(
            RSAKeyGenerationParameters(BigInt.parse('65537'), 2048, 64),
            SecureRandom('Fortuna')..seed(
              KeyParameter(
                Platform.instance.platformEntropySource().getBytes(32),
              ),
            ),
          ),
        );

    return keyGen.generateKeyPair();
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

    final bytes = asn1Sequence.encode();
    final base64 = base64Encode(bytes);

    return '''-----BEGIN PUBLIC KEY-----\n$base64\n-----END PUBLIC KEY-----''';
  }
}
