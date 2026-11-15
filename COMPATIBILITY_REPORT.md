# Dependency & AI-Model Compatibility Report

**Phase:** 0 (inspect and plan)
**Date of research:** 2026-11-15
**Sources:** pub.dev JSON API (`/api/packages/<name>`, `/score`), pub.dev package pages,
`docs.flutter.dev/reference/supported-platforms`, Flutter release index
(`storage.googleapis.com/flutter_infra_release/releases/releases_windows.json`),
google/flutter-mediapipe repository docs, Google ML Kit Terms & Data Disclosure pages,
Hugging Face model API and model cards, dataset READMEs.

Everything below was read from those sources on the date above. Nothing here has been
compiled or run yet, because no Flutter SDK is installed on this machine (see §1).
Items marked **UNVERIFIED** must be proven in the Phase 3 spike before adoption.

---

## 1. Development environment (inspected)

| Item | Found | Status |
| --- | --- | --- |
| OS | Windows 11 Pro 10.0.26300, 32 GB RAM | OK |
| Flutter SDK | **Not installed** (not on PATH; no `flutter.bat` in common locations or drive roots) | **BLOCKER** |
| Dart SDK | **Not installed** (ships with Flutter) | **BLOCKER** |
| Android SDK / `adb` / `sdkmanager` | **Not installed**; `ANDROID_HOME` unset | **BLOCKER** |
| Java | Oracle JDK 24.0.1 (`JAVA_HOME`), JRE 8 | Risk: Android tooling expects the JDK bundled with Android Studio (JBR). Use that rather than JDK 24. Check with `flutter doctor` after install. |
| Git | Installed | OK |
| Xcode / macOS | Not available (Windows host) | **BLOCKER for iOS**: no iOS build, signing or device test possible here |
| Disk | C: 20.5 GB free; D: 126 GB; F: 315 GB; G: 786 GB | Risk: Android SDK, emulator images and Gradle caches can use 15–25 GB. Put SDK, AVDs and pub/Gradle caches on D: or another large drive. |
| Working folder | Temporary session folder, not a git repo | Must move to a real project folder before Phase 1 |

### Current Flutter stable (verified from release index)

| Flutter | Dart | Released |
| --- | --- | --- |
| **3.50.0** (current stable) | 3.14.0 | 2026-11-11 |
| 3.47.9 | 3.13.7 | 2026-10-29 |

### Flutter platform support (verified, docs.flutter.dev)

- Android: supported **API 24–37** (23 and earlier unsupported).
- iOS: supported **15–27** (14 and earlier unsupported); CI-tested on 18 and 26.

These are the floor for this app. The selected AI runtime can only raise them.

---

## 2. Core Flutter dependencies (verified on pub.dev, 2026-11-15)

Pub points are out of 160. "Use" = recommended for this MVP.

