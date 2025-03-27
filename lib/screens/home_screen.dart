import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/file_model.dart';
import '../models/job_status_model.dart';
import '../widgets/file_selector_button.dart';
import '../widgets/file_info_card.dart';
import '../widgets/error_wrapper.dart';
import '../services/summarization_service.dart';
import '../widgets/summarization_button.dart';
import '../widgets/summary_result_widget.dart';
import '../widgets/synthia_mascot.dart';
import '../widgets/feature_section.dart';
import '../widgets/speech_bubble.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  FileModel? selectedFile;
  String? summary;
  JobStatus jobStatus = JobStatus.idle;
  JobStatusModel? jobStatusModel;
  String? jobId;

  final SummarizationService _summarizationService = SummarizationService();

  void _handleFileSelected(FileModel fileModel) {
    setState(() {
      selectedFile = fileModel;
      summary = null;
      jobStatus = JobStatus.idle;
      jobId = null;
    });
  }

  Future<void> _summarizeFile() async {
    if (selectedFile == null) {
      ErrorWrapper(
        context,
      ).showError(AppLocalizations.of(context)!.pleaseSelectFile);
      return;
    }

    setState(() {
      jobStatus = JobStatus.queued;
      jobId = null;
    });

    try {
      final locale = Localizations.localeOf(context);
      final JobStatusModel jobStatusResponse = await _summarizationService
          .summarizeFile(selectedFile!, locale);
      jobId = jobStatusResponse.jobId; // Extract jobId from JobStatusModel
      setState(() {
        jobStatus = JobStatus.processing;
      });
      _checkJobStatus();
    } catch (e) {
      setState(() {
        jobStatus = JobStatus.failed;
      });
      ErrorWrapper(context).showError(
        AppLocalizations.of(context)!.failedToSummarize(e.toString()),
      );
    }
  }

  Future<void> _checkJobStatus() async {
    if (jobId == null) return;

    try {
      jobStatusModel = await _summarizationService.pollForSummary(jobId!);
      setState(() {
        jobStatus = jobStatusModel!.status;
        summary = jobStatusModel!.summary;
      });
      if (jobStatus == JobStatus.processing) {
        await Future.delayed(const Duration(seconds: 2));
        _checkJobStatus();
      }
    } catch (e) {
      setState(() {
        jobStatus = JobStatus.failed;
      });
      ErrorWrapper(context).showError(
        AppLocalizations.of(context)!.failedToSummarize(e.toString()),
      );
    }
  }

  void _showAboutDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(localizations.aboutTitle),
            content: Text(
              localizations.aboutContent,
              style: const TextStyle(color: Colors.black87),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localizations.closeButton),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final bool isProcessing =
        jobStatus == JobStatus.queued || jobStatus == JobStatus.processing;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAboutDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SpeechBubble(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          localizations.mainHeading,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          localizations.subHeading,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  SynthiaMascot(width: 80, height: 80),
                  const SizedBox(height: 10),
                  // Only show the file selector when not processing
                  if (!isProcessing) ...[
                    FileSelectorButton(onFileSelected: _handleFileSelected),
                    const SizedBox(height: 16),
                  ],

                  if (selectedFile != null) ...[
                    FileInfoCard(fileModel: selectedFile!),
                    if (jobStatus == JobStatus.idle) const SizedBox(height: 16),
                    if (!isProcessing) ...[
                      SummarizationButton(
                        isLoading: false,
                        onPressed: _summarizeFile,
                      ),
                    ],
                    if (isProcessing) ...[
                      const SizedBox(height: 16),

                      Text(
                        jobStatus == JobStatus.queued
                            ? localizations.queuedMessage
                            : localizations.processingMessage,
                      ),
                      //if (jobId != null) Text('Job ID: $jobId'),
                    ],
                    if (jobStatus == JobStatus.failed) ...[
                      const SizedBox(height: 16),

                      Text(localizations.failedMessage),
                      if (jobStatusModel?.error != null)
                        Text('Error: ${jobStatusModel?.error}'),
                    ],
                  ],
                  // Only show summary result widget once, and only when completed
                  if (jobStatus == JobStatus.completed && summary != null) ...[
                    const SizedBox(height: 5),

                    SummaryResultWidget(
                      summary: summary!,
                      localizations: localizations,
                    ),
                  ],
                  if (selectedFile == null && summary == null) ...[
                    FeatureSection(localizations: localizations),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
