# DT Haritha

DT Haritha is an offline-first Flutter application for clinical dietitians working in OP/IP consultations. It provides transparent anthropometric and nutrition calculations while keeping the dietitian in control of every clinical factor.

## Features

- Three-step patient, anthropometric, and nutrition workflow
- Asian Indian adult BMI classification and configurable BMI-based IBW
- Weight-based and Mifflin-St Jeor calorie calculations
- Protein, carbohydrate, residual fat, fibre, and water calculations
- Immediate recalculation and clinical validation warnings
- Dietitian review and approval workflow
- Optional clinical notes
- Local SQLite assessment storage with search and editing
- Offline PDF report generation, printing, and sharing
- Responsive Material 3 interface for Android phones and tablets

## Privacy

The application is fully offline. It has no login, signup, analytics, cloud sync, or external patient-data transmission. Assessments are stored only in the device's local SQLite database.

## Development

Requirements:

- Flutter 3.44 or newer
- Dart 3.12 or newer
- Android SDK for Android builds

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Build an Android APK:

```bash
flutter build apk --release
```

## Clinical notice

DT Haritha is a calculation and documentation aid, not an autonomous prescribing system. All nutrition requirements must be reviewed and approved by a qualified dietitian. Adult BMI and IBW pathways should not be applied directly to children or pregnancy.
