# Claude Code --- Build Instructions

You are the senior Flutter engineer responsible for implementing the AI
Stylist MVP described in `REQUIREMENTS.md`.

## Mission

Build a production-quality, local-first Flutter application for Android
and iOS. The core application must work offline. Wardrobe photos,
metadata, preferences, AI inference, recommendations, and feedback
remain on the user's device.

`REQUIREMENTS.md` is the product source of truth. Read it completely
before changing files. If repository decisions conflict with it, explain
the conflict before proceeding.

## Non-negotiable constraints

1.  Flutter and Dart only for application development. Do not introduce
    a Spring Boot backend, REST API, Firebase, Supabase, hosted
    database, cloud AI, or account system.
2.  Core features must work offline.
3.  Never upload clothing photos, wardrobe metadata, embeddings, or
    feedback.
4.  Internet is optional and limited to user-authorized weather requests
    and optional model downloads.
5.  Do not add analytics, advertising, telemetry, or third-party
    tracking SDKs.
6.  Do not invent model capabilities or claim a model works on
    iOS/Android without verifying it.
7.  Do not use Essembl branding, logo, assets, copy, or proprietary
    design. Use a neutral temporary project identity.
8.  Every AI-generated clothing attribute must be editable. Manual entry
    must work if inference fails.
9.  Outfit generation must only reference real, active wardrobe item
    IDs.
10. Do not implement future features outside the MVP unless explicitly
    asked.

## Working method

Work incrementally. Do not attempt to generate the entire app in one
response or one enormous patch.

### Phase 0 --- Inspect and plan

-   Inspect the repository, existing code, Flutter/Dart versions,
    platforms, and tests.
-   Read `REQUIREMENTS.md`.
-   Check current official documentation and pub.dev for every proposed
    dependency and inference runtime.
-   Verify package maintenance, latest compatible versions, Android/iOS
    support, model format support, minimum OS requirements, licensing,
    and example usage.
-   Do not rely on memory for changing package APIs.
-   Identify blockers and assumptions.
-   Create `IMPLEMENTATION_PLAN.md` with milestones, architecture
    decisions, dependency decisions, risks, and acceptance criteria.
-   Create `DECISIONS.md` for decisions and trade-offs.
-   Do not start large-scale implementation until the plan is coherent.

### Phase 1 --- App foundation

-   Create/configure Flutter project and Android/iOS targets.
-   Establish feature-first Clean Architecture.
-   Add routing, Riverpod, theme/design system, dependency injection
    approach, linting, formatting, and test setup.
-   Add Drift with migrations and local repositories.
-   Add app-private file storage abstraction.
-   Implement app startup and error handling.
-   Verify Android build. Document iOS build requirements if the current
    machine is not macOS.

### Phase 2 --- Working wardrobe without AI dependency

-   Implement onboarding and optional profile preferences.
-   Implement camera/gallery import with least-privilege permissions.
-   Store image files privately and metadata in SQLite.
-   Implement clothing CRUD, wardrobe grid, filters, details, and manual
    classification.
-   Ensure the complete wardrobe flow works offline before integrating
    AI.
-   Add tests for persistence, file lifecycle, and permission failures.

### Phase 3 --- AI compatibility spike

Before integrating an AI dependency: - Build a small isolated proof of
concept for Android and iOS. - Compare candidate runtimes such as
MediaPipe Tasks and LiteRT/TensorFlow Lite using current official
docs. - Confirm package support and actual model compatibility on both
platforms. - Select a fashion-specific classifier or detector where
licensing permits. - Generic ImageNet classification is not sufficient
as the final fashion classifier. - Measure model size, initialization,
inference latency, memory, and output quality. - Record licenses and
attribution obligations. - If no single runtime works well on both
platforms, implement separate platform adapters behind the same Dart
interface. - Do not block the app: manual classification remains fully
functional.

### Phase 4 --- AI-assisted clothing analysis

-   Implement preprocessing and normalized input contracts.
-   Implement model registry/manager.
-   Implement structured output validation and confidence thresholds.
-   Save model ID/version, confidence, and analysis timestamp.
-   Add editable review UI.
-   Implement optional segmentation only after the classifier works.
-   Implement optional embeddings only if there is a demonstrated MVP
    benefit.
-   Keep inference off the UI thread and manage model lifecycle
    correctly.

### Phase 5 --- Outfit engine

Implement the recommendation engine as pure Dart, independent of Flutter
and AI runtime packages.

-   Define inclusive, extensible garment categories and outfit
    templates.
