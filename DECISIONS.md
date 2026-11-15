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

---

## Approval record

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
