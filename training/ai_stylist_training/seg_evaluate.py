"""Measures the segmentation model on the test set.

Usage:
  python -m ai_stylist_training.seg_evaluate --data data/seg --run out/seg1

Reports, separately for real photos (worn clothes) and synthetic flat-lays:
- garment-vs-background IoU: how clean a cutout is;
- per-class IoU and mean IoU over the classes present: whether each garment
  on a person is separated from the others;
- item recall: the share of garments (per photo and class) that the app
  would offer as an item, using the same rule as the app (enough pixels).
Writes seg_eval_report.json.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import keras
import numpy as np

from . import label_map as lm
from .seg_data import dataset
from .seg_metrics import MIN_AREA_SHARE, Accumulator

def evaluate(model: keras.Model, ds, names: list[str]) -> dict:
    acc = Accumulator(len(names))
    for images, masks in ds:
        pred = np.argmax(model.predict(images, verbose=0), axis=-1)
        for p, t in zip(pred, masks.numpy()[..., 0]):
            acc.add(p, t)
    return acc.summary(names)


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--data", type=Path, required=True)
    p.add_argument("--run", type=Path, required=True)
    p.add_argument("--label-map", type=Path, default=lm.DEFAULT_LABEL_MAP)
    p.add_argument("--batch", type=int, default=32)
    args = p.parse_args(argv)

    labels = lm.load(args.label_map)
    names = ["background"] + labels.type_labels
    model = keras.models.load_model(args.run / "model.keras", compile=False)
    report = {"classes": names, "minAreaShare": MIN_AREA_SHARE}
    for key, synth in (("real", False), ("synthetic", True)):
        ds = dataset(args.data, "test", args.batch, training=False, only_synthetic=synth)
        report[key] = evaluate(model, ds, names)
    (args.run / "seg_eval_report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps({k: {m: report[k][m] for m in ("foregroundIoU", "meanIoU", "itemRecall")}
                      for k in ("real", "synthetic")}, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
