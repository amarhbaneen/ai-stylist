# M3 Spike Report: On-device AI Runtime

**Date:** 2026-11-16
**Branch:** `feature/m3-ai-spike`
**Spike app:** `spikes/ai_runtime/` (standalone; not part of the product)
**Status:** Partial. The runtime is verified on an Android emulator. iOS, physical devices and the
fashion model are still open (§6).

Every number below was measured in this session. Nothing is estimated or taken from vendor
benchmarks, except where marked as a citation.

---

## 1. Question

Can `flutter_litert` (LiteRT, DECISIONS D-07) load and run a `.tflite` image model on-device, off
the UI thread, without network traffic, inside a Play-compliant APK? And what does it cost in
time, memory and size?

## 2. Setup

| Item | Value |
| --- | --- |
| Flutter / Dart | 3.50.0 / 3.14.0 |
| Package | `flutter_litert` 4.1.1 (pinned), bundled runtime (Play-services mode **off**) |
| Runtime reported by `Interpreter.version` | 2.23.0 |
| API used | `Interpreter.fromBuffer` (4 CPU threads, XNNPACK default) + `IsolateInterpreter` |
| Device | Android Emulator, `Medium_Phone_API_37.0`, x86_64, 3 GB RAM, Windows host |
| Reference models | Google MediaPipe EfficientNet-Lite0, int8 and float32 (§5). Generic ImageNet, **not fashion** |
| Input | `assets/images/synthetic_tee.jpg`, a generated navy T-shirt shape (no real photo) |
| Protocol | 3 warm-up runs, then 30 timed runs per model. Release build. Repeated 3 times |

## 3. Results

### 3.1 Inference: release build, x86_64 emulator, 3 rounds

| Model | File | Load + allocate | p50 | p95 | Min | RSS growth | Max RSS (process) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| EfficientNet-Lite0 int8 | 5.18 MB | 21–28 ms | 51–55 ms | 69–88 ms | 34–41 ms | ≈ +44 MB | 200–206 MB |
| EfficientNet-Lite0 float32 | 17.72 MB | 10–11 ms | 32–33 ms | 41–50 ms | 28 ms | ≈ +55 MB | 249–255 MB |

- **Preprocessing** (decode, resize to 224 px, pack into the tensor, in Dart) took 64–87 ms. M4
  should feed the already-downscaled working copy, and run preprocessing on the isolate.
- **The first `IsolateInterpreter` start** in a process took 89–123 ms. Later starts took 2–8 ms.
- **Debug build, for comparison:** int8 p50 204 ms, float32 p50 60 ms. Debug numbers are not
  representative and must not be used for budgets.
- **int8 was slower than float32 on the emulator.** x86 hosts emulate int8 kernels inefficiently.
  Google cites a Pixel 6 CPU at 10.08 ms for int8 vs 23.52 ms for float32 (MediaPipe image
  classifier page). **The int8 vs float32 choice must be made on real ARM devices.**

### 3.2 Output sanity

Both variants returned the same top classes for the synthetic T-shirt. Labels were read from the
`labels_without_background.txt` embedded in the model file:

| Rank | int8 | float32 |
| --- | --- | --- |
| 1 | 400 academic gown (0.22) | 400 academic gown (0.26) |
| 2 | 667 mortarboard (0.13) | 610 jersey (0.19) |
| 3 | 610 jersey (0.09) | 667 mortarboard (0.14) |

The int8 and float32 outputs agree, so quantisation is consistent. The generic ImageNet model
ranks "academic gown" above "jersey" for a plain navy T-shirt, which confirms REQUIREMENTS §8:
**generic ImageNet classification is not adequate for garments.**

### 3.3 Network egress: **PASS** (Android emulator)

| Check | Result |
| --- | --- |
| Network state during run | Airplane mode **off**; `ping 8.8.8.8` succeeded |
| `INTERNET` permission | Granted (debug build) |
| Sockets owned by the app's UID (10237), sampled every 1 s during the run | One only: `127.0.0.1:33377` in LISTEN state (the Dart VM service of a debug build). No remote endpoints |
| Kernel per-UID traffic (`dumpsys netstats`, `mAppUidStatsMap`) | 13 UIDs had traffic; **none for 10237 (spike) or 10236 (AI Stylist)** |

The bundled LiteRT runtime made no network connections. This is the property that ruled out
MediaPipe Tasks and ML Kit (COMPATIBILITY_REPORT §3.1).

### 3.4 Google Play 16 KB page size: **PASS**

- `zipalign -c -P 16 -v 4` passes for every `.so` in the release APK.
- `llvm-readelf -lW` (NDK 28.2) shows the minimum `LOAD` segment alignment for each library:

