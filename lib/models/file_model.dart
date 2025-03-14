import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;

enum FileType { audio, image, text, pdf, unknown }

class FileModel {
  final String name;
  final String path;
  final int size;
  final String extension;
  final FileType type;
  final DateTime? lastModified; // Make lastModified nullable
  final Uint8List? bytes; // Add bytes property
  final File? file; // Make file nullable

  FileModel({
    required this.name,
    required this.path,
    required this.size,
    required this.extension,
    required this.type,
    this.lastModified,
    this.bytes,
    this.file,
  });

  // Factory constructor to create a FileModel from a File (native)
  factory FileModel.fromFile(File file) {
    String fileExt = p.extension(file.path).toLowerCase().replaceAll('.', '');

    return FileModel(
      file: file,
      name: p.basename(file.path),
      path: file.path,
      size: file.lengthSync(),
      extension: fileExt,
      type: _determineFileType(fileExt),
      lastModified: file.lastModifiedSync(),
      bytes: null,
    );
  }

  // Factory constructor to create a FileModel from bytes (web)
  factory FileModel.fromBytes(Uint8List bytes, String fileName) {
    String fileExt = p.extension(fileName).toLowerCase().replaceAll('.', '');

    return FileModel(
      file: null,
      name: fileName,
      path: '', // Path is not available on web
      size: bytes.length,
      extension: fileExt,
      type: _determineFileType(fileExt),
      lastModified: null, // Last modified is not available on web
      bytes: bytes,
    );
  }

  // Helper method to determine file type based on extension
  static FileType _determineFileType(String extension) {
    if (['pdf'].contains(extension)) {
      return FileType.pdf;
    } else if (['txt', 'doc', 'docx', 'rtf'].contains(extension)) {
      return FileType.text;
    } else if (['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(extension)) {
      return FileType.image;
    } else if ([
      'mp3',
      'wav',
      'opus',
      'm4a',
      'aac',
      'ogg',
    ].contains(extension)) {
      return FileType.audio;
    } else {
      return FileType.unknown;
    }
  }

  // Helper method to get formatted file size
  String get formattedSize {
    const int kb = 1024;
    const int mb = kb * 1024;

    if (size < kb) {
      return '$size B';
    } else if (size < mb) {
      return '${(size / kb).toStringAsFixed(1)} KB';
    } else {
      return '${(size / mb).toStringAsFixed(1)} MB';
    }
  }

  // Helper method to check if file is too large for free tier
  bool get isTooBigForFreeTier {
    const int maxSizeInBytes = 10 * 1024 * 1024; // 10MB
    return size > maxSizeInBytes;
  }
}
