# AI Stylist --- MVP Product & Technical Requirements

**Document:** REQUIREMENTS.md\
**Status:** MVP baseline\
**Platforms:** Android and iOS\
**Client:** Flutter / Dart\
**Architecture:** Local-first, offline-capable, on-device AI\
**Working name:** AI Stylist (temporary; do not use Essembl branding,
assets, or trademarks)

## 1. Product vision

Build a mobile application that helps a person create outfits from
clothing they already own.

A user photographs clothing, reviews AI-generated attributes, maintains
a digital wardrobe, chooses an occasion and optionally provides weather
conditions, then receives three outfit suggestions made exclusively from
active wardrobe items.

The app must be useful without an account, backend, or internet
connection. Internet is optional and may only be used for explicitly
requested features such as live weather or downloading optional model
packages.

## 2. MVP goals

1.  Let users create and manage a local digital wardrobe.
2.  Make clothing capture and correction straightforward.
3.  Use on-device AI to assist with clothing classification and
    attributes.
4.  Generate valid, explainable outfit combinations from wardrobe items.
5.  Learn simple preferences from explicit likes and dislikes.
6.  Preserve user data locally and support export/import.
7.  Support Android and iOS from one Flutter codebase.

## 3. Non-goals

Do not implement in the MVP: - User accounts, authentication, backend,
REST API, or cloud database. - Cloud AI inference or uploading clothing
photos. - Social feeds, sharing, chat, shopping, affiliate links,
subscriptions, or ads. - Virtual try-on or generated images of people
wearing garments. - Automatic camera-roll scanning. - A general-purpose
LLM or conversational stylist. - Multi-device cloud synchronization. -
Automatic model training on user photos.

Do not add these features without an explicit product decision.

## 4. Product principles

-   Local-first: wardrobe data, photos, preferences, feedback, outfit
    history, and inference remain on the device.
-   Offline-first: core workflows must work in airplane mode.
-   AI assists; users remain in control. Every AI-generated attribute
    can be edited.
-   Never invent wardrobe items. Outfit results must reference existing
    active item IDs.
-   Be transparent about uncertain classifications.
-   Do not require gender selection. Use inclusive, optional style
    preferences and garment categories.
-   Do not infer a user's gender, body type, identity, or preferences
    from photos.
-   Minimize permissions and network access.
-   Avoid collecting analytics or advertising identifiers in the MVP.

## 5. Target platforms and compatibility

-   Flutter application for Android and iOS.
-   Establish and document minimum OS versions based on the selected,
    verified inference runtime and plugin support.
-   Do not assume a package, API, model format, or minimum OS is
    compatible. Verify current official documentation and pub.dev
    package status before adopting it.
-   Build and test Android on CI or a local Android environment.
-   iOS builds, signing, and simulator/device testing require macOS and
    Xcode.
-   If a selected AI plugin is unsupported or unreliable on either
    platform, isolate it behind an interface and provide a compatible
    alternative or manual fallback.

## 6. MVP user journeys

### 6.1 First launch

1.  Show a short explanation of local storage and optional internet use.
2.  Let the user choose optional style preferences: preferred styles,
    colors to favor/avoid, fit preference, and preferred formality.
3.  Do not require account creation, gender, location, or camera
    permission at startup.
4.  Allow the user to skip preferences and continue.

### 6.2 Add clothing

1.  User chooses camera or photo library.
2.  Request only the permission needed for that action.
3.  Copy the selected image into app-private storage.
4.  Create a clothing record with a stable UUID.
5.  Run available on-device analysis asynchronously.
6.  Show proposed category, subcategory, colors, pattern, season, and
    confidence.
7.  User can accept, edit, or skip AI suggestions.
8.  Save the item as ACTIVE only after the user confirms or completes
    manual entry.
9.  Handle cancellation, unsupported image, low storage, inference
    failure, and permission denial gracefully.

### 6.3 Wardrobe

-   Browse a grid of owned items.
-   Filter by category and optionally color, season, formality, and
    status.
-   Search by user-entered name/notes where supported.
-   Open item details and edit attributes.
-   Mark an item inactive/archived or delete it with confirmation.
-   Do not show archived/deleted items as eligible for new outfit
    generation.

### 6.4 Generate outfits

1.  User selects occasion: casual, smart casual, business, formal, or
    custom.
2.  User optionally selects style and weather context.
3.  User chooses number of results; default is three.
4.  Engine loads active wardrobe items and builds valid combinations.
5.  Apply hard constraints, then score and rank candidates.
6.  Return up to three distinct outfits, each with item IDs, score
    breakdown, and a concise explanation.