| Package | Latest | Published | Dart SDK | Flutter | Points | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| flutter_riverpod | 3.5.0 | 2026-11-06 | ^3.12.0 | >=3.0.0 | 140 | **Use**: state and DI |
| riverpod_annotation | 4.0.8 | 2026-11-06 | ^3.12.0 | – | 130 | **Use** |
| riverpod_generator (dev) | 4.0.10 | 2026-11-06 | ^3.12.0 | – | 130 | **Use** |
| go_router | 18.1.4 | 2026-11-09 | ^3.12.0 | >=3.44.0 | 150 | **Use**: routing, `StatefulShellRoute` for the 4 tabs |
| drift | 2.35.4 | 2026-11-08 | >=3.10 | – | 160 | **Use**: SQLite ORM with migrations |
| drift_flutter | 0.3.1 | 2026-07-11 | >=3.10 | – | 160 | **Use**: `driftDatabase(name:)` opener |
| drift_dev (dev) | 2.35.3 | 2026-11-08 | >=3.10 | – | 130 | **Use**: codegen and schema-migration tooling |
| sqlite3 | 3.9.1 | 2026-11-08 | >=3.10 | – | 150 | Transitive (3.x bundles native SQLite via build hooks) |
| sqlite3_flutter_libs | 0.6.0+eol | 2026-02-15 | – | – | 150 | **Do not add.** End of life: obsolete with `sqlite3` 3.x (page says "no longer does anything") |
| sqlcipher_flutter_libs | 0.7.0+eol | 2026-02-15 | – | – | 145 | **Do not add.** EOL. DB encryption is not in MVP scope (FR-10 forbids claiming it) |
| image_picker | 1.2.4 | 2026-10-06 | ^3.11.0 | >=3.41.0 | 160 | **Use**: camera and gallery. Android Photo Picker needs no storage permission |
| camera | 0.12.2 | 2026-10-27 | ^3.12.0 | >=3.44.0 | 160 | **Defer**: only if a custom capture UI is approved. `image_picker` covers the MVP |
| image | 4.13.1 | 2026-11-14 | ^3.0.0 | – | 160 | **Use**: pure-Dart pixel access for colour extraction (in an isolate, on small thumbnails only) |
| flutter_image_compress | 2.5.1 | 2026-07-25 | >=2.12 | >=2.0.0 | 150 | **Use (pending spike)**: native resize and EXIF-orientation normalisation for working copies. Pure-Dart `image` is too slow for 12 MP photos |
| path_provider | 2.1.6 | 2026-06-15 | ^3.10.0 | >=3.38.0 | 160 | **Use**: app-support directory for private files |
| path | 1.9.1 | 2024-10-17 | ^3.4.0 | – | 160 | **Use**. Stable, Dart-team package; an old release date is expected |
| uuid | 4.6.0 | 2026-07-15 | >=3.0 | – | 160 | **Use**: UUID v4 primary keys |
| crypto | 3.0.8 | 2026-10-26 | ^3.4.0 | – | 160 | **Use**: SHA-256 for duplicate detection, model and archive checksums |
| shared_preferences | 2.5.6 | 2026-10-05 | ^3.11.0 | >=3.41.0 | 160 | **Not needed**: settings live in the Drift `app_settings` table, so backup has one source of truth |
| flutter_secure_storage | 11.2.0 | 2026-09-16 | >=3.8 | >=3.19.0 | 160 | **Defer to Phase 8**: only if the encrypted-export key design needs it |
| http | 1.6.0 | 2025-11-10 | ^3.4.0 | – | 160 | **Use (Phase 7)**: weather and model downloads (streamed responses, Range header for resume) |
| dio | 5.11.1 | 2026-09-04 | >=2.18 | – | 160 | **Not needed**: `http` covers both uses with a smaller surface |
| archive | 4.7.1 | 2026-11-13 | >=3.0 | – | 150 | **Use (Phase 8)**: ZIP export/import. Needs manual path-traversal and size guards |
| file_picker | 13.3.3 | 2026-11-10 | >=3.10 | >=3.38.0 | 150 | **Use (Phase 8)**: user-chosen import file and export location |
| share_plus | 13.3.1 | 2026-10-01 | >=3.10 | >=3.38.1 | 140 | **Optional (Phase 8)**: alternative export via the OS share sheet. Evaluate against `file_picker` save |
| permission_handler | 13.0.2 | 2026-09-04 | ^3.6.0 | >=3.24.0 | 160 | **Avoid unless needed**: `image_picker` surfaces denial as a `PlatformException`. Least privilege |
| connectivity_plus | 7.3.2 | 2026-10-01 | >=3.2 | >=3.7.0 | 160 | **Not needed**: network features are user-initiated; handle failure at request time |
| freezed (dev) | 4.0.3 | 2026-10-17 | >=3.13 | – | 160 | **Use**: immutable entities, sealed failures |
| freezed_annotation | 3.1.0 | 2025-07-02 | >=3.0 | – | 150 | **Use**. Pure Dart, so allowed in the domain layer |
| json_serializable (dev) / json_annotation | 6.15.2 / 4.12.0 | 2026-10 / 2026-05 | ^3.12 / ^3.9 | – | 160/150 | **Use**: backup manifest, model manifest, analysis-output schema |
| build_runner (dev) | 2.17.1 | 2026-10-14 | ^3.11.0 | – | 160 | **Use** |
| mocktail (dev) | 1.0.5 | 2026-04-10 | >=2.12 | – | 160 | **Use**: test doubles |
| flutter_lints (dev) | 6.0.0 | 2025-05-27 | ^3.8.0 | – | 160 | **Use**, plus `strict-casts`, `strict-inference`, `strict-raw-types` |
| very_good_analysis | 11.0.0 | 2026-09-03 | ^3.13.0 | – | 160 | Alternative to `flutter_lints` (stricter) |
| cryptography | 2.9.0 | 2025-11-21 | >=3.3 | – | 130 | **Candidate (Phase 8)**: AES-GCM and KDF for encrypted export. Needs design review; points and cadence lower |
| pointycastle | 4.0.0 | 2025-02-19 | ^3.2.0 | – | 140 | Fallback candidate for Phase 8 |
| equatable | 3.0.0 | 2026-09-15 | >=3.0 | – | 160 | Not needed if `freezed` is used |
| material_color_utilities | 0.13.1 | 2026-08-10 | – | – | 150 | **Use**: CAM16/HCT colour science for colour naming and harmony. Already a Flutter SDK dependency |
| palette_generator | 0.3.3+7 | 2025-05-06 | – | – | 140 | **Do not use**: **discontinued** |