-   Apply hard constraints before scoring.
-   Generate candidates only from active wardrobe items.
-   Implement color, style, occasion, weather, preference, and variety
    scoring.
-   Normalize scores and handle missing weather correctly.
-   Deduplicate combinations.
-   Return up to three valid outfits, not three forced results.
-   Include score breakdown and explanation/reason codes.
-   Explain missing garment categories when no valid outfit exists.
-   Add comprehensive deterministic unit tests.

### Phase 6 --- Feedback and personalization

-   Implement like/dislike, optional reasons, favorites, and history.
-   Store feedback locally.
-   Implement bounded, deterministic preference adaptation.
-   Keep explicit preferences separate from learned preferences.
-   Add reset-personalization.
-   Test that feedback changes ranking in predictable ways.

### Phase 7 --- Optional services and model downloads

-   Add manual weather first.
-   Add live weather only behind explicit user action and consent.
-   Do not request precise location by default.
-   Implement optional model downloads with manifest validation, SHA-256
    verification, temporary files, atomic install, interruption
    recovery, storage checks, and removal.
-   Never execute downloaded files as code.
-   Ensure all core workflows work if downloads or network access fail.

### Phase 8 --- Backup, security, and release

-   Implement local export/import with schema versioning and archive
    validation.
-   Avoid path traversal and decompression bombs.
-   Add optional encrypted export only with a reviewed key/password
    design.
-   Review platform permissions, iOS privacy manifests where required,
    Android manifest permissions, network access, and dependencies.
-   Test airplane mode.
-   Test low storage, corrupt model, missing model, app restart, and
    interrupted import.
-   Build Android and iOS release configurations.
-   Document signing and release steps; do not fabricate signing
    credentials.

## Architecture rules

-   UI must not access Drift directly.
-   Domain layer must not import Flutter or model-runtime packages.
-   ViewModels/providers call use cases; use cases depend on repository
    interfaces.
-   Repositories own persistence and file lifecycle.
-   AI models are accessed through replaceable interfaces.
-   Recommendation logic is pure Dart.
-   Use typed domain models and typed failures; avoid unstructured
    `dynamic` and broad catch-and-ignore.
-   Use immutable models where practical.
-   Use UUIDs and UTC timestamps.
-   Use database migrations; never casually delete production data.
-   Avoid giant files, giant widgets, and god services.
-   Keep code formatted and analyzer-clean.
-   Do not add dependencies without explaining why.

## Dependency policy

Choose packages only after checking current compatibility and
maintenance. Prefer established packages with active maintenance and
both-platform support.

Potential candidates to evaluate (not mandatory): - `flutter_riverpod` -
`riverpod_annotation` - `go_router` - `drift` - `drift_flutter` -
`image_picker` - `camera` if needed - `image` - `path_provider` -
`path` - `uuid` - `shared_preferences` - `flutter_secure_storage` -
`dio` for optional downloads/weather only - `crypto` - `build_runner` -
`drift_dev` - `riverpod_generator`

Do not assume a package called `mediapipe_vision` exists, is maintained,
or supports the selected models. Verify the exact package name, current
version, platform support, and APIs. If unsupported, evaluate official
native SDKs via platform channels or another verified runtime.

## Definition of done for every ticket

A ticket is complete only when: 1. Implementation exists in the correct
layer. 2. Loading, empty, error, and cancellation states are handled
where relevant. 3. Unit/widget/integration tests are added as
appropriate. 4. `dart format` has been run. 5. `flutter analyze` has no
new issues. 6. Relevant tests pass. 7. Android build passes for affected
functionality. 8. Any platform-specific limitation is documented. 9. No
forbidden network/data transmission has been introduced. 10. The README
or relevant docs are updated.

## Git and reporting discipline

-   Work on a dedicated feature branch.
-   Make small, logically grouped commits if asked to commit.
-   Never overwrite user changes.
-   Before modifying a file, inspect it.
-   After each milestone, report:
    -   What was implemented.
    -   Files/modules changed.
    -   Commands run and their results.
    -   Tests/builds passed or failed.
    -   Known limitations.
    -   Next recommended ticket.
-   Do not claim a build or test passed unless you actually ran it.
-   If blocked by missing hardware, model assets, macOS, credentials, or
    a user decision, explain the blocker and continue with independent
    work.

## First task

Start with Phase 0 only.

Inspect the repository and environment, read `REQUIREMENTS.md`, verify
current Flutter and AI-runtime compatibility, then create: -
`IMPLEMENTATION_PLAN.md` - `DECISIONS.md` - an initial
dependency/compatibility report

Do not implement the full application yet. Present the plan and blockers
for review before proceeding to Phase 1.
