import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SummaryResultWidget extends StatelessWidget {
  final String summary;
  final AppLocalizations localizations;

  const SummaryResultWidget({
    super.key,
    required this.summary,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 16),
        Text(
          localizations.summaryTitle,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            summary,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Implement copy to clipboard
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(localizations.copiedMessage)),
                );
              },
              icon: const Icon(Icons.copy),
              label: Text(localizations.copyButton),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Implement share functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(localizations.sharingMessage)),
                );
              },
              icon: const Icon(Icons.share),
              label: Text(localizations.shareButton),
            ),
          ],
        ),
      ],
    );
  }
}
