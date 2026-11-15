# AI Stylist (working name)

Local-first, offline Flutter app for Android and iOS that builds outfits only from
clothing the user owns. No account, backend, cloud AI, analytics or telemetry.
Wardrobe photos and data never leave the device.

- Product requirements: [REQUIREMENTS.md](REQUIREMENTS.md)
- Engineering rules: [CLAUDE.md](CLAUDE.md)
- Plan and milestones: [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md)
- Decisions: [DECISIONS.md](DECISIONS.md)
- Package and model research: [COMPATIBILITY_REPORT.md](COMPATIBILITY_REPORT.md)

## Status

M1 (foundation) is in progress on `feature/m1-foundation`: app shell, Riverpod, routing, theme,
Drift schema v1, private file storage and tests. The Android build is not yet verified because the
Android SDK is not installed on the development machine. iOS needs macOS.

## Toolchain

| Tool | Version |
| --- | --- |
| Flutter | 3.50.0 stable (Dart 3.14.0) |
| Android | minSdk 24 (Flutter default), JDK 17 bytecode, via the Android Studio JBR |
| iOS | 15.0 deployment target. Needs macOS and Xcode |

Flutter and Dart analytics are disabled on the development machine
(`flutter --disable-analytics`, `dart --disable-analytics`).

## Layout

```
lib/
  app/                 bootstrap (error handling, storage), app widget, router (4-tab shell)
  core/
    database/          Drift tables (schema v1), AppDatabase, connection
    storage/           FileStore: app-private, relative paths, atomic writes
    logging/           local-only logger
    theme/             neutral Material 3 theme
    providers.dart     Riverpod DI (database, file store, clock, IDs)
  features/<feature>/presentation/
  shared/widgets/
packages/
  wardrobe_domain/     pure Dart: Result, typed failures, clock, IDs, taxonomy (draft)
  outfit_engine/       pure Dart: recommendation engine (FR-07 weights so far)
drift_schemas/         schema snapshots used to generate migration tests
test/                  database, file store and widget tests
```

UI code uses `package:material_ui` (Material moved out of the Flutter framework in 3.47).

## Commands

```bash
flutter pub get
dart run build_runner build      # Drift + Riverpod code generation
dart format lib test packages
flutter analyze
flutter test                     # app tests
(cd packages/wardrobe_domain && dart test)
(cd packages/outfit_engine && dart test)
flutter build apk --debug        # needs the Android SDK
```

After any change to `lib/core/database/tables.dart`, bump `schemaVersion`, add a migration step,
then run `dart run drift_dev make-migrations` to snapshot the schema and generate migration tests.

## Privacy

There are no network calls in the app today. The Android release manifest declares no INTERNET
permission. It will be added only with the optional weather and model-download features
(Phase 7), each documented in `docs/NETWORK.md`.
