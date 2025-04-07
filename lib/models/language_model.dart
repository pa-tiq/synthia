import 'dart:math';

class LanguageModel {
  final String code;
  final String name;
  final List<String> countries;

  const LanguageModel({
    required this.code,
    required this.name,
    required this.countries,
  });

  /// Get a random country code for this language for flag display
  String getRandomCountryCode() {
    final random = Random();
    return countries[random.nextInt(countries.length)];
  }

  /// Create a locale string from the language code
  String toLocaleString() {
    return code;
  }

  /// Available languages for summarization
  static const List<LanguageModel> availableLanguages = [
    LanguageModel(
      code: 'en',
      name: 'English',
      countries: ['US', 'GB', 'CA', 'AU', 'NZ'],
    ),
    LanguageModel(
      code: 'pt-BR',
      name: 'Português',
      countries: ['BR', 'PT', 'AO', 'MZ', 'CV'],
    ),
    LanguageModel(
      code: 'es',
      name: 'Español',
      countries: ['ES', 'MX', 'AR', 'CO', 'CL', 'PE', 'VE'],
    ),
  ];

  /// Get a language model by code
  static LanguageModel? getByCode(String code) {
    try {
      return availableLanguages.firstWhere((lang) => lang.code == code);
    } catch (_) {
      return null;
    }
  }
}
