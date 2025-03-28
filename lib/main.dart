import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  
  // Pre-initialize encryption service
  final encryptionService = EncryptionService();
  await encryptionService.initialize();
    runApp(const SynthiaApp());
}
