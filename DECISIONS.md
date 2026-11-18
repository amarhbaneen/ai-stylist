# Decisions Log

Format: each decision has a status.
- **Accepted**: an engineering decision within the scope CLAUDE.md delegates to me.
- **Proposed**: needs product-owner approval (REQUIREMENTS §18) before it is relied on.
- **Superseded**: replaced by a later decision.

Evidence for package and model facts is in `COMPATIBILITY_REPORT.md`.

---

## D-01 Toolchain: Flutter 3.50.x stable / Dart 3.14. Accepted
Use the current stable release (3.50.0, released 2026-11-11). Pin it in `.fvmrc` or the
README, and in CI. Every chosen package's SDK constraint is satisfied by it.
*Trade-off:* a x.0 release is fresh. If the spike shows a regression, fall back to 3.47.9.

## D-02 Repository layout: Dart pub workspace with a pure-Dart engine package. Accepted
```
/                         Flutter app (lib/, android/, ios/, test/)
packages/outfit_engine/   pure Dart: templates, filters, scoring, ranking, learning
packages/wardrobe_domain/ pure Dart: entities, value objects, taxonomy, failures, repo interfaces
tools/model_training/     Python scripts (not shipped) for reproducible model export
```
*Why:* CLAUDE.md requires that the domain and the recommendation engine never import Flutter
or runtime packages. A separate package with no Flutter dependency makes that a compile-time
guarantee instead of a convention. It also lets the engine be tested with `dart test`.
*Trade-off:* slightly more pubspec management.

## D-03 Architecture: feature-first Clean Architecture. Accepted
Layers per feature: `presentation` (widgets and Riverpod notifiers) → `application` (use
cases) → `domain` (from `wardrobe_domain`) ← `data` (Drift DAOs, file store, mappers, repo
implementations). Cross-cutting `ai/` and `core/` sit beside features. The UI never imports
Drift. Notifiers call use cases. Use cases depend only on repository interfaces.

## D-04 State management and DI: Riverpod 3 with code generation. Accepted
`flutter_riverpod` 3.5, `riverpod_annotation`/`riverpod_generator` 4.x. Providers act as the
DI container. Infrastructure providers (database, file store, analyzer, clock, UUID
generator) are overridden in tests.
*Alternative considered:* get_it + bloc. Rejected: two libraries where one will do.

## D-05 Persistence: Drift 2.35 on `sqlite3` 3.x; no `sqlite3_flutter_libs`. Accepted
`sqlite3_flutter_libs` and `sqlcipher_flutter_libs` are EOL. `sqlite3` 3.x bundles SQLite
through build hooks. Use `drift_dev` schema dumps (`drift_schemas/`) and generated migration
tests from schema v1 onwards. Foreign keys on (`PRAGMA foreign_keys = ON` in `beforeOpen`).
Timestamps are integer UTC milliseconds. IDs are UUID v4 text.
Settings live in an `app_settings` table, not `shared_preferences`, so backups have one source
of truth.
**DB encryption is not implemented.** Nothing will claim otherwise (FR-10).

## D-06 Image pipeline. Accepted (pending spike timing)
1. `image_picker` returns a temporary file.
2. Compute the SHA-256 of the original bytes, then check for a duplicate (FR-02).
3. Copy the original into `<appSupport>/images/originals/<uuid>.<ext>`. **The original is
   preserved.**
4. Generate a working copy (long edge 1024 px, EXIF orientation applied) and a thumbnail
   (320 px), using `flutter_image_compress` (native).
5. AI and colour extraction read the working copy in a background isolate.

The DB stores *relative* paths only. The `FileStore` abstraction owns create, delete and
orphan cleanup, writing to a temp name and then renaming.

## D-07 AI runtime: LiteRT via `flutter_litert`, bundled runtime only. Proposed (spike-gated)
Rejected: **MediaPipe Tasks** and **ML Kit**. Both send non-disableable usage metrics to
Google, which violates the no-telemetry rule.
Rejected for now: ONNX Runtime (raises iOS to 16, second model format) and ExecuTorch (pre-1.0).
The Play-services LiteRT mode is **not** enabled.
Everything sits behind the `InferenceRuntime` adapter, so we can swap to `tflite_flutter` or
`flutter_onnxruntime` without touching the domain.
*Gate:* adopt only after the spike shows no network egress, a successful model load on
Android and iOS, and acceptable latency.
*Product-owner question:* do you want to keep the MediaPipe/ML Kit exclusion? Yes is
recommended.
*M3 status (2026-11-16):* the Android part of the gate passed on an x86_64 emulator, in both
release and debug builds: the model loaded and ran in a background isolate, there was zero
network egress with INTERNET granted, and the APK is 16 KB page-size compliant. iOS and
real-device latency are still open. See `docs/spikes/M3_AI_RUNTIME_REPORT.md`.

## D-08 Fashion model strategy: tiered. Accepted 2026-11-16 (Tier 1; Tier 2 still needs legal review)
- Tier 0: deterministic Dart colour extraction and manual entry. Always available.
- Tier 1: a small bundled classifier (≤ 10 MB int8 `.tflite`) trained on Fashionpedia
  (CC BY 4.0, attribution required), optionally distilled from Marqo-FashionSigLIP
  (Apache-2.0).
- Tier 2: Marqo-FashionSigLIP vision tower (about 90 MB int8) as an **optional consented
  download**, used zero-shot against prompt embeddings computed offline.

Rejected models: anything trained on ModaNet (CC BY-NC), DeepFashion (non-commercial),
scraped data, or with an unclear licence (see the report §4).
*Needs approval:* (a) redistribution of a model derived from Fashionpedia images; (b) use of
Marqo weights, whose fine-tuning data provenance is not fully documented on the card. Legal
review is advised. (c) Who trains Tier 1, on what hardware.
*Approved 2026-11-16:* train Tier 1 ourselves on Fashionpedia, on Google Colab, with scripts
in `training/` (Python, outside the app build). Tier 2 (Marqo) still needs a legal review.

