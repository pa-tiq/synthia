import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FeatureSection extends StatelessWidget {
  final AppLocalizations localizations;

  const FeatureSection({super.key, required this.localizations});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                context,
                Icons.description_outlined,
                localizations.documentsTitle,
                localizations.documentsDescription,
              ),
            ),
            Expanded(
              child: _buildFeatureCard(
                context,
                Icons.image_outlined,
                localizations.imagesTitle,
                localizations.imagesDescription,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                context,
                Icons.headphones_outlined,
                localizations.audioTitle,
                localizations.audioDescription,
              ),
            ),
            Expanded(
              child: _buildFeatureCard(
                context,
                Icons.privacy_tip_outlined,
                localizations.privacyTitle,
                localizations.privacyDescription,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Theme.of(context).primaryColor),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
