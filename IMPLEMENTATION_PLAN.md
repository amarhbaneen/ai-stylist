# AI Stylist — Implementation Plan

Source of truth: `REQUIREMENTS.md`. Engineering rules: `CLAUDE.md`.
Decision rationale: `DECISIONS.md`. Package and model evidence: `COMPATIBILITY_REPORT.md`.
Status: **Phase 0 complete, awaiting review.** No application code has been written.

---

## 1. Blockers (must clear before Phase 1 can be *verified*)

| # | Blocker | Impact | Resolution |
| --- | --- | --- | --- |
| B-1 ✅ | Flutter SDK not installed. Resolved: Flutter 3.50.0 at D:\dev\flutter | Nothing can be built, analysed or tested | Install Flutter 3.50.0 stable (on D:, not C:, because C: has 20.5 GB free) and add it to PATH |
| B-2 ✅ | Android SDK/toolchain not installed. Resolved: Android Studio and SDK installed; debug APK builds | No Android build | Install Android Studio (bundles a JBR that Flutter uses) and the SDK + platform-tools + an emulator image on D:. Run `flutter doctor --android-licenses` |
| B-3 | No macOS / Xcode | No iOS build, signing or test | Needs a Mac, or a macOS CI runner (your decision: CI builds code only and never touches user data) |
| B-4 | No physical test devices known | Performance budgets (REQUIREMENTS §14) cannot be measured | Need 1 low-, 1 mid-, 1 high-tier Android device and 1 iPhone, or a device lab |
| B-5 | No licence-clean, mobile-sized fashion classifier exists off the shelf | MVP acceptance #4 cannot be met by Phase 4 without one | Approve D-08: train or distil a Tier-1 model (needs a Python/GPU environment) |
| B-6 ✅ | Session folder is temporary, not a git repo. Resolved: D:\dev\ai_stylist, pushed to GitHub | Work would be lost; no feature branch | Move to a permanent project folder, `git init`, branch `feature/m1-foundation` |
| B-7 | Product decisions P-1…P-8 (DECISIONS.md) | P-2 and P-6 are needed for Phase 1–2 | Review and approve |

Independent work (docs, pure-Dart engine design) can continue while B-3, B-4 and B-5 are open.

---

## 2. Target architecture

```
┌──────────────────────────── Flutter app (lib/) ─────────────────────────────┐
│ app/          bootstrap, router (go_router StatefulShellRoute: Home │       │
│               Wardrobe │ Stylist │ Favorites), theme, error boundary        │
│ features/<f>/ presentation ─► application (use cases) ─► domain interfaces  │
│                     ▲                                       ▲               │
│               data (Drift DAOs, mappers, repo impls) ───────┘               │
│ ai/           model_registry · preprocessing · runtime adapter · analyzers  │
│ core/         database (Drift), storage (FileStore), errors, logging(local) │
└─────────────┬───────────────────────────────────────────────┬───────────────┘
              │ depends on                                    │ depends on
┌─────────────▼──────────────┐                 ┌──────────────▼──────────────┐
│ packages/wardrobe_domain   │◄────────────────│ packages/outfit_engine      │
│ pure Dart: entities,       │                 │ pure Dart: templates,       │
│ taxonomy enums, failures,  │                 │ hard filters, scorers,      │
│ repository interfaces      │                 │ ranking, preference learning│
└────────────────────────────┘                 └─────────────────────────────┘
```

**AI path:**
`AnalyzeClothingUseCase` → `ClothingAnalyzer` (domain interface) →
`CompositeClothingAnalyzer`, which combines:
- `ColorExtractor`: pure Dart, run in an isolate.
- `GarmentClassifier`: uses the `InferenceRuntime` adapter (LiteRT through `flutter_litert`,
  `IsolateInterpreter`). Optional.
- `ZeroShotAttributeAnalyzer`: uses a downloaded model. Optional.

→ `AnalysisValidator` (schema plus thresholds) → `ClothingAnalysis` (suggestions only;
nothing is persisted as ACTIVE until the user confirms).