## D-09 Analysis output contract and confidence thresholds. Accepted (values to calibrate)
Each AI attribute is `Suggestion<T>{value, confidence 0..1, source(modelId, modelVersion), analyzedAtUtc}`.
The output is validated against taxonomy enums. Unknown labels map to `UNKNOWN`.
Default thresholds:
- ≥ 0.80: prefilled.
- 0.50–0.80: prefilled and marked "please confirm".
- < 0.50: not prefilled; top 3 shown as chips.

Thresholds sit in config and are recalibrated on the golden set in Phase 4. The item is not
ACTIVE until the user confirms.

## D-10 Outfit engine. Accepted
Pure Dart in `packages/outfit_engine`. Pipeline: eligible items (ACTIVE only) → template
slot filling → hard constraints → scoring → dedup by signature (sorted item IDs, hashed) →
exclude recent signatures → top-N (≤ 3, never padded).
Weights (FR-07): colour 0.25, style 0.20, occasion 0.20, weather 0.15, preference 0.15,
variety 0.05. When weather is absent, the weather component is **omitted**: the remaining
weights are renormalised to sum to 1.0, and the result records `weatherConsidered=false`.
Every outfit carries a per-component breakdown and reason codes.
Determinism: candidate order is stable (sorted by ID). Ties are broken by signature. Any
randomness takes an injected seed.

## D-11 Personalisation. Accepted
Learned preferences are stored separately from explicit ones (`learned_preferences` table, an
addition to the §11 list). Each like or dislike nudges bounded affinities: per item, per
colour family, per style tag, per category pair. The step is ±0.05, clamped to [-0.30, +0.30].
Updates are deterministic and order-dependent only on the feedback timestamp. A reset deletes
only learned rows. Explicit preferences are never rewritten.
*Refined in D-31 (M6):* style-tag keys were replaced by item-pair keys, and reasons were added.

## D-12 Networking: `http` only, user-initiated only. Accepted
No `dio`, no `connectivity_plus`. A single `NetworkGateway` interface is used by the weather
and model-download features. Every request is listed in `docs/NETWORK.md` with its fields.
The Android release manifest must declare `INTERNET` (Flutter only adds it to debug and
profile builds). Its use is documented and limited to those two features.

## D-13 Permissions: least privilege, no `permission_handler` initially. Accepted
- Android: the Photo Picker (via `image_picker`) needs no storage permission. The camera goes
  through an intent.
- iOS: `NSCameraUsageDescription`. PHPicker does not need library permission, so only add
  `NSPhotoLibraryUsageDescription` if the spike proves it is needed.

Denial surfaces as a typed `PermissionDeniedFailure`, with a "Open settings" hint.
Location permission: none. Weather uses manual city entry (REQUIREMENTS §6.6).

## D-14 Lints and formatting. Accepted
`flutter_lints` 6 plus analyzer `strict-casts`, `strict-inference`, `strict-raw-types`, and
`avoid_dynamic_calls`. `dart format` is enforced in CI.

## D-15 Weather provider. Resolved in M7 by D-35 and D-36
Manual weather first. The live provider is not chosen yet: candidates need a check of terms,
because some free tiers are non-commercial only. Only a user-typed city name would be sent,
never coordinates from GPS.

## D-16 Model hosting for optional downloads. Still open (mechanism built in M7, D-37)
Requires a hosting location you control, or approval to fetch directly from Hugging Face. The
manifest (URL, size, SHA-256, licence) ships **inside the app**, so a downloaded file can never
introduce new metadata.

## D-17 Material comes from `material_ui`. Accepted (M1)
Flutter 3.47 moved Material out of the framework: `package:flutter/material.dart` is deprecated
("Use package:material_ui/material_ui.dart instead"). The 3.50 template depends on
`material_ui` (flutter.dev publisher, 1.11.0). All app UI imports `material_ui`. go_router 18
already uses it.

## D-18 Transitive EOL SQLite shims are accepted. Accepted (M1)
`drift_flutter` 0.3.1 depends on `sqlite3_flutter_libs` 0.6.0+eol and `sqlcipher_flutter_libs`
0.7.0+eol. These releases are documented no-ops that stop the old 0.5.x build scripts from being
used. SQLite itself comes from `sqlite3` 3.9.1's build hook. We do not list either package
directly.

## D-19 Item deletion and outfit history. Accepted (M1)
`outfit_items.item_id` is `ON DELETE RESTRICT`. Deleting a garment that appears in outfit
history sets `clothing_items.deleted_at` (a tombstone) instead of removing the row, so history
stays intact (REQUIREMENTS §11). Garments with no history are hard-deleted, and their images,
colours, seasons and attributes cascade. A `DRAFT` status holds items between import and user
confirmation (§6.2.8).

## D-20 Infrastructure providers are injected at bootstrap. Accepted (M1)
`appSupportDirectoryProvider` and `appDatabaseProvider` throw unless overridden. Bootstrap
resolves the app-support directory and opens the database. Tests inject a temp directory and an
in-memory database. If private storage cannot be resolved, a `StartupErrorApp` is shown, and
details go only to the local log.

## D-21 Image import pipeline. Accepted (M2)
The import goes through these steps:
1. Check the extension against an allow-list (jpg, jpeg, png, heic, heif, webp).
2. Compute the SHA-256 of the file on a background isolate.
3. Check for a duplicate.
4. Copy the original byte-for-byte.
5. Create two native downscales: a 1024 px working copy at JPEG quality 85, and a 320 px
   thumbnail at quality 80.
6. Insert the item and image rows in a single transaction.

Any failure deletes the files already written, so nothing is left half-saved.
- **Originals** keep their EXIF metadata, including any location tags. They stay on the device
  and are never uploaded.
- **Working copies and thumbnails** are written without EXIF (`keepExif: false`), and their
  orientation is fixed in the pixels.
- **HEIC** decoding uses the platform codecs. Support on older Android devices still needs to
  be verified on hardware.

## D-22 Drafts are visible, not auto-deleted. Accepted (M2)
An imported photo stays a DRAFT until the user taps "Add to wardrobe". Drafts appear in the
wardrobe grid with a "Needs review" badge and open in the review form. They are never eligible
for outfits. The app never deletes drafts automatically, so a photo is never lost if the app is
killed mid-review. The user can discard a draft explicitly.

