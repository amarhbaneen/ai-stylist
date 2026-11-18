# Inpainting spike (not part of the product)

Measures small inpainting models for filling garment areas hidden by an arm or a phone
(D-26 spike; results in `docs/spikes/INPAINT_REPORT.md`).

- `tool/fetch_models.ps1` downloads MI-GAN 512 fp16 and LaMa-Dilated fp32 and checks the
  SHA-256 Hugging Face publishes for each. Weights are git-ignored.
- Test photos go in `assets/images/` and are never committed (they show real people and
  brand product photos): `jersey.png`, `selfie.png` (512 × 512) and
  `<photo>_arm_mask.png` / `<photo>_phone_mask.png` (white = hidden).
- `integration_test/inpaint_benchmark_test.dart` runs every model on every case and prints
  `INPAINT_RESULT` JSON lines (timing, memory, error vs. the hidden ground truth).

```
pwsh tool/fetch_models.ps1
flutter drive --profile --driver=test_driver/integration_test.dart \
  --target=integration_test/inpaint_benchmark_test.dart -d <device>
```

Exact pins: `flutter_litert` 4.1.2, `image` 4.13.1.
