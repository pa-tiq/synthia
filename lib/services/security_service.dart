import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'encryption_service.dart';

class SecurityService {
  final String apiUrl;
  final EncryptionService encryptionService = EncryptionService();

  SecurityService() : apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000';

  Future<RegistrationModel> registerUser() async {
    await encryptionService.initialize();

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/security/register'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final registrationData = json.decode(response.body);

        // Save registration details
        await _saveRegistrationDetails(
          userId: registrationData['user_id'],
          registrationToken: registrationData['registration_token'],
          serverPublicKey: registrationData['server_public_key'],
        );

        return RegistrationModel.fromJson(registrationData);
      } else {
        throw Exception('Failed to register user: ${response.body}');
      }
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

  Future<void> _saveRegistrationDetails({
    required String userId,
    required String registrationToken,
    required String serverPublicKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    await prefs.setString('registration_token', registrationToken);
    await prefs.setString('server_public_key', serverPublicKey);
    await prefs.setString(
      'registration_timestamp',
      DateTime.now().toIso8601String(),
    );
  }

  Future<RegistrationModel?> getCurrentRegistration() async {
    final prefs = await SharedPreferences.getInstance();

    final userId = prefs.getString('user_id');
    final registrationToken = prefs.getString('registration_token');
    final serverPublicKey = prefs.getString('server_public_key');

    if (userId != null &&
        registrationToken != null &&
        serverPublicKey != null) {
      return RegistrationModel(
        userId: userId,
        registrationToken: registrationToken,
        serverPublicKey: serverPublicKey,
      );
    }

    return null;
  }

  Future<bool> isRegistrationValid() async {
    final currentReg = await getCurrentRegistration();

    if (currentReg == null) return false;

    try {
      // Optional: Implement a validation endpoint in your backend
      final response = await http.post(
        Uri.parse('$apiUrl/security/validate'),
        body: {
          'user_id': currentReg.userId,
          'registration_token': currentReg.registrationToken,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> clearRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('registration_token');
    await prefs.remove('server_public_key');
    await prefs.remove('registration_timestamp');
  }

  Future<void> rotateKey(String userId, String registrationToken) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/security/rotate-key'),
        body: {
          'user_id': userId,
          'registration_token': registrationToken,
          'client_public_key': encryptionService.clientPublicKeyPEM,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await encryptionService.setSymmetricKey(
          data['encrypted_symmetric_key'],
          (await getCurrentRegistration())!.serverPublicKey,
        );
      } else {
        throw Exception('Failed to rotate key: ${response.body}');
      }
    } catch (e) {
      throw Exception('Key rotation error: $e');
    }
  }
}

class RegistrationModel {
  final String userId;
  final String registrationToken;
  final String serverPublicKey;

  RegistrationModel({
    required this.userId,
    required this.registrationToken,
    required this.serverPublicKey,
  });

  factory RegistrationModel.fromJson(Map<String, dynamic> json) {
    return RegistrationModel(
      userId: json['user_id'],
      registrationToken: json['registration_token'],
      serverPublicKey: json['server_public_key'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'registration_token': registrationToken,
      'server_public_key': serverPublicKey,
    };
  }
}
