class AppConstants {
  // File types that the app supports
  static const List<String> supportedFileTypes = [
    'pdf',
    'txt',
    'doc',
    'docx',
    'rtf',
    'jpg',
    'jpeg',
    'png',
    'gif',
    'bmp',
    'mp3',
    'wav',
    'opus',
    'm4a',
    'aac',
    'ogg',
  ];

  // File size limits
  static const int maxFileSizeInMB = 10; // Free tier limit
  static const int maxPremiumFileSizeInMB = 50; // Premium tier limit

  // Messages
  static const String fileTooBigMessage =
      'File is too large for free tier. Maximum size is 10MB.';
  static const String invalidFileTypeMessage =
      'Unsupported file type. Please choose a text, image, audio, or PDF file.';
}
