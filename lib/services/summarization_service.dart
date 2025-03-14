import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/file_model.dart';
import 'file_service.dart';
import 'package:flutter/material.dart'; // Import to use Locale

class SummarizationService {
  final String apiUrl;
  final FileService fileService = FileService();

  SummarizationService()
    : apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000';

  Future<String> summarizeFile(FileModel fileModel, Locale locale) async {
    try {
      // Verify API URL is not empty
      if (apiUrl.isEmpty) {
        throw Exception(
          'API URL is not configured. Please check your .env file.',
        );
      }

      // Print debug information
      print('Attempting to connect to API at: $apiUrl');
      print(
        'File type: ${fileModel.type.toString().split('.').last.toLowerCase()}',
      );
      print('File name: ${fileModel.name}');

      // Create the request with explicit timeout
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiUrl/summarize'),
      );

      // Add file to request based on platform
      if (fileModel.bytes != null) {
        // Web platform: use bytes
        print('Using bytes for web platform');
        String mimeType = fileService.getMimeTypeFromName(fileModel.name);
        print('MIME type: $mimeType');

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
        print('Using file path for native platform');
        File preparedFile = await fileService.prepareFileForUpload(
          fileModel.file!,
        );
        String mimeType = fileService.getMimeType(fileModel.file!);
        print('MIME type: $mimeType');
        print('File path: ${preparedFile.path}');

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
      request.fields['target_language'] = locale.toString(); // Add language

      // Add timeout to the request
      print('Sending request to $apiUrl/summarize');
      var streamedResponse = await request.send().timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          throw Exception(
            'Request timed out. Please check your network connection or server status.',
          );
        },
      );

      print('Response status code: ${streamedResponse.statusCode}');
      var response = await http.Response.fromStream(streamedResponse);

      // Check response
      if (response.statusCode == 200) {
        try {
          var jsonData = json.decode(response.body);
          print('Successfully decoded JSON response');
          return jsonData['summary'] ?? 'No summary available';
        } catch (e) {
          print('JSON decode error: $e');
          print('Response body: ${response.body}');
          throw Exception('Failed to parse server response: $e');
        }
      } else {
        // Handle error with more specific information
        print('Error response: ${response.statusCode}');
        print('Error body: ${response.body}');

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
    } on SocketException catch (e) {
      print('Socket exception: $e');
      throw Exception(
        'Network error: Unable to connect to the server. Please check your internet connection.',
      );
    } on HttpException catch (e) {
      print('HTTP exception: $e');
      throw Exception('HTTP error: $e');
    } on FormatException catch (e) {
      print('Format exception: $e');
      throw Exception('Data format error: $e');
    } catch (e) {
      print('General exception: $e');
      throw Exception('Error during summarization: $e');
    }
  }

  Future<String> summarizeText(String text, Locale locale) async {
    try {
      print('Sending text to $apiUrl/summarize/text');

      final response = await http
          .post(
            Uri.parse('$apiUrl/summarize/text'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {
              'text': text,
              'target_language': locale.toString(),
            }, // Add language
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Request timed out. Please check your network connection or server status.',
              );
            },
          );

      print('Text summarization response code: ${response.statusCode}');

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        return jsonData['summary'];
      } else {
        throw Exception('Failed to summarize text: ${response.statusCode}');
      }
    } catch (e) {
      print('Text summarization error: $e');
      throw Exception('Error during text summarization: $e');
    }
  }

  Future<bool> checkApiHealth() async {
    try {
      print('Checking API health at $apiUrl/health');
      final response = await http
          .get(Uri.parse('$apiUrl/health'))
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              print('Health check timed out');
              return http.Response('Timeout', 408);
            },
          );

      print('Health check response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Health check error: $e');
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
      print('Error parsing content type: $e');
      return null;
    }
  }
}
