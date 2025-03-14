# [synthia](https://github.com/pa-tiq/synthia)

A simple interface for AI-powered file summarization.

## Folder Structure:

```
lib/
├── main.dart                 # Application entry point
├── app.dart                  # App configuration and initialization
├── config/                   # Configuration files
│   ├── constants.dart        # App-wide constants
│   └── theme.dart            # Theme configuration
├── l10n/                     # Localization
│   ├── app_en.arb            # English translations
│   └── app_pt.arb            # Brazilian Portuguese translations
├── models/
│   └── file_model.dart       # File data model
├── screens/
│   └── home_screen.dart      # Main application screen
├── services/
│   ├── file_service.dart     # File handling services
│   └── summarization_service.dart  # API integration for summarization
├── utils/
│   └── helpers.dart          # Utility functions
└── widgets/                  # Reusable UI components
    ├── error_wrapper.dart    # Error handling widget
    ├── file_info_card.dart   # File information display
    ├── file_selector_button.dart  # File selection component
    └── file_service.dart     # File service widget
```

## Prerequisites

- Flutter (latest stable version)
- Dart SDK
- Android Studio / VS Code with Flutter plugins

## Installation

Check if everything is ok with your flutter environment

```
flutter doctor
```

Install dependencies

```
flutter pub get
```

Run the app

```
flutter run
```
