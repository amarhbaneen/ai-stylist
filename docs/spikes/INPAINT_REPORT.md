# Inpainting spike: filling garment areas hidden by an arm or a phone

Status: spike complete 2026-11-18 (Ticket B of `docs/tasks/STUDIO_PHOTO.md`). Not integrated
into the app. Code: `spikes/inpaint/` (standalone, D-26).

## Question

Can a small on-device model fill the parts of a garment that an arm, a hand or a phone hides
in a worn photo, under the app's rules: free, on the phone, licence that allows commercial use,
LiteRT built-in ops only (like `person-seg`, D-41), and good enough to be worth it?

## Candidates (checked 2026-11-18 against current sources)

| Candidate | Licence | Weights | LiteRT, built-in ops | Size | Verdict |
| --- | --- | --- | --- | --- | --- |
| **MI-GAN 512 (Places2)**, Picsart AI Research, ICCV 2023 | **MIT** (repo and HF card) | Public. LiteRT build `litert-community/MI-GAN-512-Places2-LiteRT` | **Yes**: loads and runs with the app's runtime (`flutter_litert` 4.1.2), no custom ops | **16.3 MB** (fp16) | **Recommended** |
| **LaMa-Dilated**, LaMa authors (dilated-conv variant, no FFT) | Apache-2.0 (LaMa). The conversion used here is `mlboydaisuke/LaMa-Dilated-LiteRT` (Apache-2.0). Qualcomm AI Hub ships its own compiled files under Qualcomm's asset terms: not used | Public | **Yes** | 174 MB (fp32) | Works but slower, larger and blurrier than MI-GAN |
| **Big LaMa** (Fourier convolutions) | Apache-2.0 | Public (PyTorch) | **No**: LiteRT has a built-in `RFFT2D` but no inverse FFT (`schema.fbs`), so the spectral blocks need Select TF ops (the large Flex runtime) or a rewrite | ~51M params | Not converted |
| **AOT-GAN** (Qualcomm AI Hub asset) | Unclear: the card's licence link points to a different project (AttnGAN); compiled asset under Qualcomm terms | Public zip, no published hash | Not tested | 58 MB | Excluded until the licence is clear |
| **Moebius** (HUST / vivo, ECCV 2026) | MIT tag on `hustvl/Moebius` (paper page CC BY-NC-SA) | Public, PyTorch only | No mobile build; 0.22B params (≈0.45 GB at fp16) | — | Too large for this use; revisit if a mobile export appears |
| **DreamLite** (ByteDance, arXiv 2603.28713, 0.39B) | Code Apache-2.0, **weights CC BY-NC 4.0** (non-commercial, no redistribution) per the official repo | `ByteVisionLab/DreamLite-*` not publicly accessible on Hugging Face (2026-11-18) | — | — | **Excluded**: non-commercial weights; also a text-guided editor, not an inpainter |

Hashes are pinned from Hugging Face's LFS metadata in `spikes/inpaint/tool/fetch_models.ps1`
(MI-GAN `ef53f8dc…63c25f`, LaMa-Dilated `a2ac8ed1…efe583`); the weights are git-ignored.

## Method

- Android emulator (Medium Phone, API 37, x86_64), `flutter drive --profile`, CPU, 4 threads,
  no GPU delegate (the emulator's GPU is software). 3 runs per case; p50 reported.
- Memory: process RSS before loading and after running (`ProcessInfo`).
- Four cases at 512 × 512, each with a synthetic occluder so the hidden pixels have ground
  truth: the official jersey product photo and the owner's worn selfie (local only, never
  committed), each with an **arm** (a 58 px diagonal band across the torso) and a **phone**
  (an 80 × 150 block over the chest print).
- Score: mean absolute error (0–255) and PSNR over the hidden pixels only. Baseline: the app's
  classical push-pull fill (D-44).
- Input contract used: RGB with the hidden mask. In the app this would be the polished cut-out
  on its backdrop, and "hidden" = garment hull minus visible garment (see Integration notes).

## Results

