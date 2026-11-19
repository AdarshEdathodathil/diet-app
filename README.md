# Dt Haritha

Dt Haritha is an offline-first Flutter application for clinical dietitians working in OP/IP consultations. It provides transparent anthropometric and nutrition calculations while keeping the dietitian in control of every clinical factor.

## Features

- Three-step patient, anthropometric, and nutrition workflow
- Asian Indian adult BMI classification and configurable BMI-based IBW
- Weight-based and Mifflin-St Jeor calorie calculations
- Protein, carbohydrate, residual fat, fibre, and water calculations
- Immediate recalculation and clinical validation warnings
- Dietitian review and approval workflow
- Optional clinical notes
- Local SQLite assessment storage with search and editing
- Patient profiles with OP number, contact information, consultation history, and BMI progress
- Recoverable deletion, archiving, duplication, filtering, and automatic draft recovery
- Reusable clinical factor presets that always require dietitian approval
- Complete Excel-compatible CSV export with an anonymized option
- Password-encrypted full backup and restore
- Optional app PIN and automatic background locking
- Offline PDF report generation, printing, and sharing
- Configurable report identity, light/dark themes, and responsive Material 3 layouts
- Dedicated About page with Dt Haritha E H's professional profile, qualifications, portrait, and ownership notice

## Privacy

The application is fully offline. It has no login, analytics, cloud sync, or automatic patient-data transmission. Assessments are stored in the device's local SQLite database. Android screenshots and operating-system backups are disabled, and an optional app PIN can lock the interface after backgrounding.

CSV files are intentionally portable and are therefore not encrypted. The export screen provides an anonymized mode and warns before identifiable information is shared. Full `.dthbackup` files are encrypted with AES-256-GCM using a password-derived key.

## Data workflow

- Create a patient, then open their profile to start or review assessments.
- Use the dashboard search to find a patient by name, OP number, or phone.
- Use the table icon to export one `complete_patient_data.csv` file containing patient profiles and assessment data.
- Use **Settings → Backup and restore** for password-encrypted device migration.
- Old version 1 assessments are migrated automatically into patient profiles.

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

Dt Haritha is a calculation and documentation aid, not an autonomous prescribing system. All nutrition requirements must be reviewed and approved by a qualified dietitian. Adult BMI and IBW pathways should not be applied directly to children or pregnancy.

## Ownership

This application, its content, branding, design, and associated intellectual property are owned exclusively by Dt Haritha E H.

© 2026 Dt Haritha E H. All rights reserved.
