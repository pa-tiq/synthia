import 'package:flutter/material.dart';
import '../models/file_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:just_audio/just_audio.dart';

class FileInfoCard extends StatefulWidget {
  final FileModel fileModel;

  const FileInfoCard({super.key, required this.fileModel});

  @override
  _FileInfoCardState createState() => _FileInfoCardState();
}

class _FileInfoCardState extends State<FileInfoCard> {
  Duration? _audioDuration;

  @override
  void initState() {
    super.initState();
    _fetchAudioDuration();
  }

  Future<void> _fetchAudioDuration() async {
    if (widget.fileModel.type == FileType.audio) {
      try {
        final player = AudioPlayer();
        final duration = await player.setFilePath(widget.fileModel.path);
        await player.stop();
        await player.dispose();

        if (mounted) {
          setState(() {
            _audioDuration = duration;
          });
        }
      } catch (e) {
        print('Error fetching audio duration: $e');
      }
    }
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '—';

    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

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
                        widget.fileModel.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.fileModel.formattedSize} • ${widget.fileModel.extension.toUpperCase()}',
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
              _getFileTypeString(widget.fileModel.type, localizations),
            ),
            _buildInfoRow(
              context,
              localizations.lastModifiedLabel,
              DateFormat(
                'MMM dd, yyyy • hh:mm a',
                localizations.localeName,
              ).format(widget.fileModel.lastModified ?? DateTime.now()),
            ),
            // _buildInfoRow(
            //   context,
            //   localizations.locationLabel,
            //   widget.fileModel.path,
            //   isPath: true,
            // ),
            if (widget.fileModel.type == FileType.audio)
              _buildInfoRow(
                context,
                localizations
                    .audioDurationLabel, // Add this to your localization
                _formatDuration(_audioDuration),
              ),
            if (widget.fileModel.isTooBigForFreeTier)
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

    switch (widget.fileModel.type) {
      case FileType.audio:
        iconData = Icons.audio_file;
        break;
      case FileType.image:
        iconData = Icons.image;
        break;
      case FileType.text:
        iconData = Icons.description;
        break;
      case FileType.pdf:
        iconData = Icons.picture_as_pdf;
        break;
      case FileType.unknown:
        iconData = Icons.insert_drive_file;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Icon(iconData, size: 32),
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
