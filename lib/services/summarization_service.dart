import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/file_model.dart';
import 'file_service.dart';

class SummarizationService {
  final String apiUrl;
  final FileService fileService = FileService();

  SummarizationService() : apiUrl = dotenv.env['API_URL']!;

  Future<String> summarizeFile(FileModel fileModel) async {
    try {
      // Prepare the HTTP request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiUrl/summarize'),
      );

      // Add file to request
      if (fileModel.bytes != null) {
        // Web platform: use bytes
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            fileModel.bytes!,
            filename: fileModel.name,
            contentType: _parseContentType(
              fileService.getMimeTypeFromName(fileModel.name),
            ),
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
        throw Exception('File data not available.');
      }

      // Add file metadata as form fields
      request.fields['file_type'] =
          fileModel.type.toString().split('.').last.toLowerCase();
      request.fields['file_name'] = fileModel.name;

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // Check response
      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        return jsonData['summary'];
      } else {
        // Handle error with more specific information
        if (response.body.isNotEmpty) {
          try {
            var errorData = json.decode(response.body);
            throw Exception('Summarization failed: ${errorData['detail']}');
          } catch (e) {
            throw Exception(
              'Summarization failed: ${response.statusCode} - ${response.body}',
            );
          }
        } else {
          throw Exception('Summarization failed: ${response.statusCode}');
        }
      }
    } catch (e) {
      throw Exception('Error during summarization: $e');
    }
  }

  Future<String> summarizeText(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/summarize/text'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'text': text},
      );

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        return jsonData['summary'];
      } else {
        throw Exception('Failed to summarize text: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error during text summarization: $e');
    }
  }

  Future<bool> checkApiHealth() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/health'));
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
      print('Error parsing content type: $e');
      return null;
    }
  }
}