**Interfaces (REQUIREMENTS §12):** `WardrobeRepository`, `ProfileRepository`,
`OutfitRepository`, `ClothingAnalyzer`, `BackgroundRemover`, `ModelManager`,
`WeatherRepository`, `BackupRepository`. Added: `FileStore`, `InferenceRuntime`,
`NetworkGateway`, `Clock`, `IdGenerator`, `PreferenceLearner`.

**Typed failures:** `sealed class AppFailure` with subtypes `StorageFailure`,
`InsufficientStorageFailure`, `PermissionDeniedFailure`, `UnsupportedImageFailure`,
`DuplicateItemFailure`, `ModelUnavailableFailure`, `ModelCorruptFailure`,
`InferenceFailure`, `NetworkFailure`, `ArchiveValidationFailure`, `CancelledFailure`.
Use cases return `Result<T, AppFailure>`. No catch-and-ignore.

### Database schema v1 (Drift)

| Table | Key columns |
| --- | --- |
| `user_profile` | id, preferred_styles (json), favored_colors, avoided_colors, fit_pref, formality_pref, created_at, updated_at |
| `clothing_items` | id, category, subcategory, display_name, notes, primary_color, pattern, formality(1–5), fit, brand, warmth(1–3), status(ACTIVE/ARCHIVED/DRAFT), content_sha256 (unique among non-deleted), created_at, updated_at |
| `clothing_item_colors` | item_id FK, color, role(primary/secondary) |
| `clothing_item_seasons` | item_id FK, season |
| `clothing_images` | id, item_id FK, kind(original/working/thumbnail/cutout), rel_path, width, height, bytes |
| `clothing_attributes` | id, item_id FK, attribute, value, confidence, model_id, model_version, analyzed_at, user_confirmed |
| `outfits` | id, signature, occasion, request_json, total_score, breakdown_json, reasons_json, weather_considered, created_at, is_favorite |
| `outfit_items` | outfit_id FK, item_id FK (**ON DELETE RESTRICT**; hard delete of an item becomes a soft "deleted" tombstone so history is preserved), slot |
| `outfit_feedback` | id, outfit_id FK, kind(LIKE/DISLIKE), reason_code, reason_text, created_at |
| `learned_preferences` | key (e.g. `color:navy`), weight, updated_at |
| `model_installations` | model_id, version, rel_path, sha256, size, license, state(installed/staged/failed), installed_at |
| `app_settings` | key, value |

DRAFT status is an addition. It holds an item between import and user confirmation (§6.2.8).
Drafts are never eligible for outfits, and orphaned drafts are cleaned on startup.

---

## 3. Milestones and acceptance criteria

Each ticket follows the CLAUDE.md "Definition of done". The Android build is verified
locally. The iOS build is documented, and verified only when B-3 is cleared.

### M0: Phase 0 — Inspect and plan ✅ (this document)
Deliverables: IMPLEMENTATION_PLAN.md, DECISIONS.md, COMPATIBILITY_REPORT.md.

### M1: Phase 1 — Foundation (REQ M1) ✅ Android verified 2026-11-15; iOS pending (B-3)
- Create the app with `flutter create --org <P-1> --platforms android,ios`. Set up the pub
  workspace with the two pure-Dart packages.
- Lints, `analysis_options.yaml`, CI script (`format`, `analyze`, `test`, `build apk --debug`).
- Theme and design-system tokens (neutral identity, accessible contrast, text-scale safe).
- go_router shell with 4 tabs and placeholder screens. Riverpod `ProviderScope` and bootstrap
  with a zone and `FlutterError` handler that logs **locally only**.
- Drift DB schema v1, schema dump, migration test harness, DAOs, `FileStore` with temp-then-rename.

**Accept when:** the app launches to the shell on an Android emulator in airplane mode;
`flutter analyze` is clean; DB open/close, foreign-key enforcement and FileStore tests pass;
the iOS build steps are documented.

