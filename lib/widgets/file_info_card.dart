import 'package:flutter/material.dart';
import '../models/file_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FileInfoCard extends StatelessWidget {
  final FileModel fileModel;

  const FileInfoCard({super.key, required this.fileModel});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getFileIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileModel.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${fileModel.formattedSize} • ${fileModel.extension.toUpperCase()}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              localizations.typeLabel,
              _getFileTypeString(fileModel.type, localizations),
            ),
            _buildInfoRow(
              context,
              localizations.lastModifiedLabel,
              DateFormat(
                'MMM dd, yyyy • hh:mm a',
                localizations.localeName,
              ).format(fileModel.lastModified ?? DateTime.now()),
            ),
            _buildInfoRow(
              context,
              localizations.locationLabel,
              fileModel.path,
              isPath: true,
            ),
            if (fileModel.isTooBigForFreeTier)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        localizations.fileSizeExceedsFreeTier,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _getFileIcon() {
    IconData iconData;
    Color iconColor;

    switch (fileModel.type) {
      case FileType.audio:
        iconData = Icons.audio_file;
        iconColor = Colors.blue;
        break;
      case FileType.image:
        iconData = Icons.image;
        iconColor = Colors.green;
        break;
      case FileType.text:
        iconData = Icons.description;
        iconColor = Colors.orange;
        break;
      case FileType.pdf:
        iconData = Icons.picture_as_pdf;
        iconColor = Colors.red;
        break;
      case FileType.unknown:
        iconData = Icons.insert_drive_file;
        iconColor = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, color: iconColor, size: 32),
    );
  }

  String _getFileTypeString(FileType type, AppLocalizations localizations) {
    switch (type) {
      case FileType.audio:
        return localizations.audioFileType;
      case FileType.image:
        return localizations.imageFileType;
      case FileType.text:
        return localizations.textFileType;
      case FileType.pdf:
        return localizations.pdfFileType;
      case FileType.unknown:
        return localizations.unknownFileType;
    }
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    bool isPath = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge,
              overflow: isPath ? TextOverflow.ellipsis : TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }
}