7.  If insufficient clothing exists, explain which category is missing
    and suggest adding items. Never fabricate a result.

### 6.5 Feedback and favorites

-   User can like, dislike, save, unsave, and optionally provide a
    reason.
-   Persist feedback locally.
-   Use feedback to adjust lightweight preference weights.
-   Keep explicit user preferences separate from learned preferences.
-   Provide a reset-personalization action.

### 6.6 Weather

-   Manual weather entry must work offline.
-   Live weather is optional and only requested after user
    action/consent.
-   Prefer manual city selection over precise location permission.
-   Do not silently transmit precise location.
-   Weather failure must not block outfit generation.

### 6.7 Backup and restore

-   Export wardrobe metadata, preferences, feedback, and image files to
    a user-selected local archive.
-   Support optional archive encryption with a user-supplied password or
    secure key workflow.
-   Validate archive contents, schema version, file paths, sizes, and
    checksums before import.
-   Never overwrite current data without explicit confirmation.
-   Model binaries do not need to be included in a user backup; record
    required model IDs/versions instead.

## 7. Functional requirements

### FR-01 Profile and preferences

-   Store one local profile.
-   Support preferred styles, liked/disliked colors, fit preference, and
    formality preference.
-   All fields are optional.
-   Provide reset controls.

### FR-02 Clothing capture

-   Camera and gallery input.
-   App-private image storage.
-   Image resizing/orientation normalization.
-   Preserve original image unless user chooses to remove it.
-   Handle duplicate image selection without silently creating duplicate
    items.

### FR-03 Clothing catalog

Each clothing item must support: - `id` - `category` - `subcategory` -
`displayName` or notes - `primaryColor` - `secondaryColors` -
`pattern` - `seasons` - `formality` (defined scale) - `fit` (optional) -
`brand` (optional user-entered) - `status` (ACTIVE or ARCHIVED) -
`createdAt` - `updatedAt`

Use controlled enums where appropriate and allow `UNKNOWN`/null when
uncertain.

### FR-04 AI-assisted analysis

-   On-device inference only.
-   AI output must be structured and schema-validated.
-   Store model ID, model version, confidence, and analysis timestamp.
-   Define confidence thresholds and require user confirmation for
    low-confidence outputs.
-   AI failure must not prevent manual clothing entry.
-   No photo or embedding may leave the device.

### FR-05 Background removal

-   Optional enhancement, not a blocker for wardrobe creation.
-   Run locally.
-   Preserve original image.
-   Allow user to retain original if segmentation fails or looks
    incorrect.
-   Do not make background removal a P0 dependency unless reliable
    models are verified for both platforms.

### FR-06 Outfit generation

-   Generate outfits only from ACTIVE wardrobe item IDs.
-   Define outfit templates by occasion and available categories.
-   Validate category requirements and duplicate constraints.
-   Use hard filters for impossible/ineligible combinations.
-   Use weighted scoring for soft preferences.
-   Return zero to three results; never force three invalid results.
-   Provide reason codes/score breakdown for explainability.
-   Exclude repeated combinations from recent history where possible.

Initial outfit templates: - Casual: top + bottom + shoes. - Smart
casual: top + bottom + shoes; optional layer. - Business: shirt/top +
bottom + shoes; optional jacket. - Formal: suitable formal top/dress +
bottom if required + shoes; support garment-specific templates. - Dress
outfit: dress + shoes; optional layer. - Cold-weather: valid base
outfit + outerwear.

Do not assume every user has the same garment types. Templates must be
extensible and avoid rigid gender-based rules.

### FR-07 Recommendation scoring

Initial weights (configurable and normalized to sum to 1.0): - Color
compatibility: 0.25 - Style compatibility: 0.20 - Occasion suitability:
0.20 - Weather suitability: 0.15 - User preferences: 0.15 - Variety:
0.05

Each component returns a normalized score from 0.0 to 1.0. If weather is
unavailable or not requested, redistribute or omit that component
explicitly; do not treat missing weather as a bad score.

Hard constraints must not be overridden by weighted scores.

### FR-08 Feedback

-   Like/dislike and favorite are distinct concepts.
-   Store feedback with timestamp and optional reason.
-   Preference learning must be deterministic, bounded, explainable, and
    resettable.
-   Do not silently rewrite explicit preferences.

### FR-09 Local model manager