### M2: Phase 2 — Wardrobe without AI (REQ M2, part of M3)
- Onboarding and privacy explanation, with optional and skippable preferences (FR-01).
- Add-clothing flow: camera or gallery → hash/duplicate check → private copy → working copy
  and thumbnail → manual classification form → confirm → ACTIVE.
- Wardrobe grid, filters (category, colour, season, formality, status), search, details,
  edit, archive, delete with confirmation.
- Tests: CRUD, foreign keys, archive/delete, transaction rollback, file lifecycle (orphans,
  deletion), permission denial, cancellation, unsupported image, low storage (simulated
  `FileStore` failure).

**Accept when:** a user can add, edit, archive and delete items fully offline, and the data
survives an app restart (integration test).

### M3: Phase 3 — AI compatibility spike (isolated `spikes/ai_runtime/` app)
- Run `flutter_litert` with a reference model on Android arm64, Android emulator, iOS device
  and iOS simulator.
- Network-egress capture with INTERNET granted. 16 KB page-size check. iOS release symbol check.
- Convert the Marqo-FashionSigLIP vision tower to `.tflite` and check parity against the
  reference. Train or distil the Tier-1 classifier (B-5).
- Measure model size, init time, p50/p95 latency, peak RSS and accuracy on the golden set.
- Record licences and attribution in `docs/MODELS.md`.

**Accept when:** a written spike report shows a model running on both platforms with
measured numbers, or documents why not and selects the fallback adapter.

### M4: Phase 4 — AI-assisted analysis (REQ M3)
Preprocessing contract, model registry, `InferenceRuntime` adapter, validator, thresholds,
review/edit UI with confidence badges, stored model ID/version/timestamp. Model lifecycle:
lazy load, dispose on memory pressure, never block the UI. Tests: loading/disposal, corrupt
model, schema validation, thresholds, golden images.
Segmentation (FR-05) only after the classifier works, and only if a licence-clean model is
verified. Otherwise defer.

### M5: Phase 5 — Outfit engine (REQ M4)
`packages/outfit_engine` with templates (§4), hard filters, the six scorers, weight
normalisation, weather omission, dedup, recent-history exclusion, 0–3 results, missing-category
explanation. Stylist UI: occasion, style, weather, count → results → outfit details.
**Accept when:** the deterministic unit-test suite passes, including property tests that every
result references only ACTIVE IDs and that no result violates a hard constraint; and
generation for 500 items completes in under the budget measured in M3.

### M6: Phase 6 — Feedback and personalisation (REQ M5)
Like, dislike, reason, favourite/unfavourite, history, `PreferenceLearner` (D-11), reset.
**Accept when:** tests show that a like raises, and a dislike lowers, the rank of matching
candidates by a bounded, predictable amount; and that reset restores the baseline ranking
exactly.

### M7: Phase 7 — Optional services (REQ M6)
Manual weather. Live weather behind consent (provider per D-15). Model manager UI. Downloads
with the in-app manifest, storage pre-check, `.part` temp file, Range resume, SHA-256
verification, atomic rename, rollback to the previous version, removal. `docs/NETWORK.md`.
**Accept when:** every core flow passes with the network disabled, and when downloads are
interrupted or corrupt.

### M8: Phase 8 — Backup, security, release (REQ M7, M8)
ZIP export/import (schema version, manifest with per-file SHA-256, path normalisation and
rejection of `..` and absolute paths, entry-count, per-file and total uncompressed size caps,
staging then confirm-overwrite). Encrypted export only after the P-5 design review.
Permission, manifest and privacy-manifest review (`PrivacyInfo.xcprivacy`). Airplane-mode,
low-storage, corrupt/missing model, restart and interrupted-import tests. Release builds and a
signing-steps doc (no fabricated credentials).

---

## 4. Draft taxonomy and templates (needs approval: P-6)

