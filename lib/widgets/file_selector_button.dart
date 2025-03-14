import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'
    as file_picker; // Import with prefix
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/file_model.dart';
import '../config/constants.dart';
import 'error_wrapper.dart';

class FileSelectorButton extends StatelessWidget {
  final Function(FileModel) onFileSelected;

  const FileSelectorButton({super.key, required this.onFileSelected});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _pickFile(context),
      icon: const Icon(Icons.upload_file),
      label: Text(AppLocalizations.of(context)!.chooseFileButton),
    );
  }

  Future<void> _pickFile(BuildContext context) async {
    try {
      file_picker.FilePickerResult? result = await file_picker
          .FilePicker
          .platform
          .pickFiles(
            type: file_picker.FileType.custom,
            allowedExtensions: AppConstants.supportedFileTypes,
          );

      if (result != null) {
        final file_picker.PlatformFile fileResult =
            result.files.single; // Use file_picker.PlatformFile

        if (fileResult.bytes != null) {
          // Web platform: use bytes
          Uint8List bytes = fileResult.bytes!;
          String fileName = fileResult.name;
          FileModel fileModel = FileModel.fromBytes(bytes, fileName);

          // Check if file type is supported
          if (fileModel.type == FileType.unknown) {
            ErrorWrapper(
              context,
            ).showError(AppConstants.invalidFileTypeMessage);
            return;
          }

          onFileSelected(fileModel);
        } else if (fileResult.path != null) {
          // Native platform: use path
          File file = File(fileResult.path!);
          FileModel fileModel = FileModel.fromFile(file);

          // Check if file type is supported
          if (fileModel.type == FileType.unknown) {
            ErrorWrapper(
              context,
            ).showError(AppConstants.invalidFileTypeMessage);
            return;
          }

          onFileSelected(fileModel);
        } else {
          // Handle the case where neither bytes nor path is available
          ErrorWrapper(context).showError('File data not available.');
        }
      }
    } catch (e) {
      ErrorWrapper(context).showError(
        AppLocalizations.of(context)!.failedToSummarize(e.toString()),
      );
    }
  }
}