| Library (arm64-v8a and x86_64) | Min LOAD alignment |
| --- | --- |
| `libLiteRt.so`, `libLiteRtClGlAccelerator.so`, `libflutter_litert_runtime.so`, `libtflite_custom_ops.so` | 16 384 bytes |
| `libflutter.so`, `libapp.so` | 65 536 bytes |

### 3.5 Size cost (release APK, uncompressed sizes)

| ABI | `libLiteRt.so` | `libLiteRtClGlAccelerator.so` (GPU) | Other LiteRT stubs |
| --- | --- | --- | --- |
| arm64-v8a | 5.37 MB | 3.10 MB | 0.02 MB |
| x86_64 | 7.42 MB | 3.74 MB | 0.02 MB |
| armeabi-v7a | 3.48 MB | (not shipped) | 0.01 MB |

- The GPU accelerator is bundled by default. While inference is CPU-only, M4 should exclude it to
  save about 3 MB per ABI. `flutter_litert` documents a Gradle property for this; it must be
  verified before relying on it.
- A Play App Bundle delivers one ABI per device, so the runtime adds about 5.4 MB on a typical
  arm64 phone, plus the model.

## 4. What this means for the plan

1. **D-07 (LiteRT via `flutter_litert`, bundled runtime) holds on Android.** It loads models from
   memory, runs off the UI thread, makes no network calls and meets the 16 KB rule. It stays
   *Proposed* until iOS is checked.
2. **D-08 is confirmed.** A generic classifier mislabels a plain T-shirt, so Tier 1 needs a
   fashion-trained model.
3. **Performance budgets** cannot be set from emulator numbers (REQUIREMENTS §14). Even so,
   tens of milliseconds for a 224 px CNN shows the runtime is not the bottleneck: preprocessing
   (~65–90 ms) is.
4. **Tier 0 colour extraction is done** (`lib/ai/color/`, §7). It does not depend on any model.

## 5. Reference model provenance

| File | Source | SHA-256 | Licence |
| --- | --- | --- | --- |
| `efficientnet_lite0_int8.tflite` (5 434 517 B) | `storage.googleapis.com/mediapipe-models/image_classifier/efficientnet_lite0/int8/1/` | `bc2ffe19c1118de0c0c2a9088992da5589722656e0fba81421385300a4a34b16` | Apache-2.0 per Google's MediaPipe model cards (as documented by `google/flutter-mediapipe`) |
| `efficientnet_lite0_float32.tflite` (18 582 189 B) | `…/float32/1/` | `6c7ab0a6e5dcbf38a8c33b960996a55a3b4300b36a018c4545801de3a3c8bde0` | same |

These models are used only to test the runtime. They are not committed (`.gitignore`) and will not
ship. Run `spikes/ai_runtime/tool/fetch_models.ps1` to download and verify them.

## 6. Not verified, and why

| Item | Blocker | Next step |
| --- | --- | --- |
| iOS device and simulator, iOS release symbol stripping | No macOS (B-3) | Run the spike on a Mac. Check `Strip Style` in an archive build |
| Real-device latency and memory (low, mid and high tier) | No hardware (B-4) | Run the spike's release APK; it logs `SPIKE_RESULT` JSON |
| Fashion classifier (Tier 1) | No training environment (B-5), licence sign-off (P-3) | See D-08 |
| Marqo-FashionSigLIP → `.tflite` conversion and parity | Needs Python tooling | Run with Tier-1 work |
| Accuracy on a golden set | Needs a licensed or synthetic labelled set | Build it alongside Tier 1 |
| Thermal and battery impact | Physical devices | Same as latency |

## 7. Tier 0: deterministic colour extraction (delivered)

`lib/ai/color/`, pure Dart, run on an isolate by `ImageColorAnalyzer`:
1. Decode the 320 px thumbnail and downscale it to 64 px.
2. Detect a uniform border and remove pixels within ΔE76 14 of it, unless that would leave less
   than 8% of the pixels.
3. Weight pixels towards the centre.
4. Cluster in CIELAB with k-means (k = 5, 12 iterations, fixed seed 42, k-means++ start).
5. Name each cluster with L\*/C\*/h° rules.
6. Report shares per family:
   - The largest family is the primary colour.
   - Others with a share of at least 15% are secondary.
   - The result is "multicolour" when the top share is below 35% and three or more families are
     significant.

32 unit tests cover: 22 reference colours, solid and striped garments, multicolour, a garment the
same colour as the background, a busy background, determinism, isolate decoding of a JPEG file,
and corrupt or missing files. Wiring it into the review screen as an editable suggestion is M4.
