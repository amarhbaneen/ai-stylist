"""Exports the calibrated model to LiteRT (.tflite), quantized to int8.

Usage:
  python -m ai_stylist_training.export_tflite --crops data/crops --run out/run1 \
      --model-id garment-tier1 --version 1.0.0

Steps:
1. Wraps the model with calibrated softmax heads (calibration.json).
2. Converts to a float32 .tflite (from a SavedModel, the documented path).
3. Quantizes weights and activations to int8, keeping float32 input/output
   so the app feeds plain 0-255 RGB. Default: the TFLiteConverter
   representative-dataset path. `--quantizer litert` tries the newer LiteRT
   Quantizer package (Google now marks quantizing during conversion as
   deprecated) and falls back if its API differs.
4. Runs the .tflite files with tf.lite.Interpreter on test crops and checks
   they agree with the Keras model.
5. Writes model_card.json: size, SHA-256, accuracy, I/O tensors, and the
   manifest entry for assets/models/manifest.json.
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
from .data import NO_PATTERN, dataset, read_rows
from .model import with_softmax

AGREEMENT_FLOOR = 0.97  # int8 top-1 must match float on >= 97% of test crops


def representative(crops: Path, labels: lm.LabelMap, n: int):
    ds = dataset(crops, "val", labels, 1, training=False).take(n)

    def gen():
        for image, _ in ds:
            yield [image]

    return gen


def quantize_legacy(saved_model: Path, crops: Path, labels: lm.LabelMap, n: int) -> bytes:
    converter = tf.lite.TFLiteConverter.from_saved_model(str(saved_model))
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.representative_dataset = representative(crops, labels, n)
    converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
    # inference_input_type / inference_output_type stay float32 (the default).
    return converter.convert()


def quantize_litert(float_path: Path, crops: Path, labels: lm.LabelMap, n: int) -> bytes:
    """LiteRT Quantizer (pip install litert-quantizer). The API follows the
    migration guide; any mismatch raises and the caller falls back."""
    from litert_quantizer import calibrator, quantizer  # type: ignore[import-not-found]

    interpreter = tf.lite.Interpreter(model_path=str(float_path))
    input_name = next(iter(interpreter.get_signature_runner().get_input_details()))
    samples = [
        {input_name: image.numpy().astype(np.float32)}
        for image, _ in dataset(crops, "val", labels, 1, training=False).take(n)
    ]
    qt = quantizer.Quantizer(str(float_path))
    qt.load_quantization_recipe("static_wi8_ai8")
    result = qt.calibrate(
        {"serving_default": samples},
        mode=calibrator.CalibrationMode.CALIBRATION_PROFILER_BASED,
    )
    quantized = qt.quantize(calibration_result=result)
    for attr in ("quantized_model", "model_content", "content"):
        data = getattr(quantized, attr, None)
        if isinstance(data, (bytes, bytearray)):
            return bytes(data)
    raise RuntimeError("could not read bytes from the LiteRT Quantizer result")


def run_tflite(model_path: Path, images: np.ndarray) -> tuple[dict[str, np.ndarray], dict]:
    interpreter = tf.lite.Interpreter(model_path=str(model_path))
    runner = interpreter.get_signature_runner()
    input_name = next(iter(runner.get_input_details()))
    outputs: dict[str, list] = {}
    for image in images:
        result = runner(**{input_name: image[None].astype(np.float32)})
        for k, v in result.items():
            outputs.setdefault(k, []).append(np.asarray(v, np.float32)[0])
    io = {
        "inputs": {k: {"shape": v["shape"].tolist(), "dtype": np.dtype(v["dtype"]).name}
                   for k, v in runner.get_input_details().items()},
        "outputs": {k: {"shape": v["shape"].tolist(), "dtype": np.dtype(v["dtype"]).name}
                    for k, v in runner.get_output_details().items()},
    }
    return {k: np.stack(v) for k, v in outputs.items()}, io


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--crops", type=Path, required=True)
    p.add_argument("--run", type=Path, required=True)
    p.add_argument("--label-map", type=Path, default=lm.DEFAULT_LABEL_MAP)
    p.add_argument("--model-id", default="garment-tier1")
    p.add_argument("--version", default="1.0.0")
    p.add_argument("--calibration-samples", type=int, default=300)
    p.add_argument("--check-samples", type=int, default=1000)
    p.add_argument("--quantizer", choices=["legacy", "litert"], default="legacy")
    args = p.parse_args(argv)

    labels = lm.load(args.label_map)
    temps = json.loads((args.run / "calibration.json").read_text(encoding="utf-8"))
    model = keras.models.load_model(args.run / "model.keras", compile=False)
    inference = with_softmax(model, temps)

    saved = args.run / "saved_model"
    inference.export(str(saved))  # TensorFlow SavedModel with serving_default
    float_path = args.run / f"{args.model_id}-float32.tflite"
    float_path.write_bytes(tf.lite.TFLiteConverter.from_saved_model(str(saved)).convert())

    quantizer_used = "legacy"
    if args.quantizer == "litert":
        try:
            int8 = quantize_litert(float_path, args.crops, labels, args.calibration_samples)
            quantizer_used = "litert"
        except Exception as e:  # noqa: BLE001 - any API mismatch → documented fallback
            print(f"LiteRT Quantizer failed ({type(e).__name__}: {e}); using TFLiteConverter.")
            int8 = quantize_legacy(saved, args.crops, labels, args.calibration_samples)
    else:
        int8 = quantize_legacy(saved, args.crops, labels, args.calibration_samples)
    int8_path = args.run / f"{args.model_id}-int8.tflite"
    int8_path.write_bytes(int8)

    # Check on test crops: Keras vs float .tflite vs int8 .tflite.
    _, tt, tp = read_rows(args.crops, "test", labels)
    n = min(args.check_samples, len(tt))
    images = np.stack([x[0].numpy() for x, _ in
                       dataset(args.crops, "test", labels, 1, training=False).take(n)])
    keras_out = {k: np.asarray(v) for k, v in inference.predict(images, verbose=0).items()}
    float_out, io = run_tflite(float_path, images)
    int8_out, int8_io = run_tflite(int8_path, images)

    def top1(out, y, mask=None):
        pred = out.argmax(1)
        m = np.ones(len(y), bool) if mask is None else mask
        return round(float((pred[m] == y[m]).mean()), 4) if m.any() else None

    has_p = tp[:n] != NO_PATTERN
    check = {
        "samples": n,
        "typeTop1": {"keras": top1(keras_out["type"], tt[:n]),
                     "float32": top1(float_out["type"], tt[:n]),
                     "int8": top1(int8_out["type"], tt[:n])},
        "patternTop1": {"keras": top1(keras_out["pattern"], tp[:n], has_p),
                        "int8": top1(int8_out["pattern"], tp[:n], has_p)},
        "int8AgreesWithKeras": round(float(
            (int8_out["type"].argmax(1) == keras_out["type"].argmax(1)).mean()), 4),
        "maxProbDiffFloat": round(float(np.abs(float_out["type"] - keras_out["type"]).max()), 6),
    }
    sha = hashlib.sha256(int8).hexdigest()
    labels_file = labels.labels_json()
    card = {
        "modelId": args.model_id,
        "version": args.version,
        "quantizer": quantizer_used,
        "file": int8_path.name,
        "sizeBytes": len(int8),
        "sha256": sha,
        "floatSizeBytes": float_path.stat().st_size,
        "io": int8_io,
        "floatIo": io,
        "temperatures": temps,
        "check": check,
        "labels": labels_file,
        "license": "Model weights: project licence. Trained on Fashionpedia annotations "
                   "(CC BY 4.0, attribution required). Backbone: Keras ImageNet weights.",
        "manifestEntry": {
            "id": args.model_id,
            "version": args.version,
            "task": "garment-type-pattern",
            "title": "Clothing type and pattern",
            "asset": f"assets/models/{args.model_id}.tflite",
            "sha256": sha,
            "license": "CC-BY-4.0 (Fashionpedia annotations)",
        },
    }
    (args.run / "labels.json").write_text(json.dumps(labels_file, indent=2), encoding="utf-8")
    (args.run / "model_card.json").write_text(json.dumps(card, indent=2), encoding="utf-8")
    print(json.dumps({k: card[k] for k in ("file", "sizeBytes", "sha256", "check")}, indent=2))
    if check["int8AgreesWithKeras"] < AGREEMENT_FLOOR:
        print(f"WARNING: int8 agrees with Keras on only {check['int8AgreesWithKeras']:.1%} "
              f"of test crops (< {AGREEMENT_FLOOR:.0%}). Do not ship this file.")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
