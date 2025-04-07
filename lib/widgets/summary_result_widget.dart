import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart';

class SummaryResultWidget extends StatelessWidget {
  final String summary;
  final AppLocalizations localizations;

  const SummaryResultWidget({
    super.key,
    required this.summary,
    required this.localizations,
  });

  // Copy summary to clipboard
  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: summary));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(localizations.copiedMessage)));
  }

  // Share summary (mobile only)
  void _shareSummary() {
    Share.share(summary);
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we're on web platform
    final bool isWeb = kIsWeb;

    return Column(
      children: [
        // const Divider(),
        // Text(
        //   localizations.summaryTitle,
        //   style: const TextStyle(
        //     fontSize: 20,
        //     fontWeight: FontWeight.bold,
        //     color: Colors.black54,
        //   ),
        // ),
        // const SizedBox(height: 16),
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
          child: Text.rich(
            TextSpan(
              text: summary,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.black,
                fontFamily: 'Roboto',
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () => _copyToClipboard(context),
              icon: const Icon(Icons.copy),
              label: Text(localizations.copyButton),
            ),
            // Only show share button on mobile platforms
            if (!isWeb) ...[
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: _shareSummary,
                icon: const Icon(Icons.share),
                label: Text(localizations.shareButton),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
