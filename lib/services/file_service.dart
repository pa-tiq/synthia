import 'dart:io';
import 'package:mime/mime.dart';

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

  // Get MIME type of file from File object
  String getMimeType(File file) {
    return lookupMimeType(file.path) ?? 'application/octet-stream';
  }

  // Get MIME type from file name (for web)
  String getMimeTypeFromName(String fileName) {
    return lookupMimeType(fileName) ?? 'application/octet-stream';
  }

  // Prepare file for upload (could compress or convert in the future)
  Future<File> prepareFileForUpload(File file) async {
    // For now, we're just returning the original file
    // In the future, you could add compression, conversion, etc.
    return file;
  }
}
