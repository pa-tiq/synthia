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
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiUrl/summarize'),
      );

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

      // Add file metadata
      request.fields['fileType'] = fileModel.type.toString().split('.').last;
      request.fields['fileName'] = fileModel.name;

      // Send request
      var response = await request.send();

      // Check response
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonData = json.decode(responseData);
        return jsonData['summary'];
      } else {
        throw Exception('Failed to summarize: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error during summarization: $e');
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