-   Bundle a small baseline model only after validating its licensing,
    size, runtime compatibility, and performance.
-   Advanced models may be downloaded only after user consent.
-   Verify SHA-256 and signed/known manifest metadata before
    installation.
-   Use temporary download files and atomic installation.
-   Handle interrupted downloads, insufficient storage, corrupt files,
    version rollback, and removal.
-   Never execute downloaded code.
-   Model downloads are optional; app core must work without them.

### FR-10 Privacy and network

-   No backend, account, analytics, ad SDK, or cloud AI in MVP.
-   Network access is used only for explicitly enabled weather or model
    downloads.
-   Document every network request and its data fields.
-   No clothing images, personal wardrobe metadata, or embeddings are
    transmitted.
-   App must operate with network disabled.
-   Use app-private storage and platform secure storage for
    secrets/keys.
-   Do not claim database/files are encrypted unless encryption is
    actually implemented and tested.

## 8. AI/model selection requirements

Do not hard-code a specific package or model before a compatibility
spike.

Evaluate candidates against: - Android and iOS support. - Current
Flutter/Dart compatibility. - Model format and runtime support. -
CPU/GPU/NPU delegate availability and stability. - Model license and
redistribution rights. - Model size and memory use. - Inference latency
on low-, mid-, and high-tier devices. - Classification quality on
fashion-specific data. - Offline operation. - Accessibility of model
weights and reproducible conversion.

Recommended staged approach: 1. Start with deterministic Dart color
extraction and manual category selection. 2. Integrate a verified
on-device image classification model. 3. Evaluate a fashion-specific
classifier/detector; generic ImageNet classification alone is
insufficient. 4. Add segmentation as an optional enhancement. 5. Add
embeddings only when they provide measurable value. 6. Do not add an LLM
to the MVP.

Possible runtime candidates include MediaPipe Tasks or LiteRT/TensorFlow
Lite, but the implementation must verify current official support and
package health for both platforms. Keep runtime adapters replaceable.

## 9. Technical architecture

Use feature-first Clean Architecture.

Suggested layers: - Presentation: screens, widgets, view
models/providers. - Domain: entities, value objects, use cases,
repository interfaces, recommendation rules. - Data: Drift DAOs, local
file storage, repository implementations, mappers. - AI: model registry,
preprocessing, inference adapters, output validators. - Platform:
camera/gallery, secure storage, file picker, optional network providers.

Rules: - UI never accesses Drift directly. - Domain layer must not
import Flutter or inference-runtime packages. - AI inference must not
run on the UI thread. - Expensive image processing must use isolates or
native asynchronous APIs as appropriate. - Repositories own persistence
and file lifecycle. - All dependencies are injected. - Keep
recommendation engine pure Dart and independently testable. - Use
migrations for all database schema changes. - Add structured error types
and user-friendly error messages.

## 10. Suggested project structure

``` text
lib/
  main.dart
  app/
    app.dart
    router.dart
    bootstrap.dart
  core/
    config/
    errors/
    logging/
    theme/
    utils/
    storage/
    database/
    permissions/
    models/
  features/
    onboarding/
      data/
      domain/
      presentation/
    profile/
      data/
      domain/
      presentation/
    wardrobe/
      data/
      domain/
      presentation/
    clothing_analysis/
      data/
      domain/
      presentation/
    stylist/
      data/
      domain/
      presentation/
    favorites/
      data/
      domain/
      presentation/
    weather/
      data/
      domain/
      presentation/
    backup/
      data/
      domain/
      presentation/
  ai/
    model_manager/
    runtime/
    preprocessing/
    classification/
    segmentation/
    embeddings/
  recommendation/
    templates/
    filters/
    scoring/
    ranking/
  shared/
    widgets/
    models/
test/
  unit/
  widget/
  integration/
  fixtures/
```

Adjust module boundaries if the chosen Flutter architecture benefits
from a different organization, but preserve separation of concerns.

## 11. Database requirements

Use SQLite through Drift.

Required tables: - `user_profile` - `clothing_items` -
`clothing_images` - `clothing_attributes` - `outfits` - `outfit_items` -
`outfit_feedback` - `model_installations` - `app_settings` (if not
represented in DataStore/preferences)

Use UUID primary keys, integer UTC timestamps, foreign keys, appropriate
indexes, and schema migrations.

Important persistence rules: - Store image files separately from
SQLite. - Use relative or app-managed file references; never assume a
path remains valid after reinstall or import. - Enforce referential
integrity. - Avoid destructive migrations. - Preserve historical outfit
records while marking unavailable/deleted garments appropriately. -
Ensure export/import handles database and files consistently.

