import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/file_model.dart';
import '../models/job_status_model.dart';
import 'file_service.dart';
import 'security_service.dart';
import 'package:flutter/material.dart';
import 'encryption_service.dart';

class SummarizationService {
  final String apiUrl;
  final FileService fileService = FileService();
  final SecurityService securityService = SecurityService();
  final EncryptionService encryptionService = EncryptionService();
  bool _isInitialized = false;

  SummarizationService()
    : apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000';

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await encryptionService.initialize();
      _isInitialized = true;
    }
  }

  Future<JobStatusModel> summarizeFile(
    FileModel fileModel,
    Locale locale,
  ) async {
    try {
      await _ensureInitialized();

      // Ensure user is registered
      var registration = await _ensureRegistration();

      // Submit the file and get the job ID
      String jobId = await _submitFileForSummarization(
        fileModel,
        locale,
        registration,
      );

      // Poll for the job result
      return await pollForSummary(jobId);
    } catch (e) {
      throw Exception('Error during summarization: $e');
    }
  }

  Future<JobStatusModel> summarizeText(String text, Locale locale) async {
    try {
      await _ensureInitialized();

      // Ensure user is registered
      var registration = await _ensureRegistration();

      // Submit the text and get the job ID
      String jobId = await _submitTextForSummarization(
        text,
        locale,
        registration,
      );

      // Poll for the job result
      return await pollForSummary(jobId);
    } catch (e) {
      throw Exception('Error during text summarization: $e');
    }
  }

  Future<RegistrationModel> _ensureRegistration() async {
    // Check if we have a valid registration
    var currentRegistration = await securityService.getCurrentRegistration();
    var isRegistrationValid = await securityService.isRegistrationValid();

    // If no registration or invalid, register a new user
    if (currentRegistration == null || !isRegistrationValid) {
      currentRegistration = await securityService.registerUser();
    }

    return currentRegistration;
  }

  Future<String> _submitFileForSummarization(
    FileModel fileModel,
    Locale locale,
    RegistrationModel registration,
  ) async {
    try {
      // Verify API URL is not empty
      if (apiUrl.isEmpty) {
        throw Exception(
          'API URL is not configured. Please check your .env file.',
        );
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiUrl/summarize'),
      );

      // Add security parameters
      request.fields['user_id'] = registration.userId;
      request.fields['registration_token'] = registration.registrationToken;
      request.fields['client_public_key'] =
          encryptionService.clientPublicKeyPEM;
      request.fields['file_type'] =
          fileModel.type.toString().split('.').last.toLowerCase();
      request.fields['file_name'] = fileModel.name;
      request.fields['target_language'] = locale.toString();

      final payload = json.encode({
        'file_type': fileModel.type.toString().split('.').last.toLowerCase(),
        'file_name': fileModel.name,
        'target_language': locale.toString(),
      });

      request.fields['encrypted_payload'] = encryptionService.encryptPayload(
        payload,
      );

      // Add file to request based on platform
      if (fileModel.bytes != null) {
        // Web platform: use bytes
        String mimeType = fileService.getMimeTypeFromName(fileModel.name);

        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            fileModel.bytes!,
            filename: fileModel.name,
            contentType: _parseContentType(mimeType),
          ),
        );
      } else if (fileModel.file != null) {
        // Native platform: use file path
        File preparedFile = await fileService.prepareFileForUpload(
          fileModel.file!,
        );
        String mimeType = fileService.getMimeType(fileModel.file!);

        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            preparedFile.path,
            contentType: _parseContentType(mimeType),
          ),
        );
      } else {
        throw Exception(
          'File data not available. Both bytes and file are null.',
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);

        // Handle encrypted response
        if (jsonData['encrypted_symmetric_key'] != null) {
          await encryptionService.setSymmetricKey(
            jsonData['encrypted_symmetric_key'],
            registration.serverPublicKey,
          );
        }

        final decryptedResponse = encryptionService.decryptPayload(
          jsonData['encrypted_data'],
        );
        return json.decode(decryptedResponse)['job_id'];
      } else {
        // Handle error with more specific information
        if (response.body.isNotEmpty) {
          try {
            var errorData = json.decode(response.body);
            throw Exception(
              'Server error: ${errorData['detail'] ?? response.body}',
            );
          } catch (_) {
            throw Exception(
              'Server error ${response.statusCode}: ${response.body}',
            );
          }
        } else {
          throw Exception('Server error: Status code ${response.statusCode}');
        }
      }
    } catch (e) {
      if (e.toString().contains('EncryptionService not initialized')) {
        // Try to initialize and retry once
        await encryptionService.initialize();
        return _submitFileForSummarization(fileModel, locale, registration);
      }
      rethrow;
    }
  }

  Future<String> _submitTextForSummarization(
    String text,
    Locale locale,
    RegistrationModel registration,
  ) async {
    final response = await http.post(
      Uri.parse('$apiUrl/summarize/text'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'user_id': registration.userId,
        'registration_token': registration.registrationToken,
        'text': text,
        'target_language': locale.toString(),
      },
    );

    if (response.statusCode == 200) {
      var jsonData = json.decode(response.body);
      return jsonData['job_id'];
    } else {
      throw Exception('Failed to submit text: ${response.statusCode}');
    }
  }

  // Existing methods remain the same
  Future<JobStatusModel> pollForSummary(String jobId) async {
    final response = await http.get(Uri.parse('$apiUrl/result/$jobId'));

    if (response.statusCode == 200) {
      try {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jobStatus = JobStatusModel.fromJson(json.decode(decodedBody));

        print('Summary from poll: ${jobStatus.summary}');
        return jobStatus;
      } catch (e) {
        print('Error decoding response: $e');
        throw Exception('Failed to decode response: $e');
      }
    } else {
      throw Exception('Failed to get job status: ${response.statusCode}');
    }
  }

  // Existing helper method
  MediaType? _parseContentType(String mimeType) {
    try {
      List<String> parts = mimeType.split('/');
      if (parts.length == 2) {
        return MediaType(parts[0], parts[1]);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> checkApiHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$apiUrl/health'))
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              return http.Response('Timeout', 408);
            },
          );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
