# Model Register

Every model the project uses, in the product or in experiments, with its provenance, licence and
status. REQUIREMENTS FR-09 and §18 require licensing to be approved before any model ships.

| ID | Purpose | Source | Licence | Size | SHA-256 | Status |
| --- | --- | --- | --- | --- | --- | --- |
| `color-tier0` (v1.0.0) | Colour families (Tier 0) | Deterministic code in `lib/ai/color/` (no weights) | Project code | – | – | **Shipped** (M4): pre-fills the main colour on the review screen |
| `efficientnet-lite0-int8` | Runtime test only | Google MediaPipe model storage (see the spike report §5) | Apache-2.0 per Google model cards | 5.18 MB | `bc2ffe19…a34b16` | **Spike only, never shipped** |
| `efficientnet-lite0-float32` | Runtime test only | Same | Same | 17.72 MB | `6c7ab0a6…c8bde0` | **Spike only, never shipped** |
| `garment-tier1` (v1.0.0) | Category, type, pattern (Tier 1) | Trained on Fashionpedia (CC BY 4.0) with `training/` on Google Colab; MobileNetV3-Large backbone, Keras ImageNet weights (Apache-2.0) | CC BY 4.0 data, attribution required (P-3 approved 2026-11-16) | 3.36 MB (int8 weights, float activations) | `d562792c…ed8dc397` | **Shipped** (M4, D-38): bundled; category 90.6% / type 85% / pattern 80% top-1 on the Fashionpedia test set; not yet measured on flat-lay photos |
| `garment-seg` (v1.0.0) | Garment cut-out and separation (FR-05) | Trained on Fashionpedia masks (CC BY 4.0) with `training/garment_segmentation.ipynb`; MobileNetV3-Large backbone, Keras ImageNet weights (Apache-2.0) | CC BY 4.0 data, attribution required (P-3) | 3.84 MB (int8 weights, float activations) | `39224bc4…6dd8aeab19` | **Shipped** (D-39, D-40): bundled; garment-vs-background IoU 0.84 on real photos and 0.97 on synthetic flat-lays, 76% / 87% of garments found; not yet measured on real flat-lays or phones |
| `marqo-fashionsiglip-vision` (candidate) | Optional zero-shot attributes (Tier 2) | huggingface.co/Marqo/marqo-fashionSigLIP | Apache-2.0 (weights). Training-data provenance not fully documented | ~90 MB int8 ONNX | – | **Candidate**: needs conversion and parity checks, plus legal review |

## Attribution obligations

- **Fashionpedia** (trained `garment-tier1` and `garment-seg`): CC BY 4.0. Credited, with a link to the licence and
  a note of the changes, on the On-device models screen (Settings → On-device models).
- **Marqo-FashionSigLIP** (if shipped or downloaded): Apache-2.0. Include the licence and NOTICE.
- **LiteRT runtime** (`flutter_litert`, bundled): include the licences of the runtime and its
  native libraries in the open-source notices.

## Rejected

| Model | Reason |
| --- | --- |
| yainage90/fashion-object-detection | Trained on ModaNet (CC BY-NC 4.0, non-commercial) |
| DeepFashion-trained models | Non-commercial research licence |
| yainage90/fashion-image-feature-extractor | Trained on scraped data |
| sayeed99/segformer-*-fashion | Licence "other", unclear |
| U²-Net / u2netp | Trained on DUTS, whose terms are unclear (research-only or CC BY-NC per mirrors); cuts out the whole person, not each garment (D-39) |
| MediaPipe Tasks and ML Kit bundles | Runtimes send usage metrics to Google (COMPATIBILITY_REPORT §3.1) |
