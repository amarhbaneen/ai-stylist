# Model Register

Every model the project uses, in the product or in experiments, with its provenance, licence and
status. REQUIREMENTS FR-09 and §18 require licensing to be approved before any model ships.

| ID | Purpose | Source | Licence | Size | SHA-256 | Status |
| --- | --- | --- | --- | --- | --- | --- |
| `color-tier0` | Colour families (Tier 0) | Deterministic code in `lib/ai/color/` (no weights) | Project code | – | – | **In product code** (UI wiring in M4) |
| `efficientnet-lite0-int8` | Runtime test only | Google MediaPipe model storage (see the spike report §5) | Apache-2.0 per Google model cards | 5.18 MB | `bc2ffe19…a34b16` | **Spike only, never shipped** |
| `efficientnet-lite0-float32` | Runtime test only | Same | Same | 17.72 MB | `6c7ab0a6…c8bde0` | **Spike only, never shipped** |
| `fashion-tier1` (planned) | Category, type, pattern | To be trained on Fashionpedia (CC BY 4.0), optionally distilled from Marqo-FashionSigLIP | Depends on the training data (P-3) | target ≤ 10 MB | – | **Blocked**: training environment and licence sign-off |
| `marqo-fashionsiglip-vision` (candidate) | Optional zero-shot attributes (Tier 2) | huggingface.co/Marqo/marqo-fashionSigLIP | Apache-2.0 (weights). Training-data provenance not fully documented | ~90 MB int8 ONNX | – | **Candidate**: needs conversion and parity checks, plus legal review |

## Attribution obligations (to include in the app's licences screen once shipped)

- **Fashionpedia** (if used to train `fashion-tier1`): CC BY 4.0. Credit the Fashionpedia authors
  and link the licence.
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
| MediaPipe Tasks and ML Kit bundles | Runtimes send usage metrics to Google (COMPATIBILITY_REPORT §3.1) |