## D-23 Least-privilege picking. Accepted (M2)
- **Android:** the system Photo Picker and the camera intent are used. The manifest declares no
  CAMERA or storage permission. Photos lost when Android kills the activity are recovered with
  `retrieveLostData()` when the Wardrobe tab opens.
- **iOS:** `requestFullMetadata: false` means the photo-library permission is never requested.
  App Store policy still requires both `NSCameraUsageDescription` and
  `NSPhotoLibraryUsageDescription` in `Info.plist`, so both are present.
- **Errors:** denied access is mapped from the plugin's error codes, which were checked against
  the plugin sources, to `PermissionDeniedFailure`. The manual flow stays available.

## D-24 Orphan clean-up at launch. Accepted (M2)
After startup, a background task removes files under `images/` that no `clothing_images` row
references. These are left behind by a crash between the file write and the database commit, or
by a failed file delete. A failure is only logged, and the clean-up runs again at the next
launch.

## D-25 Tier-0 colour extraction algorithm. Accepted (M3)
Colour extraction is deterministic, pure Dart, and runs on an isolate (`lib/ai/color/`):
1. Downscale the thumbnail to 64 px.
2. Remove a uniform background using the border colour, with a ΔE76 threshold of 14.
3. Weight pixels towards the centre.
4. Cluster in CIELAB with seeded k-means (k = 5).
5. Name each cluster with L\*/C\*/h° rules, not nearest-swatch matching, so navy/blue,
   burgundy/red and beige/brown separate by lightness.

The output is the primary colour, secondary colours (share ≥ 15%) and a confidence (the primary's
share). It is reported as "multicolour" when no family reaches 35% and three or more are
significant. It is a suggestion only, and the user confirms it in the review form (M4). Thresholds
are constants, to be tuned against the golden set.
*Why rules over a model:* the result is explainable, needs no licence or download, behaves the
same on every device, and meets REQUIREMENTS §8 step 1.

