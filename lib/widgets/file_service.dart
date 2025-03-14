import 'dart:io';
import 'package:path/path.dart' as path;

class FileService {
  // Validate file size
  bool isValidFileSize(File file, {bool isPremium = false}) {
    final int maxSizeInBytes =
        isPremium
            ? 50 *
                1024 *
                1024 // 50 MB for premium
            : 10 * 1024 * 1024; // 10 MB for free tier

    return file.lengthSync() <= maxSizeInBytes;
  }

  // Get MIME type of file
  String getMimeType(File file) {
    final extension = path.extension(file.path).toLowerCase();

    switch (extension) {
      case '.pdf':
        return 'application/pdf';
      case '.txt':
        return 'text/plain';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.opus':
        return 'audio/opus';
      case '.m4a':
        return 'audio/m4a';
      default:
        return 'application/octet-stream';
    }
  }

  // Prepare file for upload (could compress or convert in the future)
  Future<File> prepareFileForUpload(File file) async {
    // For now, we're just returning the original file
    // In the future, you could add compression, conversion, etc.
    return file;
  }
}
