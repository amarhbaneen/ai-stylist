# Tier-1 clothing classifier training

Trains the small on-device model that suggests a garment's **type** (and so its category)
and **pattern** (DECISIONS D-08; licensing approved under P-3). This folder is Python and
runs on Google Colab. It is **not part of the app build**: only the exported `.tflite` file
and `labels.json` are copied into the app.

## Run it

1. Open `fashion_classifier.ipynb` in Colab (File → Upload notebook, or open from GitHub).
2. Runtime → Change runtime type → **GPU** (T4 is enough).
3. Run the cells in order. Outputs are saved to Google Drive under `ai_stylist_training/`.
4. Send back `garment-tier1.tflite`, `labels.json`, `model_card.json` and
   `eval_report.json`.

## What it does

| Step | Script | Output |
| --- | --- | --- |
| Crop one garment per box, map labels | `prepare_data.py` | `crops/{train,val,test}/*.jpg`, CSVs, `*_report.json` |
| Fine-tune MobileNetV3 with two heads | `train.py` | `model.keras`, `history.csv` |
| Accuracy, calibration, app-level stats | `evaluate.py` | `calibration.json`, `eval_report.json` |
| LiteRT export and XNNPACK check | `export_tflite.py` | `garment-tier1.tflite`, `labels.json`, `model_card.json` |

- **Data:** Fashionpedia. The official val set is our test set. 10% of the training *photos*
  become val, so crops from one photo never sit in both.
- **Labels:** `config/label_map.json` maps Fashionpedia categories to the app taxonomy.
  Ambiguous classes ("shirt, blouse", "pants", "shoe") map to a category only, with no
  subcategory. Pattern attributes are mapped by keyword, and the mapping is printed for
  review. Preparation fails if a configured name is not in the annotation file.
- **Model:** MobileNetV3-Large (ImageNet weights, Apache-2.0), input float32 RGB 0–255 at
  224×224, outputs `type` and `pattern` probabilities. Full int8 is about 3.6 MB; float32 is about 12 MB.
- **Calibration:** one temperature per head, fitted on val, is built into the exported
  model, so the app's 0.80 and 0.50 thresholds (D-09) mean what they say.
- **Quantization:** float input and output, so the app feeds plain 0–255 RGB. The export
  tries variants in order: full int8 (TFLiteConverter representative dataset, or
  `--quantizer litert`), then int8 weights only ("dynamic"), then float16. Each one is run
  with the default CPU runtime, XNNPACK included, because phones use it too. The first that
  XNNPACK can prepare and that agrees with the Keras model on at least 97% of test crops
  becomes `garment-tier1.tflite`. `model_card.json` records every variant's result, and the
  export exits 1 if none passes.

## Known limitations

- **Domain gap:** Fashionpedia photos show clothes being worn. The app's photos are often
  flat-lays or on hangers. Accuracy on real app photos must be measured separately before
  shipping (a small golden set of phone photos).
- Fine-grained types the data can't separate (jeans vs trousers, sneakers vs boots) are not
  predicted; the user picks them.
- Patterns are only learned from garments that have a pattern attribute.

## Local tests

The data preparation needs only Python 3.10+ and Pillow:

```bash
python -m unittest discover -s tests -v
```

Training, evaluation and export need TensorFlow (preinstalled on Colab).

## Licences and attribution

- Fashionpedia annotations: CC BY 4.0. The app must credit Fashionpedia.
- Fashionpedia images are not owned by Fashionpedia (Flickr, Unsplash, Pexels and others).
  They are used only for training and never shipped. The prepare step reports their licences.
- Keras MobileNetV3 ImageNet weights: Apache-2.0.
