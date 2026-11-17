"""Segmentation metrics in plain numpy (unit-tested without TensorFlow)."""

from __future__ import annotations

import numpy as np

from .seg_prepare import IGNORE

# The app offers a garment as an item when it covers at least this share of
# the photo (keep in sync with GarmentSegmenter.minAreaShare in the app).
MIN_AREA_SHARE = 0.01


class Accumulator:
    """Confusion matrix plus per-photo item counts."""

    def __init__(self, num_classes: int):
        self.num_classes = num_classes
        self.cm = np.zeros((num_classes, num_classes), np.int64)
        self.expected = self.found = self.extra = 0

    def add(self, pred: np.ndarray, true: np.ndarray) -> None:
        """One photo: predicted and true class maps of the same shape."""
        n = self.num_classes
        valid = true != IGNORE
        t, p = true[valid].astype(np.int64), pred[valid].astype(np.int64)
        self.cm += np.bincount(t * n + p, minlength=n * n).reshape(n, n)
        min_px = MIN_AREA_SHARE * true.size
        true_items = {c for c in range(1, n) if (true == c).sum() >= min_px}
        pred_items = {c for c in range(1, n) if ((pred == c) & valid).sum() >= min_px}
        self.expected += len(true_items)
        self.found += len(true_items & pred_items)
        self.extra += len(pred_items - true_items)

    def summary(self, names: list[str]) -> dict:
        cm = self.cm
        inter = np.diag(cm).astype(np.float64)
        union = cm.sum(0) + cm.sum(1) - inter
        support = cm.sum(1)
        present = [i for i in range(1, len(names)) if support[i]]
        fg_inter = cm[1:, 1:].sum()
        fg_union = cm[1:, :].sum() + cm[:, 1:].sum() - fg_inter
        return {
            "foregroundIoU": round(float(fg_inter / max(fg_union, 1)), 4),
            "meanIoU": (round(float(np.mean([inter[i] / union[i] for i in present])), 4)
                        if present else None),
            "pixelAccuracy": round(float(inter.sum() / max(cm.sum(), 1)), 4),
            "itemRecall": round(self.found / max(self.expected, 1), 4),
            "items": {"expected": self.expected, "found": self.found, "extra": self.extra},
            "iou": {n: (round(float(inter[i] / union[i]), 4) if support[i] else None)
                    for i, n in enumerate(names)},
            "support": {n: int(support[i]) for i, n in enumerate(names)},
        }
