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

- **M1 (foundation):** complete. App shell, Riverpod, routing, theme, Drift schema v1, private
  file storage and tests.
- **M2 (wardrobe without AI):** complete for Android.
  - First-launch privacy screen with optional, skippable style preferences.
  - Editable preferences, with a reset.
  - Adding clothes by camera or gallery, with the photo copied into private storage.
  - Duplicate-photo detection.
  - A manual classification form.
  - A wardrobe grid with category chips, filters (colour, season, formality, status) and search.
  - Item details, edit, archive and restore, and delete with confirmation.

Verified on 2026-11-16 on an Android emulator (API 37, x86_64) in airplane mode:
- Onboarding, then adding a synthetic test image through the system Photo Picker.
- Classifying the item and seeing it in the grid.
- Force-stopping and relaunching: the item persists.

There were no permission prompts and no runtime errors. iOS (needs macOS) and physical Android
devices are not yet verified, and the camera path has only been exercised in tests, not on a
device.

The first Gradle build installs NDK 28.2, SDK platforms 35 and 36, and CMake 3.22.1
automatically. If a first build fails while those are being installed, re-run it once.
`android/gradle.properties` disables Kotlin incremental compilation, because the project (D:) and
the pub cache (C:) are on different drives.

The first Gradle build installs NDK 28.2, SDK platforms 35 and 36, and CMake 3.22.1 automatically.
That first run failed while those components were being installed, and the next run passed
unchanged. If a first build fails, re-run it once before investigating.

## Toolchain

| Tool | Version |
| --- | --- |
| Flutter | 3.50.0 stable (Dart 3.14.0) |
| Android | minSdk 24 (Flutter default), JDK 17 bytecode, via the Android Studio JBR. SDK at `%LOCALAPPDATA%\Android\Sdk` |
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
    media/             photo picker, native image downscaling, SHA-256 hashing
    logging/           local-only logger
    theme/             neutral Material 3 theme
    providers.dart     Riverpod DI (database, file store, clock, IDs)
  features/
    onboarding/        first-launch privacy + optional preferences
    profile/           style preferences (data: Drift repository)
    wardrobe/          import, grid, filters, details, editor (data: Drift repository)
    home/ stylist/ favorites/   placeholders until M4-M5
  shared/              taxonomy labels, chip selectors, stored-image widget
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
