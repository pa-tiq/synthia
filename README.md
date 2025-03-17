# [synthia](https://github.com/pa-tiq/synthia)

A simple interface for AI-powered file summarization.

## Folder Structure:

```
lib/
├── main.dart                 # Application entry point
├── app.dart                  # App configuration and initialization
├── config/                   # Configuration files
│   ├── constants.dart        # App-wide constants
│   └── theme.dart            
├── l10n/                     # Localization
│   ├── app_en.arb           
│   └── app_pt.arb            
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
    ├── api_debug_widget.dart       
    ├── error_wrapper.dart          
    ├── feature_sectionart        
    ├── file_info_card.dart        
    ├── file_selector_button.dart   
    ├── file_service.dart           
    ├── summarization_button.dart   
    └── summary_result_widget.dart 
```

## Prerequisites

- Flutter (latest stable version)
- Dart SDK
- Android Studio / VS Code with Flutter plugins

## Installation

Check if everything is ok with your flutter environment

```bash
flutter doctor
```

Install dependencies

```bash
flutter pub get
```

Run the app

```bash
flutter run
```
