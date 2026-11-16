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

## D-08 Fashion model strategy: tiered. Proposed (needs licensing approval)
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

## D-15 Weather provider. Deferred to Phase 7 (needs approval)
Manual weather first. The live provider is not chosen yet: candidates need a check of terms,
because some free tiers are non-commercial only. Only a user-typed city name would be sent,
never coordinates from GPS.

## D-16 Model hosting for optional downloads. Deferred to Phase 7 (needs decision)
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

## D-26 Spikes live in `spikes/`, outside the product build. Accepted (M3)
Each spike is a standalone Flutter app with its own pubspec (exact version pins) and is excluded
from the root analyzer. Downloaded model binaries are git-ignored and fetched by a script that
verifies their SHA-256, so the repository never redistributes third-party weights by accident.

---

## Approval record

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
| P-7 | New network transmissions | Only weather (city name) and model downloads. Reject MediaPipe/ML Kit telemetry |
| P-8 | Paid features | None |
