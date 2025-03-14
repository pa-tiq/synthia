import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SummarizationButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const SummarizationButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon:
          isLoading
              ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
              : const Icon(Icons.auto_awesome),
      label: Text(
        isLoading
            ? localizations.summarizingButton
            : localizations.summarizeButton,
      ),
      style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
    );
  }
}
