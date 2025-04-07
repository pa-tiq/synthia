import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/file_model.dart';
import '../models/job_status_model.dart';
import 'file_service.dart';
import 'auth_service.dart';

class SummarizationService {
  final String apiUrl;
  final FileService fileService = FileService();
  final AuthService authService = AuthService();

  SummarizationService()
    : apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000';

  // Helper method to execute API calls with token refresh capability
  Future<T> _executeWithTokenRefresh<T>({
    required Future<T> Function(Map<String, String> headers) apiCall,
  }) async {
    try {
      // Get current auth headers
      final authHeaders = await authService.getAuthHeader();

      // Try the API call
      return await apiCall(authHeaders);
    } catch (e) {
      // If we get a 401 error, try to force refresh the token and retry once
      if (e.toString().contains('Server error 401') ||
          e.toString().contains('Unauthorized') ||
          e.toString().contains('Invalid token')) {
        // Force token refresh by clearing the stored token
        final secureStorage = authService.secureStorage;
        await secureStorage.delete(key: AuthService.tokenKey);

        // Get fresh auth headers
        final newAuthHeaders = await authService.getAuthHeader();

        // Retry the API call with the new token
        return await apiCall(newAuthHeaders);
      }

      // For other errors, just rethrow
      rethrow;
    }
  }

  Future<JobStatusModel> summarizeFile(
    FileModel fileModel,
    String targetLanguage,
  ) async {
    try {
      return await _executeWithTokenRefresh<JobStatusModel>(
        apiCall: (authHeaders) async {
          // Submit the file and get the job ID
          String jobId = await _submitFileForSummarization(
            fileModel,
            targetLanguage,
            authHeaders,
          );

          // Poll for the job result
          return await pollForSummary(jobId, authHeaders);
        },
      );
    } catch (e) {
      throw Exception('Error during summarization: $e');
    }
  }

  Future<JobStatusModel> summarizeText(
    String text,
    String targetLanguage,
  ) async {
    try {
      return await _executeWithTokenRefresh<JobStatusModel>(
        apiCall: (authHeaders) async {
          // Submit the text and get the job ID
          String jobId = await _submitTextForSummarization(
            text,
            targetLanguage,
            authHeaders,
          );

          // Poll for the job result
          return await pollForSummary(jobId, authHeaders);
        },
      );
    } catch (e) {
      throw Exception('Error during text summarization: $e');
    }
  }

  Future<String> _submitFileForSummarization(
    FileModel fileModel,
    String targetLanguage,
    Map<String, String> authHeaders,
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

      // Add auth headers
      request.headers.addAll(authHeaders);

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

      // Add file metadata - using snake_case for API compatibility
      request.fields['file_type'] =
          fileModel.type.toString().split('.').last.toLowerCase();
      request.fields['file_name'] = fileModel.name;
      request.fields['target_language'] =
          targetLanguage; // Use the provided language code

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        return jsonData['job_id'];
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
    } on SocketException {
      throw Exception(
        'Network error: Unable to connect to the server. Please check your internet connection.',
      );
    } on HttpException catch (e) {
      throw Exception('HTTP error: $e');
    } on FormatException catch (e) {
      throw Exception('Data format error: $e');
    } catch (e) {
      throw Exception('Error during file submission: $e');
    }
  }

  Future<String> _submitTextForSummarization(
    String text,
    String targetLanguage,
    Map<String, String> authHeaders,
  ) async {
    final response = await http.post(
      Uri.parse('$apiUrl/summarize/text'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        ...authHeaders, // Spread the auth headers
      },
      body: {'text': text, 'target_language': targetLanguage},
    );

    if (response.statusCode == 200) {
      var jsonData = json.decode(response.body);
      return jsonData['job_id'];
    } else {
      throw Exception('Failed to submit text: ${response.statusCode}');
    }
  }

  Future<JobStatusModel> pollForSummary(
    String jobId,
    Map<String, String> authHeaders,
  ) async {
    return await _executeWithTokenRefresh<JobStatusModel>(
      apiCall: (headers) async {
        final response = await http.get(
          Uri.parse('$apiUrl/result/$jobId'),
          headers: headers,
        );

        if (response.statusCode == 200) {
          try {
            final decodedBody = utf8.decode(response.bodyBytes);
            final jobStatus = JobStatusModel.fromJson(json.decode(decodedBody));
            return jobStatus;
          } catch (e) {
            print('Error decoding response: $e');
            throw Exception('Failed to decode response: $e');
          }
        } else {
          throw Exception('Failed to get job status: ${response.statusCode}');
        }
      },
    );
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
}
