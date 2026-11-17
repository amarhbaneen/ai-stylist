"""Exports the segmentation model to LiteRT and picks a shippable variant.

Usage:
  python -m ai_stylist_training.seg_export --data data/seg --run out/seg1 \
      --model-id garment-seg --version 1.0.0

Same rules as export_tflite.py: float32 input (RGB 0-255, 256x256) and
output (per-pixel class probabilities), variants tried in order int8 ->
dynamic -> float16, each run with XNNPACK because phones use it. A variant
is accepted when its per-pixel class agrees with Keras on >= 97% of pixels
and its garment-vs-background mask keeps >= 95% IoU with Keras.
Writes <model-id>.tflite, seg_labels.json and seg_model_card.json.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path

import keras
import numpy as np
import tensorflow as tf

from . import label_map as lm
from .export_tflite import NO_DELEGATES, _op_at, convert_dynamic, convert_float16
from .seg_data import dataset
from .seg_metrics import MIN_AREA_SHARE
from .seg_model import with_softmax
from .seg_prepare import SIZE

PIXEL_AGREEMENT_FLOOR = 0.97
FG_IOU_FLOOR = 0.95


def labels_json(labels: lm.LabelMap) -> dict:
    return {
        "schemaVersion": 1,
        "task": "garment-segmentation",
        "input": {"name": "image", "size": SIZE,
                  "format": "float32 [1,256,256,3] RGB 0-255, whole photo resized"},
        "output": {"name": "mask", "format": "float32 [1,256,256,C] class probabilities"},
        "minAreaShare": MIN_AREA_SHARE,
        "classes": [{"index": 0, "label": "background"}] + [
            {"index": i + 1, "label": c.label, "category": c.category, "subcategory": c.subcategory}
            for i, c in enumerate(labels.classes)
        ],
    }


def convert_int8(saved: Path, data: Path, n: int) -> bytes:
    ds = dataset(data, "val", 1, training=False).take(n)

    def gen():
        for image, _ in ds:
            yield [image]

    converter = tf.lite.TFLiteConverter.from_saved_model(str(saved))
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.representative_dataset = gen
    converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
    return converter.convert()


def run_tflite(path: Path, images: np.ndarray) -> tuple[np.ndarray, dict]:
    interpreter = tf.lite.Interpreter(model_path=str(path))  # default delegates: XNNPACK
    runner = interpreter.get_signature_runner()
    input_name = next(iter(runner.get_input_details()))
    output_name = next(iter(runner.get_output_details()))
    out = [np.asarray(runner(**{input_name: im[None].astype(np.float32)})[output_name])[0]
           for im in images]
    io = {
        "inputs": {k: {"shape": v["shape"].tolist(), "dtype": np.dtype(v["dtype"]).name}
                   for k, v in runner.get_input_details().items()},
        "outputs": {k: {"shape": v["shape"].tolist(), "dtype": np.dtype(v["dtype"]).name}
                    for k, v in runner.get_output_details().items()},
    }
    return np.stack(out), io


def compare(probs: np.ndarray, reference: np.ndarray) -> dict:
    pred, ref = probs.argmax(-1), reference.argmax(-1)
    fg, ref_fg = pred > 0, ref > 0
    return {
        "pixelAgreement": round(float((pred == ref).mean()), 4),
        "foregroundIoUvsKeras": round(float((fg & ref_fg).sum() / max((fg | ref_fg).sum(), 1)), 4),
        "maxProbDiff": round(float(np.abs(probs - reference).max()), 6),
    }


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--data", type=Path, required=True)
    p.add_argument("--run", type=Path, required=True)
    p.add_argument("--label-map", type=Path, default=lm.DEFAULT_LABEL_MAP)
    p.add_argument("--model-id", default="garment-seg")
    p.add_argument("--version", default="1.0.0")
    p.add_argument("--calibration-samples", type=int, default=200)
    p.add_argument("--check-samples", type=int, default=200)
    args = p.parse_args(argv)

    labels = lm.load(args.label_map)
    model = keras.models.load_model(args.run / "model.keras", compile=False)
    inference = with_softmax(model)
    saved = args.run / "seg_saved_model"
    inference.export(str(saved))
    float_path = args.run / f"{args.model_id}-float32.tflite"
    float_path.write_bytes(tf.lite.TFLiteConverter.from_saved_model(str(saved)).convert())

    images = np.stack([x[0].numpy() for x, _ in
                       dataset(args.data, "test", 1, training=False).take(args.check_samples)])
    reference = np.asarray(inference.predict(images, verbose=0)["mask"])

    variants = [
        ("int8", lambda: convert_int8(saved, args.data, args.calibration_samples)),
        ("dynamic", lambda: convert_dynamic(saved)),
        ("float16", lambda: convert_float16(saved)),
    ]
    results: list[dict] = []
    chosen = None
    for name, convert in variants:
        try:
            content = convert()
        except Exception as e:  # noqa: BLE001 - record and try the next variant
            results.append({"variant": name, "converted": False, "error": f"{type(e).__name__}: {e}"})
            continue
        path = args.run / f"{args.model_id}-{name}.tflite"
        path.write_bytes(content)
        result: dict = {"variant": name, "file": path.name, "sizeBytes": len(content)}
        try:
            probs, io = run_tflite(path, images)
        except RuntimeError as e:
            result.update(xnnpack=False, error=str(e).strip(), failingOp=_op_at(path, str(e)))
            results.append(result)
            print(json.dumps(result, indent=2))
            continue
        result.update(xnnpack=True, **compare(probs, reference))
        results.append(result)
        print(json.dumps(result, indent=2))
        if (result["pixelAgreement"] >= PIXEL_AGREEMENT_FLOOR
                and result["foregroundIoUvsKeras"] >= FG_IOU_FLOOR):
            chosen = (name, path, io)
            break

    seg_labels = labels_json(labels)
    (args.run / "seg_labels.json").write_text(json.dumps(seg_labels, indent=2), encoding="utf-8")
    if chosen is None:
        (args.run / "seg_model_card.json").write_text(json.dumps(
            {"modelId": args.model_id, "version": args.version, "shippable": False,
             "variants": results}, indent=2), encoding="utf-8")
        print("ERROR: no variant passed the XNNPACK and agreement checks. Do not ship.")
        return 1

    name, path, io = chosen
    content = path.read_bytes()
    final = args.run / f"{args.model_id}.tflite"
    final.write_bytes(content)
    sha = hashlib.sha256(content).hexdigest()
    card = {
        "modelId": args.model_id, "version": args.version, "shippable": True, "variant": name,
        "file": final.name, "sizeBytes": len(content), "sha256": sha,
        "floatSizeBytes": float_path.stat().st_size, "io": io, "variants": results,
        "labels": seg_labels,
        "license": "Model weights: project licence. Trained on Fashionpedia annotations "
                   "(CC BY 4.0, attribution required). Backbone: Keras ImageNet weights.",
        "manifestEntry": {
            "id": args.model_id, "version": args.version, "task": "garment-segmentation",
            "title": "Garment cut-out", "asset": f"assets/models/{args.model_id}.tflite",
            "labelsAsset": f"assets/models/{args.model_id}.labels.json",
            "sha256": sha, "license": "CC-BY-4.0 (Fashionpedia annotations)",
        },
    }
    (args.run / "seg_model_card.json").write_text(json.dumps(card, indent=2), encoding="utf-8")
    print(f"Chosen: {name} -> {final.name} ({len(content):,} bytes, sha256 {sha})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
