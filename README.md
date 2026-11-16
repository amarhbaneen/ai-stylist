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

- **M3 (AI compatibility spike):** partly done; merged into `main`.
  - LiteRT (`flutter_litert` 4.1.1) runs `.tflite` models in a background isolate on the Android
    emulator, with zero network egress, and the APK is 16 KB page-size compliant.
  - Tier-0 colour extraction is in `lib/ai/color/`.
  - Still open: iOS, real-device numbers, and the fashion model.
  - See [docs/spikes/M3_AI_RUNTIME_REPORT.md](docs/spikes/M3_AI_RUNTIME_REPORT.md) and
    [docs/MODELS.md](docs/MODELS.md).
- **M4 (AI-assisted analysis):** partly done, on `feature/m4-ai-analysis`.
  - When a photo is added, the main colour is detected on-device and pre-filled with its
    confidence. Medium confidence asks you to confirm; low confidence appears only as tappable
    hints. Secondary colours are offered as "Also detected" chips.
  - Suggestions are stored with their source model, version, confidence and time, plus whether
    you kept each one.
  - A model registry with SHA-256 checks and an output validator are ready for a fashion model.
  - Category, type and pattern classification is waiting on a licensed model (see
    [docs/MODELS.md](docs/MODELS.md)).
  - Verified on the emulator offline: a new green shirt photo had Green pre-filled.
- **M6 (feedback and personalisation):** complete for Android; merged into `main`.
  - Like, dislike (with optional reasons and a note) and save on every outfit.
  - The Favorites tab has Saved and History views.
  - Learning is bounded and deterministic: per garment, per colour and per pairing, rebuilt
    from the feedback log since the last reset.
  - Learned preferences appear separately in Style preferences, with "Reset learning".
  - Tests show a like changes the next ranking by an exact, predictable amount, and a reset
    restores the baseline.
  - Verified on the emulator offline: like, save, the Saved view, and the learned section.
- **M5 (outfit engine):** complete for Android; merged into `main`.
  - `packages/outfit_engine` is pure Dart: templates, hard constraints, six scorers, ranking,
    variety and explanations.
  - The Stylist tab offers occasion, optional style, optional manual weather and the number of
    ideas (1–3).
  - Results show reasons, and an outfit details screen shows the score breakdown and weights.
  - Outfits are stored as history, so recent combinations are avoided.
  - Verified on the emulator in airplane mode, with the engine on a real background isolate:
    the missing-items explanation, a complete outfit, details, and history-aware repeats.
  - Not done yet: the Home "daily suggestion" (still a placeholder) and real-device timings.

The first Gradle build installs NDK 28.2, SDK platforms 35 and 36, and CMake 3.22.1
automatically. If a first build fails while those are being installed, re-run it once.
`android/gradle.properties` disables Kotlin incremental compilation, because the project (D:) and
the pub cache (C:) are on different drives.

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
    stylist/           outfit generation UI, outfit details (data: Drift outfit repository)
    favorites/         feedback bar, Saved/History, learned-preferences section
                       (data: Drift feedback + personalization repositories)
    home/              placeholder (daily suggestion not built yet)
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
