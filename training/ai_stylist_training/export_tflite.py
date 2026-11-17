"""Exports the calibrated model to LiteRT (.tflite) and picks a shippable variant.

Usage:
  python -m ai_stylist_training.export_tflite --crops data/crops --run out/run1 \
      --model-id garment-tier1 --version 1.0.0

Steps:
1. Wraps the model with calibrated softmax heads (calibration.json).
2. Converts to a float32 .tflite (from a SavedModel, the documented path).
3. Builds smaller variants, best first, all with float32 input/output so the
   app feeds plain 0-255 RGB:
     int8     int8 weights and activations (representative dataset; or the
              LiteRT Quantizer with `--quantizer litert`, falling back)
     dynamic  int8 weights, float activations (no calibration data)
     float16  float16 weights
4. Checks each variant on test crops with the default CPU runtime, XNNPACK
   included, because the phone uses it too. A variant is accepted only if
   XNNPACK can prepare it and its top-1 type agrees with Keras on >= 97% of
   crops. The first accepted variant is written to <model-id>.tflite.
5. Writes model_card.json: chosen variant, every variant's result, size,
   SHA-256, accuracy, I/O tensors, and the manifest entry.
Exit code 1 means no variant passed; nothing should be shipped.
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

AGREEMENT_FLOOR = 0.97  # variant top-1 must match Keras on >= 97% of test crops
NO_DELEGATES = tf.lite.experimental.OpResolverType.BUILTIN_WITHOUT_DEFAULT_DELEGATES


def representative(crops: Path, labels: lm.LabelMap, n: int):
    ds = dataset(crops, "val", labels, 1, training=False).take(n)

    def gen():
        for image, _ in ds:
            yield [image]

    return gen


def convert_int8_legacy(saved: Path, crops: Path, labels: lm.LabelMap, n: int) -> bytes:
    converter = tf.lite.TFLiteConverter.from_saved_model(str(saved))
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.representative_dataset = representative(crops, labels, n)
    converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
    # inference_input_type / inference_output_type stay float32 (the default).
    return converter.convert()


def convert_int8_litert(float_path: Path, crops: Path, labels: lm.LabelMap, n: int) -> bytes:
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


def convert_dynamic(saved: Path) -> bytes:
    converter = tf.lite.TFLiteConverter.from_saved_model(str(saved))
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    return converter.convert()


def convert_float16(saved: Path) -> bytes:
    converter = tf.lite.TFLiteConverter.from_saved_model(str(saved))
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float16]
    return converter.convert()


def _op_at(model_path: Path, message: str) -> str | None:
    """Names the op behind 'Node number N' in a delegate error, for the report."""
    import re

    m = re.search(r"Node number (\d+)", message)
    if not m:
        return None
    try:
        interp = tf.lite.Interpreter(model_path=str(model_path),
                                     experimental_op_resolver_type=NO_DELEGATES)
        for op in interp._get_ops_details():  # noqa: SLF001 - diagnostics only
            if op["index"] == int(m.group(1)):
                return op["op_name"]
    except Exception:  # noqa: BLE001 - diagnostics must not hide the real error
        return None
    return None


def run_tflite(model_path: Path, images: np.ndarray, xnnpack: bool = True
               ) -> tuple[dict[str, np.ndarray], dict]:
    kwargs = {} if xnnpack else {"experimental_op_resolver_type": NO_DELEGATES}
    interpreter = tf.lite.Interpreter(model_path=str(model_path), **kwargs)
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


def top1(out: np.ndarray, y: np.ndarray, mask: np.ndarray | None = None) -> float | None:
    m = np.ones(len(y), bool) if mask is None else mask
    return round(float((out.argmax(1)[m] == y[m]).mean()), 4) if m.any() else None


def check_variant(path: Path, images: np.ndarray, keras_out: dict, tt: np.ndarray,
                  tp: np.ndarray) -> tuple[dict, dict | None]:
    """Runs a variant with XNNPACK; returns (result, io) — io is None on failure."""
    result: dict = {"file": path.name, "sizeBytes": path.stat().st_size}
    try:
        out, io = run_tflite(path, images)
    except RuntimeError as e:
        result.update(xnnpack=False, error=str(e).strip(), failingOp=_op_at(path, str(e)))
        return result, None
    has_p = tp != NO_PATTERN
    result.update(
        xnnpack=True,
        typeTop1=top1(out["type"], tt),
        patternTop1=top1(out["pattern"], tp, has_p),
        agreesWithKeras=round(float(
            (out["type"].argmax(1) == keras_out["type"].argmax(1)).mean()), 4),
        maxTypeProbDiff=round(float(np.abs(out["type"] - keras_out["type"]).max()), 6),
    )
    return result, io


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

    def int8() -> tuple[bytes, str]:
        if args.quantizer == "litert":
            try:
                return convert_int8_litert(float_path, args.crops, labels,
                                           args.calibration_samples), "litert"
            except Exception as e:  # noqa: BLE001 - any API mismatch → documented fallback
                print(f"LiteRT Quantizer failed ({type(e).__name__}: {e}); using TFLiteConverter.")
        return convert_int8_legacy(saved, args.crops, labels, args.calibration_samples), "legacy"

    variants = [
        ("int8", int8),
        ("dynamic", lambda: (convert_dynamic(saved), "legacy")),
        ("float16", lambda: (convert_float16(saved), "legacy")),
    ]

    # Test crops, and the Keras reference outputs.
    _, tt, tp = read_rows(args.crops, "test", labels)
    n = min(args.check_samples, len(tt))
    tt, tp = tt[:n], tp[:n]
    images = np.stack([x[0].numpy() for x, _ in
                       dataset(args.crops, "test", labels, 1, training=False).take(n)])
    keras_out = {k: np.asarray(v) for k, v in inference.predict(images, verbose=0).items()}
    has_p = tp != NO_PATTERN
    reference = {"samples": n, "typeTop1": top1(keras_out["type"], tt),
                 "patternTop1": top1(keras_out["pattern"], tp, has_p)}

    results: list[dict] = []
    chosen: tuple[str, str, Path, dict] | None = None
    for name, convert in variants:
        try:
            content, quantizer_used = convert()
        except Exception as e:  # noqa: BLE001 - record and try the next variant
            results.append({"variant": name, "converted": False, "error": f"{type(e).__name__}: {e}"})
            continue
        path = args.run / f"{args.model_id}-{name}.tflite"
        path.write_bytes(content)
        result, io = check_variant(path, images, keras_out, tt, tp)
        result = {"variant": name, "quantizer": quantizer_used, **result}
        results.append(result)
        print(json.dumps(result, indent=2))
        if io is not None and result["agreesWithKeras"] >= AGREEMENT_FLOOR:
            chosen = (name, quantizer_used, path, io)
            break

    if chosen is None:
        (args.run / "model_card.json").write_text(json.dumps(
            {"modelId": args.model_id, "version": args.version, "shippable": False,
             "reference": reference, "variants": results}, indent=2), encoding="utf-8")
        print("ERROR: no variant passed the XNNPACK and agreement checks. Do not ship. "
              "Send model_card.json for review.")
        return 1

    name, quantizer_used, path, io = chosen
    final = args.run / f"{args.model_id}.tflite"
    content = path.read_bytes()
    final.write_bytes(content)
    sha = hashlib.sha256(content).hexdigest()
    labels_file = labels.labels_json()
    card = {
        "modelId": args.model_id,
        "version": args.version,
        "shippable": True,
        "variant": name,
        "quantizer": quantizer_used,
        "file": final.name,
        "sizeBytes": len(content),
        "sha256": sha,
        "floatSizeBytes": float_path.stat().st_size,
        "io": io,
        "temperatures": temps,
        "reference": reference,
        "variants": results,
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
    print(f"Chosen: {name} → {final.name} ({len(content):,} bytes, sha256 {sha})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
