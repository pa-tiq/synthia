import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart'; // Add this package

class AuthService {
  final String apiUrl;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  // Security keys
  static const String deviceIdKey = 'device_id';
  static const String tokenKey = 'auth_token';

  AuthService() : apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000';

  // Check if token is still valid or needs refresh
  Future<String> getAuthToken() async {
    try {
      String? token = await secureStorage.read(key: tokenKey);

      // If no token exists or token is expired, we need a new one
      if (token == null || JwtDecoder.isExpired(token)) {
        // Try to use existing device ID if we have one
        String? deviceId = await secureStorage.read(key: deviceIdKey);

        if (deviceId != null) {
          // Device exists, try to refresh token
          token = await _refreshToken(deviceId);
        } else {
          // First time usage, register new device
          var credentials = await _registerNewDevice();
          deviceId = credentials['device_id'];
          token = credentials['token'];

          // Store the device ID
          await secureStorage.write(key: deviceIdKey, value: deviceId);
        }

        // Store the new token
        await secureStorage.write(key: tokenKey, value: token);
      }

      if (token == null) {
        throw Exception('Token is null');
      }
      return token;
    } catch (e) {
      // If any errors occur, clear stored values and try again from scratch
      await secureStorage.delete(key: tokenKey);
      throw Exception('Authentication error: $e');
    }
  }

  // Get full authorization header for API requests
  Future<Map<String, String>> getAuthHeader() async {
    String token = await getAuthToken();
    return {'Authorization': 'Bearer $token'};
  }

  // Register a new anonymous device
  Future<Map<String, String>> _registerNewDevice() async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/register'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        return {'device_id': jsonData['device_id'], 'token': jsonData['token']};
      } else {
        throw Exception('Failed to register: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

  // Refresh token using existing device ID
  Future<String> _refreshToken(String deviceId) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/refresh-token'),
        headers: {'Content-Type': 'application/json', 'X-Device-ID': deviceId},
      );

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        return jsonData['token'];
      } else {
        // If refresh fails, we'll need to register a new device
        throw Exception('Token refresh failed');
      }
    } catch (e) {
      throw Exception('Token refresh error: $e');
    }
  }
}