All "Use" packages declare SDK constraints satisfied by Dart 3.14 / Flutter 3.50.
Actual resolution (`flutter pub get`) is **UNVERIFIED** until the SDK is installed.

---

## 3. On-device AI runtimes (verified on pub.dev + vendor docs)

| Package | Latest | Published | Publisher | Points | 30-day downloads | Platforms |
| --- | --- | --- | --- | --- | --- | --- |
| **flutter_litert** | 4.1.1 | 2026-11-11 | hugo.ml (community, verified publisher) | 160 | 18,877 | android, ios, desktop, web |
| tflite_flutter | 0.12.1 | 2025-10-28 | tensorflow.org | 140 | 75,688 | android, ios, desktop |
| tflite_flutter_helper | 0.3.1 | 2021-12-22 | tensorflow.org | 120 | – | **Discontinued** |
| litert_flutter | 0.0.1 | 2024-10-28 | tensorflow.org | 140 | 8 | Placeholder, not usable |
| **mediapipe_vision** | 0.3.0 | 2026-11-12 | google.dev | 160 | 838 | android, ios, desktop, web |
| mediapipe_task_vision | 0.0.1 | 2023-03-23 | tensorflow.org | 140 | 15 | Abandoned |
| google_mlkit_image_labeling | 1.0.3 | 2026-11-13 | flutter-ml.dev | 160 | 24,089 | android, ios |
| google_mlkit_object_detection | 1.0.3 | 2026-11-13 | flutter-ml.dev | 160 | 16,077 | android, ios |
| google_mlkit_subject_segmentation | 0.3.2 | 2026-11-10 | flutter-ml.dev | 160 | 7,141 | android, ios |
| flutter_onnxruntime | 1.9.0 | 2026-10-06 | masic.ai | 150 | 41,945 | android, ios, desktop, web |
| onnxruntime | 1.4.1 | 2024-03-27 | (none) | 150 | 18,952 | Stale |
| executorch_flutter | 0.9.1 | 2026-11-15 | zcreations.info | 160 | 480 | android, ios, desktop, web. Pre-1.0 |
| pytorch_lite | 4.3.2 | 2025-01-09 | – | 130 | – | **Discontinued** (replaced by executorch_flutter) |

### 3.1 Telemetry (decisive finding)