| Model | Init | p50 per image | RSS added | jersey arm (MAE / PSNR) | jersey phone | selfie arm | selfie phone |
| --- | --- | --- | --- | --- | --- | --- | --- |
| push-pull (baseline) | — | 37–66 ms | — | 8.0 / 24.9 | 40.0 / 12.6 | 53.3 / 10.9 | 39.9 / 12.9 |
| **MI-GAN 512 fp16** | 33 ms | **1.8 s** | **~275 MB** | **3.1 / 34.2** | **27.9 / 12.5** | **35.6 / 12.3** | 33.9 / 12.1 |
| LaMa-Dilated fp32 | 160 ms | 13.3 s | ~860 MB | 5.3 / 30.7 | 29.1 / 13.7 | 38.9 / 12.4 | **27.1 / 13.8** |

What the images show (reviewed side by side):

- **Push-pull** leaves blocky grey patches: fine for pinholes (its D-44 job), useless for an
  arm-sized area. A model is needed for this.
- **MI-GAN** fills plain fabric convincingly: on the product photo the arm band disappears
  almost perfectly, folds and shading continue. Over printed text or logos it **invents
  strokes** ("FLY BETTER" becomes unreadable marks). No model can recover hidden lettering.
- **LaMa-Dilated** is smudgier, with visible blur and ghosting over the print, and costs 7×
  the time and 3× the memory.

The MI-GAN model card reports that XNNPACK rejects this fp16 graph. With `flutter_litert` 4.1.2
it ran on the CPU without error on the emulator; real-phone CPU speed is not measured (the
card reports ~6 ms on a phone GPU, ~1.8 s on a Raspberry Pi 5 CPU).

## Recommendation

**MI-GAN 512 (MIT), as an optional download (D-37), opt-in, never bundled.**

- Use it only for areas the person hides (arm, hand, phone), not to "improve" visible
  fabric, and show the result as a separate, clearly labelled view ("Filled") next to the
  polished cut-out, which stays the default. The original photo is never changed. This keeps
  D-44's rule that polish uses only real pixels; filling is a separate, visible choice.
- Warn when the hidden area overlaps print or a logo, or simply always say "filled areas are
  estimated". Text and logos under an arm cannot be restored by any model.
- Run at 512 × 512 on the garment crop and paste back only the hidden pixels, upscaled, so
  the visible garment keeps its full resolution.
- Places2 training means the model knows textures and scenes, not garments. Fine-tuning on
  Fashionpedia masks (as for `garment-seg`) is the path to better results on clothing, later.

## Integration notes (for the follow-up ticket)

- **Hidden mask.** "Garment hull minus visible garment" also includes real gaps (between an arm
  and the torso, under the chin). A better mask: pixels the person model labels as body skin
  or "other" (hand, phone) inside the garment's hull. The multiclass person model already runs
  (D-41), so this costs nothing extra.
- **Memory.** ~275 MB extra while running: load on demand, close right after, never keep it
  resident.
- **Download.** 16.3 MB through the existing manager (manifest, SHA-256, atomic install).

## Open (blockers for a final decision)

- **Real occluded photos.** The quality numbers use synthetic occluders on two photos. Before
  integration, run the spike on 3–4 real worn photos where an arm or a phone covers the garment
  (owner to supply; they stay local).
- **Real phones.** Timing and memory on mid- and low-tier Android phones (B-4); iOS not built.
- AOT-GAN licence; Moebius mobile export.

## Reproduce

```
cd spikes/inpaint
pwsh tool/fetch_models.ps1
# put jersey.png, selfie.png and the *_mask.png files in assets/images/ (local only)
flutter drive --profile --driver=test_driver/integration_test.dart \
  --target=integration_test/inpaint_benchmark_test.dart -d <device>
```

## Sources

- MI-GAN: github.com/Picsart-AI-Research/MI-GAN (MIT);
  huggingface.co/litert-community/MI-GAN-512-Places2-LiteRT; huggingface.co/andraniksargsyan/migan
- LaMa: github.com/advimman/lama (Apache-2.0); huggingface.co/mlboydaisuke/LaMa-Dilated-LiteRT;
  huggingface.co/qualcomm/LaMa-Dilated
- LiteRT built-in operators: google-ai-edge/LiteRT `tflite/converter/schema/schema.fbs`
  (`RFFT2D` only); developers.google.com/edge/litert/models/ops_select
- AOT-GAN: huggingface.co/qualcomm/AOT-GAN
- Moebius: huggingface.co/hustvl/Moebius; arxiv.org/abs/2606.19195
- DreamLite: github.com/ByteVisionLab/DreamLite (weights CC BY-NC 4.0); arxiv.org/abs/2603.28713
