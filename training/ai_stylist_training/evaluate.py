"""Measures the trained model and fits confidence calibration.

Usage:
  python -m ai_stylist_training.evaluate --crops data/crops --run out/run1

Fits one temperature per head on the validation split (so the app's
0.80 / 0.50 thresholds mean what they say), then reports on the test split:
type and category accuracy, pattern accuracy, per-class recall, confusion
matrices, calibration error, and what the app would actually do at each
confidence level. Writes calibration.json and eval_report.json.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import keras
import numpy as np

from . import label_map as lm
from .data import NO_PATTERN, dataset, read_rows

PREFILL_AT, CONFIRM_AT = 0.80, 0.50  # DECISIONS D-09


def softmax(logits: np.ndarray, t: float = 1.0) -> np.ndarray:
    z = logits / t
    z = z - z.max(axis=1, keepdims=True)
    e = np.exp(z)
    return e / e.sum(axis=1, keepdims=True)


def nll(logits: np.ndarray, y: np.ndarray, t: float) -> float:
    p = softmax(logits, t)[np.arange(len(y)), y]
    return float(-np.log(np.maximum(p, 1e-12)).mean())


def fit_temperature(logits: np.ndarray, y: np.ndarray) -> float:
    """Grid search, then refine: robust and dependency-free."""
    grid = np.exp(np.linspace(np.log(0.3), np.log(5.0), 60))
    t = min(grid, key=lambda g: nll(logits, y, g))
    fine = np.linspace(t * 0.9, t * 1.1, 41)
    return float(min(fine, key=lambda g: nll(logits, y, g)))


def ece(probs: np.ndarray, y: np.ndarray, bins: int = 15) -> float:
    """Expected calibration error of the top prediction."""
    conf = probs.max(axis=1)
    correct = probs.argmax(axis=1) == y
    edges = np.linspace(0, 1, bins + 1)
    total = 0.0
    for lo, hi in zip(edges[:-1], edges[1:]):
        m = (conf > lo) & (conf <= hi)
        if m.any():
            total += m.mean() * abs(correct[m].mean() - conf[m].mean())
    return float(total)


def category_probs(type_probs: np.ndarray, labels: lm.LabelMap) -> tuple[np.ndarray, list[str]]:
    """Sums class probabilities per app category, as the app's validator does."""
    cats = sorted({c.category for c in labels.classes})
    out = np.zeros((len(type_probs), len(cats)), np.float64)
    for i, c in enumerate(labels.classes):
        out[:, cats.index(c.category)] += type_probs[:, i]
    return out, cats


def app_levels(probs: np.ndarray, y: np.ndarray) -> dict:
    """Share of items at each D-09 level, and accuracy within it."""
    conf, correct = probs.max(axis=1), probs.argmax(axis=1) == y
    out = {}
    for name, m in (
        ("prefill", conf >= PREFILL_AT),
        ("confirm", (conf >= CONFIRM_AT) & (conf < PREFILL_AT)),
        ("hint", conf < CONFIRM_AT),
    ):
        out[name] = {
            "share": round(float(m.mean()), 4),
            "accuracy": round(float(correct[m].mean()), 4) if m.any() else None,
        }
    return out


def confusion(y: np.ndarray, pred: np.ndarray, names: list[str]) -> dict:
    m = np.zeros((len(names), len(names)), int)
    np.add.at(m, (y, pred), 1)
    return {"labels": names, "matrix": m.tolist()}


def per_class_recall(y: np.ndarray, pred: np.ndarray, names: list[str]) -> dict:
    return {
        n: {"support": int((y == i).sum()),
            "recall": round(float((pred[y == i] == i).mean()), 4) if (y == i).any() else None}
        for i, n in enumerate(names)
    }


def predict_logits(model: keras.Model, crops: Path, split: str, labels: lm.LabelMap,
                   batch: int) -> dict[str, np.ndarray]:
    out = model.predict(dataset(crops, split, labels, batch, training=False), verbose=0)
    return {k: np.asarray(v, np.float64) for k, v in out.items()}


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--crops", type=Path, required=True)
    p.add_argument("--run", type=Path, required=True, help="folder with model.keras")
    p.add_argument("--label-map", type=Path, default=lm.DEFAULT_LABEL_MAP)
    p.add_argument("--batch", type=int, default=128)
    args = p.parse_args(argv)

    labels = lm.load(args.label_map)
    model = keras.models.load_model(args.run / "model.keras", compile=False)

    # Calibrate on val.
    _, vt, vp = read_rows(args.crops, "val", labels)
    val = predict_logits(model, args.crops, "val", labels, args.batch)
    has_p = vp != NO_PATTERN
    temps = {
        "type": fit_temperature(val["type"], vt),
        "pattern": fit_temperature(val["pattern"][has_p], vp[has_p]) if has_p.any() else 1.0,
    }
    (args.run / "calibration.json").write_text(json.dumps(temps, indent=2), encoding="utf-8")

    # Report on test.
    _, tt, tp = read_rows(args.crops, "test", labels)
    test = predict_logits(model, args.crops, "test", labels, args.batch)
    type_raw, type_cal = softmax(test["type"]), softmax(test["type"], temps["type"])
    cat_cal, cats = category_probs(type_cal, labels)
    y_cat = np.array([cats.index(labels.classes[i].category) for i in tt])
    top3 = np.argsort(-type_cal, axis=1)[:, :3]

    has_tp = tp != NO_PATTERN
    pat_cal = softmax(test["pattern"][has_tp], temps["pattern"])
    y_pat = tp[has_tp]

    report = {
        "temperatures": temps,
        "test": {
            "crops": int(len(tt)),
            "type": {
                "top1": round(float((type_cal.argmax(1) == tt).mean()), 4),
                "top3": round(float((top3 == tt[:, None]).any(axis=1).mean()), 4),
                "eceBefore": round(ece(type_raw, tt), 4),
                "eceAfter": round(ece(type_cal, tt), 4),
                "perClass": per_class_recall(tt, type_cal.argmax(1), labels.type_labels),
                "confusion": confusion(tt, type_cal.argmax(1), labels.type_labels),
            },
            "category": {
                "top1": round(float((cat_cal.argmax(1) == y_cat).mean()), 4),
                "appLevels": app_levels(cat_cal, y_cat),
                "perClass": per_class_recall(y_cat, cat_cal.argmax(1), cats),
                "confusion": confusion(y_cat, cat_cal.argmax(1), cats),
            },
            "pattern": {
                "labelled": int(has_tp.sum()),
                "top1": round(float((pat_cal.argmax(1) == y_pat).mean()), 4) if len(y_pat) else None,
                "appLevels": app_levels(pat_cal, y_pat) if len(y_pat) else None,
                "perClass": per_class_recall(y_pat, pat_cal.argmax(1), list(labels.pattern_classes)),
            },
        },
    }
    (args.run / "eval_report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    t = report["test"]
    print(json.dumps({
        "type_top1": t["type"]["top1"], "type_top3": t["type"]["top3"],
        "category_top1": t["category"]["top1"], "category_levels": t["category"]["appLevels"],
        "pattern_top1": t["pattern"]["top1"], "temperatures": temps,
    }, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