The MVP forbids telemetry (CLAUDE.md #5, REQUIREMENTS §4 and FR-10). Two of the strongest
candidates send usage data to Google, and the app cannot switch this off:

- **MediaPipe Tasks (`mediapipe_vision`)**: the package's own `doc/privacy_and_licenses.md`
  says Google's MediaPipe runtimes "send usage metrics to Google". The metrics cover the task,
  running mode, latencies and input counts. On Android and iOS the uploads also carry the app
  ID and version, and the OS, Dart and Flutter versions. Uploads go to
  `play.googleapis.com/log`, one request per task close, and "The packages cannot turn the
  logging off." On Android the upload fires whenever the app has the INTERNET permission,
  which this app needs for the optional weather and model downloads.
  → **Rejected for the MVP.** Images are not sent, but this is still third-party telemetry.
- **Google ML Kit (all `google_mlkit_*`)**: Google's ML Kit Terms say the APIs "send metrics
  about the performance and utilization of the APIs in your app to Google". The Android data
  disclosure lists device info, app info and performance metrics "for diagnostics and usage
  analytics".
  → **Rejected for the MVP**, for the same reason. The base image-labelling model is also
  generic, not fashion-specific.

The `mediapipe_vision` package does exist and is maintained under `google/flutter-mediapipe`,
contrary to the caution in CLAUDE.md. It is new (v0.1.0 → 0.3.0, 838 downloads in 30 days),
needs Android minSdk 28 and iOS 15, and adds about 13 MB per ABI on Android. It is technically
capable, but excluded on privacy grounds unless the product owner explicitly accepts the
telemetry (REQUIREMENTS §18: "Any new network transmission or analytics").

### 3.2 Recommended runtime: LiteRT via `flutter_litert` (bundled runtime)

Verified from the package README:

- A fork of `tflite_flutter` with a source-compatible `Interpreter` API, plus the newer
  LiteRT `CompiledModel` API. It bundles native libraries automatically, where
  `tflite_flutter` needs a manual dynamic-library step.
- Bundled LiteRT version 2.3.2 (from the NPU section).
- **minSdk 24 on Android** since 4.0.0, which matches Flutter's floor. iOS: the Interpreter
  API works on iOS 15. Core ML NPU needs iOS 16 (optional).
- Delegates: XNNPACK CPU everywhere; Metal and Core ML on iOS; Android GPU only through
  `CompiledModel` (the Interpreter GPU delegate was removed in 4.0.0).
- `IsolateInterpreter` for off-UI-thread inference, which meets REQUIREMENTS §9.
- An *opt-in* "LiteRT from Google Play services" mode exists. **We will not enable it.** It
  downloads the runtime at first use and goes through Play services. The default bundled
  runtime keeps everything in the APK.
- Licence: to be confirmed from the package `LICENSE` in the spike. LiteRT itself is
  Apache-2.0.

**UNVERIFIED (spike exit criteria):**
1. The bundled LiteRT runtime makes **no network connections**. Capture traffic on an Android
   device or emulator (with INTERNET granted) and on iOS.
2. A fashion model (§4) loads and runs on Android arm64, Android x86_64 emulator, iOS device
   and iOS simulator.
3. 16 KB page-size compatibility on Android 15+ (Play requirement). Not stated on the page.
4. Release IPA symbol stripping. `tflite_flutter` documents a "Failed to lookup symbol" issue.
   Check whether `flutter_litert` has it.

**Risks:** single community publisher (bus factor), and fast major-version churn (3.x → 4.x
removed APIs). Mitigation: put it behind our `InferenceRuntime` adapter, and pin exact
versions.

**Fallbacks, in order:**
1. `tflite_flutter` 0.12.1 (official publisher, but no release for about 13 months and a
   manual native-library step). Same `.tflite` model format, so models carry over.
2. `flutter_onnxruntime` 1.9.0 (ONNX Runtime 1.28; **iOS 16 minimum**; 16 KB-compliant since
   1.5.1). Useful if the selected model converts better to ONNX than to LiteRT. Not chosen as
   primary: it raises the iOS floor and would mean a second model format.
3. `executorch_flutter`: pre-1.0, too new for the MVP.

---

## 4. Fashion-specific models (verified on Hugging Face, 2026-11-15)

REQUIREMENTS §8 says generic ImageNet classification is not enough. **No ready-made,
mobile-sized, licence-clean fashion classifier in `.tflite` format was found.** Candidates:

| Model | Licence (weights) | Training data / base | Size | Fit for MVP |
| --- | --- | --- | --- | --- |
| **Marqo/marqo-fashionSigLIP** | Apache-2.0 | Fine-tuned from ViT-B-16-SigLIP (WebLI) with GCL on categories, styles, colours, materials. Evaluated on DeepFashion, Fashion200k, KAGL, Polyvore, Atlas | Vision tower ONNX: fp32 354.5 MB, fp16 177.3 MB, **int8 89.6 MB**, q4 58.3 MB | **Best quality candidate.** Zero-shot: precompute text embeddings for our taxonomy prompts offline and ship only the vision tower. Too large to bundle, so it is an optional download. Conversion to LiteRT, and accuracy after int8, are UNVERIFIED |
| Marqo/marqo-fashionCLIP | Apache-2.0 | Fine-tuned ViT-B-16 (LAION-2B) | Vision int8 83.3 MB | Same approach, slightly weaker per Marqo's own benchmark |
| patrickjohncyh/fashion-clip | MIT | ViT-B/32, trained on Farfetch data (800K products, "awaiting official release") | 577 MB (fp32 combined) | Card says "not developed for model deployment". Biased to white-background product shots. Not preferred |
| yainage90/fashion-object-detection | MIT | Conditional-DETR R50 trained on **ModaNet (CC BY-NC 4.0)** + Fashionpedia | 166 MB | **Rejected**: non-commercial training-data licence. DETR is also heavy for mobile |
| valentinafevu/yolos-fashionpedia | MIT | YOLOS on Fashionpedia (CC BY 4.0) | 117 MB | Possible detector, but a transformer detector is slow on mobile. Not needed for one-garment photos |
| sayeed99/segformer-b2/b3-fashion | "other" | – | – | Rejected: unclear licence |
| yainage90/fashion-image-feature-extractor | MIT | Swin, crawled user posts (onthelook, kream) | 332 MB | Rejected: scraped-data provenance |
| HopitAI/moda-fashion-* | MIT | Unknown | – | Not evaluated. Low adoption |

**Datasets (licence verified):**
- **Fashionpedia**: CC BY 4.0 (dataset card). Images are Flickr-sourced with per-image licences. Usable for training **with attribution**.
- **ModaNet**: annotations **CC BY-NC 4.0**. Not usable for a commercial product.
- **DeepFashion / DeepFashion2**: non-commercial research licence (from prior knowledge; recheck if used). Avoid.

### 4.1 Recommended model strategy (needs approval; see DECISIONS D-07, D-08)

1. **Tier 0, always on, no model:** deterministic Dart colour extraction (k-means in CIELAB
   on a downsampled, centre-weighted thumbnail, in an isolate) and manual category entry.
2. **Tier 1, bundled small model (target ≤ 10 MB):** a MobileNetV3 or EfficientNet-Lite
   garment classifier for our taxonomy (category, subcategory, pattern), trained on
   **Fashionpedia crops** (CC BY 4.0), optionally **distilled from Marqo-FashionSigLIP**
   (Apache-2.0) as a teacher. Exported to `.tflite` int8 with a reproducible script kept in
   `tools/model_training/`.
   *Requires a Python/GPU training environment, which is not on this machine.*
3. **Tier 2, optional download:** the Marqo-FashionSigLIP vision tower (int8, about 90 MB)
   with precomputed text-prompt embeddings, for higher-quality zero-shot attributes. Download
   only after user consent, with a pinned SHA-256 (FR-09).

Until Tier 1 exists, the app ships with Tier 0 only. That meets FR-04's "AI failure must not
prevent manual entry", but **not** MVP acceptance criterion #4 ("AI can classify the
supported initial categories on-device").

---

## 5. Platform floors implied by the recommendation

| | Android | iOS |
| --- | --- | --- |
| Flutter 3.50 floor | API 24 | 15.0 |
| flutter_litert (Interpreter) | API 24 | 15.0 (Core ML NPU: 16) |
| image_picker / go_router / drift | ≤ Flutter floor | ≤ Flutter floor |
| If ONNX fallback used | API 24 | **16.0** |
| If MediaPipe were accepted | **API 28** | 15.0 |

**Proposed:** Android **minSdk 24**, iOS **15.0**. Needs approval (REQUIREMENTS §18).

---

## 6. Open verification items, carried into the Phase 3 spike

1. `flutter pub get` resolves the full dependency set on Flutter 3.50 / Dart 3.14.
2. LiteRT bundled runtime: no network egress (packet capture), 16 KB page size, iOS release symbols.
3. Model conversion: SigLIP vision tower → `.tflite` (or ONNX fallback). Check numerical
   parity with the PyTorch reference (cosine similarity ≥ 0.99 on 50 images).
4. Latency, memory and init time on one low-, one mid- and one high-tier Android device, and
   one iPhone. **Needs hardware.**
5. Accuracy on a licensed or synthetic golden set (≥ 200 images across categories),
   reporting top-1 per attribute.