## D-27 Outfit engine design details. Accepted (M5)
These refine D-10:
- **Templates:** two structural templates, *separates* (top + bottom + shoes, optional layer)
  and *one-piece* (dress or jumpsuit + shoes, optional layer).
  - Business and formal are not separate structures; their formality window is applied as a
    hard constraint on each item.
  - Below 12 °C the layer becomes required (FR-06's cold-weather template).
- **Hard constraints:** ACTIVE only; the category matches the slot; formality within the
  occasion window (casual 1–3, smart casual 2–4, business 3–5, formal 4–5, custom = chosen ±1);
  items explicitly tagged only for other seasons are excluded when weather is given; heavy items
  are excluded at 28 °C or above. **Unknown attributes never exclude an item.**
- **Bounded search:** each slot keeps its 10 best items by item-level occasion, preference,
  variety and weather fit. The search therefore stays at roughly 12k candidates whatever the
  wardrobe size. Measured: 500 items in 428–444 ms on the dev PC in JIT mode. On devices it runs
  on a background isolate.
- **Signature:** sorted item IDs joined by `+`. Plain rather than hashed, because it is
  deterministic, readable and needs no crypto dependency.
- **Selection:** greedy, with a 0.04 penalty per item shared with an already chosen outfit, so
  the three results differ. Signatures from the last 7 days are skipped; they are reused only
  when nothing else is valid, and then labelled "Suggested recently".
- **Never padded:** 0–3 results. With 0, a per-category explanation is returned (no items / not
  formal enough / not suitable for the weather).

## D-28 Colour harmony uses the painter's (RYB) wheel. Accepted (M5)
Family positions on the RYB wheel:
- Analogous: within 60° (score 0.8).
- Complementary: 150–210° apart (0.75).
- Anything else between: a mild clash (0.45).
- Neutrals (black, white, grey, beige, brown, navy): 1.0 with anything.
- Same family: 0.85 (monochrome).
- Multicolour: 1.0 with neutrals, 0.55 with other colours.
- Unknown colour: 0.65.
- More than two competing chromatic colours: a further −0.15 each.

*Why RYB:* fashion harmony rules are written on this wheel. CIELAB, which is used for colour
*naming* (D-25), places orange and blue only 133° apart. The first implementation used CIELAB,
and a unit test caught the mismatch.

## D-29 Style is inferred from item attributes. Accepted (M5)
Garments carry no style tag. The style component combines three parts:
- formality coherence (spread of formality levels).
- pattern mixing (more than one patterned piece is penalised).
- when a style is requested (or preferred in the profile), an affinity read from formality,
  pattern, colour and type. For example, minimal favours solid neutrals, and sporty favours
  sneakers or low formality.

The rules are simple and explainable, and can be replaced once AI tags exist.

## D-30 Generation pipeline and persistence. Accepted (M5)
`GenerateOutfits` (pure Dart) runs these steps:
1. Load ACTIVE items, explicit preferences and 7 days of history.
2. Run the engine through an injected runner. The app uses `Isolate.run`; tests run it inline.
3. Re-check that every returned ID is an ACTIVE item.
4. Store the results.

Shown outfits are stored in `outfits` / `outfit_items`, with the template, scores, weights and
reasons as JSON. This is the history used for variety now, and for favourites and feedback in M6.
Nothing is stored when no outfit is possible.

## D-31 Learning from feedback (refines D-11). Accepted (M6)
- **Keys and steps.** A like gives `item:<id>` +0.05, `color:<CODE>` +0.03 per distinct main
  colour, and `pair:<idA>+<idB>` +0.05 for each pair of garments worn together. Every weight is
  clamped to ±0.30 after each step.
  - D-11 also mentioned style tags. Garments have none, so pairings take that role ("these go
    well together").
- **Dislike reasons change what is learned**, so the user's intent is respected:

  | Reason | Effect |
  | --- | --- |
  | No reason, "Not my style" or "Something else" | Mirrors a like (negative) |
  | "Colours don't work" | Colours −0.03, the pairing −0.05, each garment only −0.01 |
  | "Too formal", "Too casual" or "Wrong for the weather" | The pairing −0.05, garments −0.01, colours unchanged |
  | "Wore it recently" | **No effect.** It isn't a judgement on taste |

- **The latest opinion per outfit wins.** Events are append-only, and changing a like into a
  dislike does not double-count. A "cleared" event removes the opinion.
- **Recomputed from the log, never nudged in place.** After each event the weights are rebuilt
  from all feedback since the last reset, in (createdAt, id) order. They are deterministic and
  self-healing.
- **Strict ordering.** The repository gives every new event for an outfit a timestamp later than
  that outfit's previous event. Without this, two events in the same millisecond tied and fell
  back to random UUID order. A widget test caught this as a flaky like→undo failure.
- **Reset.** Learned rows are deleted and `personalization_reset_at` is recorded, so learning
  ignores older feedback. History, favourites and explicit preferences are kept.
- **Kept separate.** Favourites never train the model. Learned weights only ever change the
  preference component (15% of the total), so one like moves an outfit's score by a predictable
  0.13 × 0.176 ≈ 0.023 without weather. A unit test asserts this exactly.

## D-32 Favourites and history UI. Accepted (M6)
- Every outfit card and the details screen have like, dislike and save buttons. Tapping the
  active rating clears it.
- Dislike opens an optional reason sheet. Dismissing the sheet records nothing; "Skip" records a
  dislike without a reason.
- The Favorites tab has two views: **Saved** (hearted outfits) and **History** (every stored
  suggestion, newest first, capped at 200 in the view).
- The preferences screen shows "Learned from your feedback" below the explicit choices: liked and
  skipped colours, counts of adjusted garments and pairings, and "Reset learning". The explicit
  reset button is labelled "Reset choices" to keep the two apart.

## D-33 AI-assisted analysis pipeline. Accepted (M4)
- **Contract (domain).** Each suggested value is a `Suggestion<T>`: the value, a confidence
  from 0 to 1, alternatives, the source model ID and version, and the analysis time, grouped
  into a `ClothingAnalysis`. `ClothingAnalyzer` never throws; failures are typed results.
- **Validation.** `OutputValidator` handles raw model output:
  - it drops NaN, infinite and negative scores.
  - it normalises scores only when they sum above 1, so mass on unmapped labels lowers
    confidence honestly.
  - it maps labels through the manifest's label table, and never invents values the taxonomy
    lacks.
- **Thresholds (D-09).** `ConfidencePolicy` is 0.80 to prefill and 0.50 to ask for
  confirmation; below that, the value appears only as tappable hints. Suggestions never
  overwrite a field the user has touched or filled, and secondary colours are offered, never
  prefilled.
- **Analyzers.** `CompositeClothingAnalyzer` runs every analyzer with a 15-second timeout.
  Partial success counts as success. A timeout or a thrown exception becomes a typed failure,
  using `TimeoutException` rather than `onTimeout`, because a narrower reified future type would
  make `onTimeout` throw. Today it contains only `ColorTier0Analyzer` (`color-tier0@1.0.0`).
- **Model registry.** A bundled `assets/models/manifest.json` (schema version 1, currently
  empty). Entries are parsed strictly. A model is loaded only if its SHA-256 matches; otherwise
  the result is a typed failure, "unavailable" or "corrupt", never a crash.
  - **The LiteRT runtime is not added yet.** `flutter_litert` would add about 8 MB per CPU
    architecture with no model to run. It joins the composite together with the first licensed
    fashion model (D-08, B-5). The M3 spike is the reference adapter.
- **Provenance.** Suggestions are stored in `clothing_attributes`, one row per value, with
  alternatives under `PRIMARY_COLOR_ALT`. They are cached per item, so reopening a draft doesn't
  re-run analysis. On save, `ConfirmAnalysis` sets `user_confirmed` for each value the user kept.
- **When it runs.** Only for items still under review. It reads the 320 px thumbnail on a
  background isolate, and the form shows immediately while analysis runs.
- **Known limitation, pinned by a test.** White garment areas on a near-white backdrop are
  removed as background. This needs segmentation (FR-05).

## D-34 No automatic retry for analysis. Accepted (M4)
Riverpod 3 retries failing providers without limit by default (200 ms backoff up to 6.4 s).
Re-analysing a photo that can't be decoded won't succeed, so `clothingAnalysisProvider` uses
`retry: _noRetry`. It fails once, and the screen falls back to manual entry.

## D-35 Live weather uses Open-Meteo. Accepted (M7, owner's choice)
The owner chose Open-Meteo over MET Norway. One request, made only when the user taps
"Get current weather" after opting in:
`GET https://api.open-meteo.com/v1/forecast?latitude&longitude&current=temperature_2m,precipitation,weather_code&timezone=UTC`.
- Data licence CC BY 4.0: the attribution "Weather data by Open-Meteo.com" is shown next to
  fetched values and in Style preferences.
- **The free API is for non-commercial use only.** A commercial release needs a paid
  Open-Meteo plan or a switch of provider (the `WeatherRepository` interface keeps that a
  one-class change). Recorded here so it is not forgotten before release.
- No API key, no cookies, 10 s timeout, results cached in memory for 15 minutes per city.
- The fetched values only fill the manual temperature slider and rain switch, which stay
  editable; any failure keeps manual weather.
- Instead of D-12's `NetworkGateway`, a single injected `http.Client` provider is the only
  HTTP client in the app. Tests replace it with a fake, so no test can reach the network.

## D-36 Offline city list, rounded coordinates. Accepted (M7)
Open-Meteo needs coordinates, but sending a typed city name to a geocoding service would add
a second request. Instead the app bundles a city list built from GeoNames `cities15000`
(CC BY 4.0) by `tools/build_cities.ps1`: places with population ≥ 50,000 plus capitals,
12,467 cities, 699 KB. Coordinates are rounded to 2 decimals (~1 km) in the asset and again
before sending, so nothing more precise than a city centre can leave the device. No location
permission is used. Search is local and accent-insensitive.

## D-37 Optional model downloads. Accepted (M7)
`ModelDownloadManager` (lib/ai/download):
- Only manifest entries with a `download` block (`https` URL, exact `sizeBytes` ≤ 200 MB) are
  downloadable. IDs and versions must be safe folder names, so a manifest cannot cause path
  traversal. An entry must have exactly one of `asset` or `download`.
- Bytes go to `models/<id>/<version>/model.bin.part`. An interrupted download resumes with a
  `Range` request (206 appends; 200 restarts; 416 discards the partial file). Pause keeps it.
- More bytes than declared, a size mismatch or a SHA-256 mismatch delete the file and record
  FAILED. Only a verified file is renamed to `model.bin` (atomic on one volume) and recorded
  INSTALLED; older versions are removed afterwards, so a failed update keeps the old model.
- The registry re-checks the SHA-256 every time it loads a model. Files are only read as
  weights, never executed.
- At startup `recover` drops records whose file vanished and versions the manifest no longer
  lists.
- There is no storage pre-check: Flutter has no free-space API without another plugin.
  Running out of space maps to `InsufficientStorageFailure` and the partial file is deleted.
- The manifest lists no downloadable models yet (D-16, P-3), so the Model manager screen says
  so and the app is unaffected.

## D-38 Tier-1 garment classifier in the app. Accepted (M4)
- **Model.** `garment-tier1` 1.0.0, trained with `training/` on Google Colab (D-08, P-3).
  MobileNetV3-Large, two heads: 23 garment types and 8 patterns. Calibrated probabilities
  (one temperature per head) are built into the file. Model card and evaluation report:
  `training/model_cards/`.
- **Variant.** Full int8 failed to load under XNNPACK, the default CPU accelerator ("Node
  number 127 failed to prepare"), so the export chose the next variant: **int8 weights, float
  activations** ("dynamic range"). 3.36 MB, agrees with the float model on 97.6% of 1,000 test
  crops. The export now always runs this check (`export_tflite.py`).
- **Test-set results** (3,426 Fashionpedia crops; photos of worn clothes): category 90.6%
  top-1; 81% of items reach the 0.80 prefill level, and those are 97% correct. Type 85% top-1,
  96% top-3. Pattern 80% top-1. Weak: cardigan, shirt/blouse, sweater, vest, floral, dotted.
  No test examples for tie or animal print.
- **Runtime.** `flutter_litert` held to 4.1.x (4.1.2 resolved), bundled runtime only, as the
  M3 spike verified (D-07). Inference runs on its own isolate; decoding and resizing run on
  another. The model is opened on first use, kept for later photos, and closed when the
  provider is disposed.
- **Input.** The whole thumbnail, resized to 224×224 without cropping, RGB 0–255 float, the
  same as `training/` evaluated.
- **Labels.** `assets/models/garment-tier1.labels.json`, named by the new optional manifest
  field `labelsAsset`, parsed strictly. Types sum into categories through `OutputValidator`.
  Ambiguous classes (shirt/blouse, T-shirt/sweatshirt, pants, shoe) suggest a category only.
  A type is dropped if it belongs to another category than the suggested one, or if it is
  below 0.15.
- **Form.** Category, type and pattern follow D-09 like colour: prefill at ≥ 0.80, prefill and
  "please confirm" at 0.50–0.80, hint chips below. Fields the user changed are never
  overwritten, and a type is only prefilled when it fits the form's category.
- **Attribution.** The On-device models screen lists the built-in model and credits
  Fashionpedia (CC BY 4.0) and the Keras ImageNet weights.
- **Android check (2026-11-17).** `integration_test/garment_model_test.dart` on the x86_64
  emulator (API 37): model opened in 423 ms; 49 ms median and 162 ms worst over 10 analyses,
  decoding included. A synthetic red T-shirt gave Top (69%, "please confirm") and Solid (74%).
  Release APK builds (89.9 MB, all ABIs). Real-phone numbers are still open.
- **Limits.** Accuracy on flat-lay and hanger photos is not measured yet (domain gap). Cached
  analyses keep only colour alternatives, so hint chips for category, type and pattern appear
  on the first review, not after reopening a draft. iOS is not built or tested.

## D-39 Background removal: our own garment segmentation model. Accepted 2026-11-17 (owner)
- **Need (FR-05).** Remove the background from flat-lay and hanger photos, and cut each garment
  out of a photo of someone wearing it. The owner chose: train our own model, and let one worn
  photo create several wardrobe items.
- **Rejected.** ML Kit subject segmentation (telemetry, D-07). MediaPipe selfie multiclass
  (Apache-2.0, but one "clothes" class for all garments, so it can't separate items).
  U²-Net (code and weights reported as Apache-2.0, but trained on DUTS, whose terms are unclear
  and labelled research-only or CC BY-NC by mirrors; it also cuts out the whole person, not
  each garment).
- **Model.** Trained in Colab on Fashionpedia masks (CC BY 4.0, already approved under P-3):
  256×256, MobileNetV3-Large encoder, light decoder, the classifier's 23 garment types plus
  background. Synthetic flat-lays (Fashionpedia garments pasted on plain backdrops) cover the
  app's usual photos. Exported with the same XNNPACK check as the classifier.
- **App rules (built in D-40).** The original photo is always kept (D-06);
  the cut-out is a separate image, and the user can switch back to the original. Segmentation
  failing never blocks adding an item. Each garment covering at least 1% of the photo is
  offered as an item; the user picks which ones to add. The classifier then runs on each
  cut-out.

## D-40 Garment cut-out in the app (FR-05). Accepted (M4)
- **Model shipped.** `garment-seg` 1.0.0, 3.84 MB, SHA-256 `39224bc4…6dd8aeab19`. Full int8
  failed under XNNPACK ("Node number 137 failed to prepare"), so the dynamic-range variant
  ships, as for the classifier. It agrees with the Keras model on 98.5% of pixels (garment vs.
  background IoU 0.982). Model card and evaluation are in `training/model_cards/`.
- **Quality (Fashionpedia test set).** Real photos: garment-vs-background IoU 0.84, 76% of
  garments found (covering at least 1% of the photo). Synthetic flat-lays: IoU 0.97, 87% found.
  Per-class IoU is low (mean 0.27): the model finds garments much better than it names them.
  It also reports many extra items, which is why the next three rules exist.
- **Grouping.** Pixels are grouped by app category, not model class, so a garment the model
  half-calls "shirt" and half "sweater" stays one garment. The model's category only labels
  the picker; the classifier (90.6% category accuracy, D-38) suggests the item's attributes
  from the cut-out.
- **Clean-up.** Within each garment, connected parts smaller than 20% of its largest part are
  removed. A garment that falls below 1% of the photo afterwards is dropped, and the masks are
  rebuilt so its pixels go back to the others. With one garment, the mask is "not background".
- **Choosing.** One garment covering at least 4% is cut out directly; a lone smaller find is
  ignored. With several, a picker shows each cut-out; those covering at least 4% start ticked.
  "Keep the whole photo" adds the photo as before.
- **Storage.** Schema v2 adds `clothing_items.show_cutout` (step-by-step migration with a data
  test). A cut-out is two transparent PNGs, `CUTOUT` (cropped, up to 1024 px) and
  `CUTOUT_THUMBNAIL` (up to 320 px), under `images/cutouts/` with a fresh name each time so image
  caches never show a replaced file. The original photo is untouched, and a switch on the
  review and details screens shows either.
- **Several items from one photo.** Each extra item is a new DRAFT with its own copies of the
  photo files, so deleting one item never affects another. The copies share the photo's
  SHA-256, so importing the photo again is still caught as a duplicate. Creating them is all
  or nothing: on any failure the new items are removed and the first keeps its photo. The first
  item opens for review; the others wait under "Needs review", and a message says so.
- **Analysis on cut-outs.** Analysis reads the thumbnail being shown. The classifier
  composites transparent pixels onto white. Colour extraction skips transparent pixels and its
  plain-border heuristic, so a white shirt on a pale backdrop is still measured correctly.
- **Android check (2026-11-17).** `integration_test/garment_segmentation_test.dart` on the
  x86_64 emulator (API 37): model opened in 538–770 ms; finding and cutting out garments in a
  1024×768 photo took 681–843 ms median, under 910 ms worst (decode, inference, masks and PNG
  encoding). On a synthetic red T-shirt the masks line up with the shape; it was labelled
  one-piece, with a spurious accessory, as expected for an image unlike any photo. Release APK
  builds (94.2 MB, all ABIs).
- **Build note.** The Dart AOT compiler crashed ("linearscan.cc: unreachable code") on this
  code until two constructs were rewritten plainly: a record-pattern assignment into `final`
  locals, and a `for`-in over five-field records with `null` fields. Which one triggered it was
  not isolated; if the crash returns after a Flutter upgrade, look at similar constructs.
- **Limits.** Not yet measured on real flat-lay, hanger or worn photos, or on a real phone.
  iOS is not built. Each extra item stores its own copy of the photo (more storage, simpler
  and safer deletes). Changing the cut-out choice does not re-run analysis.

## D-41 Official product photo through Google Lens, and a person-aware cut-out. Accepted 2026-11-18 (owner)
- **Why.** On a real worn photo (a selfie in a football shirt) the owner disliked the cut-out:
  the mesh chair behind the shoulders and things on a shelf were kept, the text was mirrored by
  the front camera, and the edges were rough. The owner wants the clean product photo the shop
  shows, like Essembl does, but free. Essembl's own method is not public; generating such
  images needs a paid cloud model (no cloud AI, P-7). Paid search APIs (Cloud Vision Web
  Detection, Lens wrappers) need keys and money and would upload photos. Free option chosen
  by the owner: hand the cut-out to Google Lens and let the user pick the product photo.
- **Requirement change (owner).** REQUIREMENTS §3 lists "sharing" as a non-goal and the app
  never uploads photos. Exception: when the user taps **Find official photo**, the app passes
  one image to Google Lens (or, without the Google app, to the app the user picks in the share
  sheet). The image is the garment cut-out flattened onto white when there is one (no face,
  no room), else the working photo. The app itself still makes no network request; Lens is a
  separate app the user chose, under Google's terms. Nothing else is shared, nothing is sent
  automatically.
- **Flow.** Find official photo → Lens opens with the image (Android: explicit intent to the
  Google app's `LensShareEntryPointActivity`, found with `cmd package query-activities`;
  fallback to the share sheet via `share_plus` 13.3.1 if it is missing) → the user saves the
  matching product photo → **Use official photo** picks it from the gallery (system Photo
  Picker, no permission) → stored as `PRODUCT` (≤1024 px JPEG) and `PRODUCT_THUMBNAIL` (≤320
  px) under `images/products/`. The item's switch then offers Cut-out / Official / Original;
  the user's photo is never changed. **Change** and **Remove** are offered. Only the share
  folder `files/visual_search/` is exposed, read-only, through the app's own FileProvider.
- **Storage.** Schema v3 adds `clothing_items.show_product` (step-by-step migration with a data
  test). The domain exposes one `ItemView` (photo, cut-out, product); the two columns are its
  storage. A missing chosen image falls back to the photo. Product thumbnails are kept for
  outfit history like cut-out thumbnails.
- **Person-aware cut-out.** The bundled `person-seg` model (MediaPipe Selfie Multiclass
  Segmentation 256×256, Apache-2.0, Google; pinned `float32/1` file, SHA-256
  `c6748b12…6507e0e0`, 16.4 MB) runs after the garment model. When at least 5% of the photo is
  a person, garment pixels are kept only where the person model sees clothes or accessories
  (grown by 2 px, with a 0.35–0.65 ramp so unsure pixels are not half-visible); background,
  skin and hair go. Flat-lays and hangers (no person) are unchanged. If the model is missing or
  fails, the garment model is used alone.
- **Why this model.** The smaller MediaPipe selfie segmenter (250 KB) needs the MediaPipe custom
  op `Convolution2DTransposeBias`, which the bundled LiteRT runtime lacks ("kTfLiteUnresolvedOps"
  on the emulator). The multiclass model uses only built-in ops and labels clothes separately
  from skin, which is what a cut-out needs. Its cost is 16.4 MB more in the app.
- **Flip.** A Flip button mirrors the cut-out (both PNGs, on an isolate) for front-camera
  selfies; the original photo is untouched.
- **Product-style display.** Cut-outs and product photos are shown on a light backdrop with
  padding, like a shop photo.
- **Android check (2026-11-18, emulator API 37).** Person model loads and runs with LiteRT; on
  the owner's selfie the garment area went from 46.4% to 44.0% of the photo, removing chair and
  arm fragments at the sides; the chair mesh just above one shoulder remains, because both
  models take it for clothing. Segmentation with both models: about 0.75 s per photo. Synthetic
  flat-lay unchanged (no person found). Find official photo opened Google Lens directly with the
  cut-out, which listed matching products; Use official photo stored the chosen image and the
  three-way switch appeared.
- **Limits.** Lens results and terms are Google's and may change; the Lens component name is
  undocumented, hence the share-sheet fallback. Saving the photo in Lens is a manual step (no
  share-back into the app yet). iOS not built: the share sheet is used there (the Google app
  offers a Lens share target). Not yet tried on a real phone.

## D-42 Editorial design system. Accepted 2026-11-18 (owner)
- **Why.** The app used stock Material 3 (seeded slate palette with a lavender tint, Roboto,
  pill indicators, cards, a "sparkles" AI icon, the default Flutter launcher icon), which
  reads as generated. The owner asked for a modern, fashion-led look with one accent, one
  radius, a spacing scale, a non-Inter font, designed empty/loading/error states, real error
  messages and meaningful motion.
- **Direction.** Editorial and type-led, as in current fashion and editorial UI: warm paper
  background, near-black ink, one accent (bottle green `#1F4D3A`; dark mode `#8CC2A6`), photos
  framed without card chrome. All text pairs meet WCAG AA (most AAA).
- **Tokens** (`lib/core/theme/tokens.dart`): spacing 4/8/12/16/24/32/48 with a 24 px page
  margin; one radius, 8 px, for every shape; motion 150/250/400 ms with ease-out for entries,
  turned off when the system asks for reduced motion. Raw numbers in widgets are a bug.
- **Type.** Instrument Serif for titles and Geist for text, both SIL OFL 1.1, bundled in
  `assets/fonts/` (Geist as static 400/500/600 instances of the variable font) and listed on
  the licences page. Nothing is downloaded at runtime.
- **Components.** Ink-filled chips and segmented buttons for selection; the accent only for the
  main action, progress and focus; a hairline above the tab bar instead of a pill indicator;
  frameless two-up wardrobe grid; cut-outs get a shadow traced from their outline so white
  garments stay visible; product photos sit on white.
- **States.** One `EmptyState`, `ErrorState` (plain-language message per failure type, retry
  where it helps) and `LoadingState`, plus pulsing skeletons where the layout is known.
- **Motion.** Staggered fade-up for grid items and states, cross-fade between photo, cut-out
  and official photo, a Hero from grid tile to item photo, and the platform page transitions
  (predictive back on Android, Cupertino on iOS).
- **Icon.** A hanger in paper white on the accent, as an Android adaptive icon (with a
  monochrome layer) and the iOS icon set.

## D-43 Automatic official photo with Google Cloud Vision. Accepted 2026-11-18 (owner)
- **Why.** The owner wants the flow "take or add a photo → remove the background → find the
  official or a similar photo by itself → suggest the official photo or the cut-out". The
  Lens hand-off (D-41) needed the user to search and save by hand. Lens has no API; scraping
  it breaks Google's terms. The owner chose Google Cloud Vision Web Detection, with their own
  API key (first 1,000 searches a month free per Google's pricing; billed beyond that).
- **Requirement change (owner).** This is the first feature that uploads an image. It is
  **off by default** and needs an explicit opt-in with a consent dialog in Style preferences.
  Only the garment cut-out, flattened onto white (no face, no room, no original photo), is
  sent, with the user's own key. Nothing else about the user or wardrobe is sent. Turning it
  off stops all requests; the rest of the app is unchanged and works offline.
- **Request.** `POST https://vision.googleapis.com/v1/images:annotate`, one request with the
  JPEG as base64 `content` and feature `WEB_DETECTION`, `maxResults` 20 (docs:
  docs.cloud.google.com/vision/docs/detecting-web). The key goes in the `X-goog-api-key`
  header, never the URL. On Android the app also sends `X-Android-Package` and
  `X-Android-Cert` (its signing SHA-1, read natively) so a key restricted to the app works.
  Images over 6 MB are not sent (the API's JSON limit is 10 MB). Timeout 20 s.
- **Ranking.** Exact matches (`fullMatchingImages`, those with a known page first), then partial
  matches, then `visuallySimilarImages`; `https` only, each once. Page titles are stripped of
  markup and shown as the source with the shop's host name.
- **Downloads.** Candidates are downloaded in order until three usable ones are found (at most
  eight tried): `https` only, `image/*` content type, at most 8 MB (checked while streaming),
  at least 200 px on the shorter side, and decodable. Files go to
  `<support>/official_photo_candidates/<itemId>/`, cleared before each search, and are only
  ever decoded as images. The chosen one is stored as the item's product photo (D-41).
- **Key storage.** The opt-in is in `app_settings`; the key is in the platform keystore with
  `flutter_secure_storage` 11.2.0 (Android Keystore-backed AES-GCM, iOS Keychain), never in the
  database or logs. It can be replaced or removed in Style preferences.
- **UI.** Under a new cut-out: "Looking for the official photo" with placeholders, then
  "Official photo found" (or "Similar product photos" when nothing matches exactly) with up to
  three choices, **Use this photo** and **Keep my cut-out**. Nothing is applied without a tap.
  No match and errors (no key, rejected key, quota, offline) say so in plain words, with
  **Search again** or **Try again**. With the feature on, the manual Lens button is hidden;
  choosing a photo from the gallery stays available.
- **Not verified.** No real API key was available, so the live API, its result quality on worn
  photos, and the Android key restriction were not tested end to end. All of it is covered by
  unit and widget tests with a fake HTTP client.

## D-44 Studio polish for cut-outs, on device. Accepted 2026-11-18 (owner)
- **Why.** The owner wants cut-outs to look like shop product photos, for free and fully on
  the phone (no cloud AI, P-7 unchanged; brief in `docs/tasks/STUDIO_PHOTO.md`). Polish uses
  only the garment's own pixels: it never invents detail.
- **Pipeline** (`lib/ai/studio/`, pure Dart, no Flutter, isolate-safe), run inside `cutOut()`
  right after the cut-out is rendered:
  1. Mask clean-up: closing with a radius of ~1% of the long edge, then transparent pixels
     enclosed by the closed garment become garment if their hole is at most 2% of the garment
     area. Larger holes are left (they may be real). Closing can bridge a narrow concave gap
     (between a sleeve and the body) and fill it; the 2% cap limits that.
  2. Those pixels get colour by push-pull diffusion from the garment around them.
  3. Defringe: each semi-transparent edge pixel within 8 px of the opaque interior takes the
     nearest opaque colour (alpha kept), which removes background tint; then a 3 × 3 feather
     of the edge band only.
  4. Straighten: principal axis from the mask's second moments; rotated only for a tilt of
     2°–15° and only if the shape is elongated enough ((λ1−λ2)/(λ1+λ2) ≥ 0.08).
  5. Light: levels p2→p98 on luma plus a gray-world white balance pulled 30% toward neutral
     and kept within ±8%, applied at the largest strength (bisection) that keeps the mean
     CIE76 ΔE of garment pixels ≤ 6 and every sampled pixel ≤ 15. Tested on dark, bright,
     white-on-white and saturated garments.
  6. Canvas: transparent **4:5 portrait**, garment at 85% of the limiting side, ≤1024 px. 4:5
     matches the item photo frame (D-42) and most shop product shots, so it fills the frame
     without letterboxing. The D-42 backdrop and traced shadow still apply when shown.
- **Storage: both files.** A polished cut-out is stored as `CUTOUT`/`CUTOUT_THUMBNAIL` (what is
  shown) plus its unpolished copy as `CUTOUT_RAW`/`CUTOUT_RAW_THUMBNAIL`. Image kinds are text,
  so there is no schema change. Analysis reads `ItemImages.analysisThumbnail`, which is the raw
  copy when the cut-out is shown, so polish cannot change detected colours or types. Flip
  mirrors all four files; replacing a cut-out replaces all four. Polishing at display time was
  rejected: it would repeat ~0.3–0.8 s of work on every view and in every grid tile.
- **Setting.** Style preferences → Cut-outs → **Studio polish**, on by default (row absent =
  on). It applies to cut-outs made from then on; existing items keep what they were saved
  with. Off = the plain cut-out, as before. The original photo is never changed; if polish
  throws or finds no garment, the plain cut-out is used.
- **Speed (Android emulator, API 37, x86_64, profile build, two-garment synthetic photo).**
  Segmentation and cut-outs without polish: p50 595 ms. With polish: p50 2.1 s, so about
  0.75 s per garment. Polish of one 740 × 690 cut-out on the desktop VM: ~260 ms (PNG
  encoding ~26 ms, so the steps themselves dominate). On the owner's selfie (debug build) the
  whole step took 3.5 s. Running the mask steps at reduced resolution is the obvious
  optimisation (next ticket).
- **Result on the owner's selfie.** Centred on the 4:5 canvas, smoother edges, a small tilt
  corrected, light evened. The chair mesh above one shoulder remains: both models label it as
  clothing, so it is opaque garment as far as polish is concerned (only a model that knows the
  garment's shape could remove it; see the inpainting spike).

## D-26 Spikes live in `spikes/`, outside the product build. Accepted (M3)
Each spike is a standalone Flutter app with its own pubspec (exact version pins) and is excluded
from the root analyzer. Downloaded model binaries are git-ignored and fetched by a script that
verifies their SHA-256, so the repository never redistributes third-party weights by accident.

---

## Approval record

**2026-11-17 (FR-05 background removal):** the owner chose to train our own garment
segmentation model on Fashionpedia (D-39) over U²-Net, and chose that a photo of someone
wearing several garments can add each of them as its own item.

**2026-11-16 (M4 training):** the owner approved P-3 as recommended (a Tier-1 model trained on
Fashionpedia, CC BY 4.0, with in-app attribution; Marqo only after legal review) and D-08
(train our own Tier-1 classifier), using Google Colab for training.

**2026-11-16 (M7):** the owner chose Open-Meteo as the live weather provider (D-35) and
approved downloading GeoNames `cities15000.zip` (CC BY 4.0) to build the offline city list.

**2026-11-16:** the owner chose "start M2", so the draft taxonomy and outfit templates (P-6,
IMPLEMENTATION_PLAN.md §4) are the working default. The values are stored as stable codes, so
they can still be extended later.

**2026-11-15:** the product owner approved the Phase 0 plan as written, including D-07 (excluding
MediaPipe and ML Kit because of their telemetry). D-07 and D-08 still depend on the Phase 3 spike
results. Where the table below gives a recommendation for P-1 and P-2, it is used as the working
default until the owner says otherwise. P-3 and P-5…P-7 still need explicit sign-off at the phase
where each one blocks work.

## Decisions explicitly awaiting the product owner (REQUIREMENTS §18)

| # | Decision | My recommendation |
| --- | --- | --- |
| P-1 | App name and branding | Keep "AI Stylist" as a placeholder; package ID `dev.placeholder.ai_stylist` |
| P-2 | Minimum OS | Android API 24, iOS 15.0 |
| P-3 | Model redistribution and licensing | Tier 1 trained on Fashionpedia (CC BY 4.0) with attribution; Marqo after legal review |
| P-4 | Delete originals after processing? | No. Keep originals; offer "remove original" per item later |
| P-5 | Encrypted-export design and password recovery | Defer to Phase 8 review. No recovery: a forgotten password means the archive is lost, with a clear warning |
| P-6 | Fashion taxonomy and templates | Draft in IMPLEMENTATION_PLAN.md §4. Please review |
| P-7 | New network transmissions | Only weather (rounded city coordinates, D-36) and model downloads. Reject MediaPipe/ML Kit telemetry |
| P-8 | Paid features | None |