## 12. Internal Dart contracts

Define interfaces for: - `WardrobeRepository` - `ProfileRepository` -
`OutfitRepository` - `ClothingAnalyzer` - `BackgroundRemover` -
`ModelManager` - `WeatherRepository` - `BackupRepository`

The outfit generator should accept an `OutfitRequest` containing
occasion, style, optional weather, requested count, and excluded recent
outfit signatures. It should return validated `Outfit` domain objects
containing existing item IDs, score breakdown, and explanation/reason
codes.

Do not create HTTP endpoints in the MVP.

## 13. UX requirements

Primary navigation: - Home - Wardrobe - Stylist - Favorites

Required screens: - Onboarding and privacy explanation. - Home / daily
suggestion. - Wardrobe grid and category filters. - Add clothing
camera/gallery flow. - AI analysis review/edit screen. - Clothing
details. - Occasion/weather selection. - Outfit results. - Outfit
details. - Favorites/history. - Profile/preferences. - Model manager. -
Export/import.

UX requirements: - Clear loading, empty, error, and permission-denied
states. - Accessible text sizes and contrast. - Responsive layouts for
different phone sizes. - Do not block the app while models load. - Show
when advanced models are unavailable. - Manual workflows must always
remain available.

## 14. Performance and quality requirements

Establish measurable budgets during the first device spike rather than
inventing universal guarantees.

Measure on low-, mid-, and high-tier Android devices and representative
iPhones: - Cold start time. - Image import and preprocessing time. -
Model initialization time. - Per-image inference latency. - Peak
memory. - Battery impact. - Storage usage. - Outfit generation latency
for small, medium, and large wardrobes.

Acceptance: - No long-running work on the UI thread. - No crashes on
missing/corrupt models. - No data loss on app restart. - Graceful
behavior under low storage. - App remains usable if AI is unavailable. -
Core wardrobe and outfit generation work offline.

## 15. Testing requirements

Unit tests: - Category/template validation. - Color compatibility. -
Style compatibility. - Hard constraints. - Score normalization. -
Duplicate detection. - Preference learning and reset. - Import/export
validation.

Database tests: - CRUD. - Foreign keys. - Migrations. - Archive/delete
behavior. - Transaction rollback.

AI tests: - Model loading and disposal. - Input preprocessing. - Output
schema validation. - Confidence thresholds. - Invalid/corrupt model
handling. - Golden test images with expected classifications.

Widget/integration tests: - Onboarding. - Add/edit/delete garment. -
Manual fallback. - Outfit generation. - Feedback and favorites. -
Offline operation. - Backup/restore.

Never use real personal wardrobe photos in committed test fixtures
without explicit permission. Use synthetic or licensed test images.

## 16. MVP acceptance criteria

The MVP is ready for beta when:

1.  A new user can start without creating an account.
2.  User can add clothing using camera or gallery.
3.  User can manually classify clothing if AI fails.
4.  AI can classify the supported initial categories on-device.
5.  User can correct all AI attributes.
6.  Wardrobe persists after app restart.
7.  User can generate valid outfits using only active wardrobe items.
8.  The engine returns up to three ranked outfits, or a useful
    explanation if there are insufficient items.
9.  User can like, dislike, and favorite outfits.
10. Basic personalization affects subsequent recommendations.
11. Core workflows work in airplane mode.
12. Optional internet requests require user action/consent.
13. No clothing photos or wardrobe metadata are uploaded.
14. Export and import can restore wardrobe data and images.
15. Android and iOS builds pass the agreed test suite.

## 17. Delivery milestones

-   M1: Architecture, app shell, local database.
-   M2: Wardrobe CRUD and image storage.
-   M3: Manual clothing entry and AI classification.
-   M4: Outfit generation and scoring.
-   M5: Feedback, favorites, personalization.
-   M6: Optional model manager and weather.
-   M7: Backup, privacy, performance and testing.
-   M8: Android/iOS beta builds.

## 18. Product decisions that require explicit approval

Do not silently decide: - Final app name or branding. - Minimum
supported OS versions. - Model redistribution/licensing. - Whether
original photos can be deleted after processing. - Encryption and
password-recovery behavior. - Exact fashion taxonomy and outfit
templates. - Any new network transmission or analytics. - Any paid
feature or subscription.

Document assumptions and ask only when a decision blocks implementation.