**Categories → subcategories** (inclusive; no gendered categories):
- `TOP`: t-shirt, shirt, blouse, polo, sweater, hoodie, tank, other
- `BOTTOM`: jeans, trousers, chinos, shorts, skirt, leggings, other
- `ONE_PIECE`: dress, jumpsuit, overall, other
- `OUTERWEAR`: jacket, blazer, coat, cardigan, vest, other
- `FOOTWEAR`: sneakers, boots, dress shoes, loafers, sandals, heels, flats, other
- `ACCESSORY`: bag, hat, scarf, belt, tie, other (optional slots only)
- `UNKNOWN`

**Attributes:**
- Colour: about 16 named families (black, white, grey, navy, blue, red, green, …), plus a
  neutral flag.
- Pattern: solid, striped, checked, floral, graphic, dotted, animal, other, UNKNOWN.
- Seasons: spring, summer, autumn, winter (multi-select).
- Formality 1–5: 1 = lounge, 2 = casual, 3 = smart casual, 4 = business, 5 = formal.
- Warmth 1–3. *Proposed addition*, used by the weather scorer.
- Fit: slim, regular, relaxed, oversized, UNKNOWN.

**Templates** (data-driven, slot-based, extensible):

| Template | Required slots | Optional | Occasions |
| --- | --- | --- | --- |
| Separates | TOP + BOTTOM + FOOTWEAR | OUTERWEAR, ACCESSORY | casual, smart casual |
| Business separates | TOP(formality ≥ 3) + BOTTOM(≥ 3) + FOOTWEAR(≥ 3) | OUTERWEAR(blazer/jacket) | business |
| One-piece | ONE_PIECE + FOOTWEAR | OUTERWEAR | all; formality filters by occasion |
| Formal | (TOP + BOTTOM, or ONE_PIECE) with formality ≥ 4 + FOOTWEAR ≥ 4 | OUTERWEAR | formal |
| Cold-weather modifier | any base template + OUTERWEAR (warmth ≥ 2) | – | applied when temperature < threshold |

**Hard constraints:** ACTIVE only; one item per slot; no duplicate item; every required slot
filled; occasion formality window (for example business requires ≥ 3); season exclusion only
when weather is given; user "never pair" rules (future).

---

## 5. Testing strategy (summary)

- `packages/*`: `dart test`, 100 % of scoring and constraint branches, plus seeded
  property-based tests.
- App unit: use cases with mocktail fakes. Drift with in-memory `NativeDatabase` plus
  generated migration tests.
- Widget: onboarding, add/edit/delete, manual fallback, stylist results, favourites.
- Integration (`integration_test`): end-to-end add → generate → like → restart → persist;
  airplane mode; backup round-trip.
- Fixtures: synthetic or licensed images only (REQUIREMENTS §15).

---

## 6. Risks

| Risk | Likelihood | Mitigation |
| --- | --- | --- |
| No fashion model meets quality and licence bar in time | High | Tier-0 manual and colour always works; ship Tier 1 when ready |
| `flutter_litert` single-maintainer, API churn | Medium | Adapter interface; pinned versions; `tflite_flutter`/ONNX fallbacks |
| LiteRT bundled runtime has hidden egress | Low (unverified) | Packet-capture gate in M3 |
| SigLIP conversion fails or int8 accuracy collapses | Medium | ONNX fallback adapter; fp16 variant; keep Tier 2 optional |
| iOS untested on this machine | Certain | Mac or CI required before beta; documented |
| Pure-Dart image work too slow | Medium | Native resize via `flutter_image_compress`; colour on 128 px thumbnails in an isolate |
| Low disk on C: | Medium | SDKs and caches on D: |
| Scope creep (LLM, try-on, sharing) | – | Out of scope per REQUIREMENTS §3 |

---

## 7. Next recommended ticket

**M1-T1:** install the toolchain (B-1, B-2), move to a permanent repo (B-6), and approve P-1
and P-2. Then scaffold the Flutter app plus the pub workspace, lints and CI script, and show
`flutter doctor` and `flutter analyze` output.
