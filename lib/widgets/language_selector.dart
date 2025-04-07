import 'package:flutter/material.dart';
import '../models/language_model.dart';
import 'package:flag/flag.dart';

class LanguageSelector extends StatefulWidget {
  final String? initialLanguageCode;
  final Function(LanguageModel) onLanguageSelected;

  const LanguageSelector({
    super.key,
    this.initialLanguageCode,
    required this.onLanguageSelected,
  });

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  late LanguageModel _selectedLanguage;
  late String _countryCode;

  @override
  void initState() {
    super.initState();
    // Set initial language, default to English if not specified
    final initialCode = widget.initialLanguageCode ?? 'en';
    _selectedLanguage =
        LanguageModel.getByCode(initialCode) ??
        LanguageModel.availableLanguages.first;

    // Generate random country code for the flag
    _regenerateCountryCode();
  }

  void _regenerateCountryCode() {
    _countryCode = _selectedLanguage.getRandomCountryCode();
  }

  void _selectLanguage(LanguageModel language) {
    setState(() {
      _selectedLanguage = language;
      _regenerateCountryCode();
    });
    widget.onLanguageSelected(language);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Flag.fromCode(
              FlagsCode.values.firstWhere(
                (code) => code.name == _countryCode,
                orElse: () => FlagsCode.UN, // Default to UN flag if not found
              ),
              height: 14,
              width: 32,
              fit: BoxFit.fitWidth,
            ),
          ),
        ),
        value: _selectedLanguage.code,
        items:
            LanguageModel.availableLanguages.map((language) {
              return DropdownMenuItem<String>(
                value: language.code,
                child: Text(language.name),
              );
            }).toList(),
        onChanged: (String? value) {
          if (value != null) {
            final language = LanguageModel.getByCode(value);
            if (language != null) {
              _selectLanguage(language);
            }
          }
        },
      ),
    );
  }
}
