"""Tests for segmentation metrics (numpy only)."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from ai_stylist_training.seg_metrics import Accumulator  # noqa: E402
from ai_stylist_training.seg_prepare import IGNORE  # noqa: E402

NAMES = ["background", "dress", "belt"]


class AccumulatorTest(unittest.TestCase):
    def test_perfect_prediction(self):
        true = np.zeros((20, 20), np.uint8)
        true[2:18, 2:12] = 1
        true[10:12, 2:12] = 2
        acc = Accumulator(3)
        acc.add(true.copy(), true)
        s = acc.summary(NAMES)
        self.assertEqual(s["foregroundIoU"], 1.0)
        self.assertEqual(s["meanIoU"], 1.0)
        self.assertEqual(s["itemRecall"], 1.0)
        self.assertEqual(s["items"], {"expected": 2, "found": 2, "extra": 0})

    def test_ignore_pixels_do_not_count_and_wrong_class_still_cuts_out(self):
        true = np.zeros((10, 10), np.uint8)
        true[0:5] = 1
        true[9] = IGNORE
        pred = np.zeros((10, 10), np.uint8)
        pred[0:5] = 2          # right shape, wrong garment type
        pred[9] = 1            # predictions on ignored pixels are not penalised
        acc = Accumulator(3)
        acc.add(pred, true)
        s = acc.summary(NAMES)
        self.assertEqual(s["foregroundIoU"], 1.0, "the cutout itself is perfect")
        self.assertEqual(s["iou"]["dress"], 0.0)
        self.assertEqual(s["items"], {"expected": 1, "found": 0, "extra": 1})
        self.assertIsNone(s["iou"]["belt"], "no true belt pixels")


if __name__ == "__main__":
    unittest.main()
