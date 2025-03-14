import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:synthia/widgets/api_debug_widget.dart';
import '../models/file_model.dart';
import '../widgets/file_selector_button.dart';
import '../widgets/file_info_card.dart';
import '../widgets/error_wrapper.dart';
import '../services/summarization_service.dart';
import '../widgets/summarization_button.dart';
import '../widgets/summary_result_widget.dart';
import '../widgets/feature_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  FileModel? selectedFile;
  String? summary;
  bool isLoading = false;

  final SummarizationService _summarizationService = SummarizationService();

  void _handleFileSelected(FileModel fileModel) {
    setState(() {
      selectedFile = fileModel;
      summary = null;
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
      isLoading = true;
    });

    try {
      final result = await _summarizationService.summarizeFile(selectedFile!);
      setState(() {
        summary = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
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
            content: Text(localizations.aboutContent),
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
                  const SizedBox(height: 24),
                  Text(
                    localizations.mainHeading,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.subHeading,
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  FileSelectorButton(onFileSelected: _handleFileSelected),
                  if (selectedFile != null) ...[
                    const SizedBox(height: 24),
                    FileInfoCard(fileModel: selectedFile!),
                    const SizedBox(height: 16),
                    SummarizationButton(
                      isLoading: isLoading,
                      onPressed: _summarizeFile,
                    ),
                    const ApiDebugWidget(),
                  ],
                  if (summary != null) ...[
                    SummaryResultWidget(
                      summary: summary!,
                      localizations: localizations,
                    ),
                  ],
                  if (selectedFile == null && summary == null) ...[
                    const SizedBox(height: 64),
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
