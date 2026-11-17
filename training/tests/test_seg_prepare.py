"""Tests for segmentation data preparation (no TensorFlow needed).

Run from training/:  python -m unittest discover -s tests -v
"""

from __future__ import annotations

import csv
import json
import sys
import tempfile
import unittest
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from ai_stylist_training import label_map as lm  # noqa: E402
from ai_stylist_training import seg_prepare as seg  # noqa: E402

LABELS = lm.load()
NAMES = [c.fashionpedia for c in LABELS.classes] + sorted(LABELS.excluded) + ["sleeve"]
CATEGORIES = [{"id": i, "name": n, "supercategory": "x"} for i, n in enumerate(NAMES)]


def cat_id(name: str) -> int:
    return NAMES.index(name)


def cls(name: str) -> int:
    """Mask value for a Fashionpedia name (class index + 1)."""
    return [c.fashionpedia for c in LABELS.classes].index(name) + 1


def rect(x: int, y: int, w: int, h: int) -> list[list[float]]:
    return [[x, y, x + w, y, x + w, y + h, x, y + h]]


def rle(mask: np.ndarray) -> dict:
    """Uncompressed COCO RLE (column-major), as Fashionpedia may store it."""
    flat = mask.flatten(order="F").astype(int)
    counts, value, run = [], 0, 0
    for v in flat:
        if v == value:
            run += 1
        else:
            counts.append(run)
            value, run = v, 1
    counts.append(run)
    return {"size": list(mask.shape), "counts": counts}


def write_dataset(root: Path, images: int = 12) -> Path:
    img_dir = root / "images"
    img_dir.mkdir()
    data = {"categories": CATEGORIES, "attributes": [], "images": [], "annotations": [],
            "licenses": [{"id": 1, "name": "Flickr"}]}
    ann_id = 1
    belt = np.zeros((300, 400), bool)
    belt[140:150, 60:180] = True
    for i in range(images):
        Image.new("RGB", (400, 300), (30, 90 + i, 160)).save(img_dir / f"{i}.jpg")
        data["images"].append({"id": i, "width": 400, "height": 300, "file_name": f"{i}.jpg", "license": 1})
        for cat, segm, area, crowd in [
            ("dress", rect(50, 20, 150, 250), 37500, 0),   # big garment, painted first
            ("belt", rle(belt), 1200, 0),                   # RLE, on top of the dress
            ("sleeve", rect(60, 30, 40, 40), 1600, 0),      # part: ignored
            ("sock", rect(300, 200, 40, 60), 2400, 0),      # excluded: ignore
            ("shoe", rect(250, 250, 50, 30), 1500, 1),      # crowd: ignore
        ]:
            data["annotations"].append({"id": ann_id, "image_id": i, "category_id": cat_id(cat),
                                        "segmentation": segm, "area": area, "iscrowd": crowd,
                                        "bbox": [0, 0, 1, 1], "attribute_ids": []})
            ann_id += 1
    path = root / "ann.json"
    path.write_text(json.dumps(data), encoding="utf-8")
    return path


class DecodeTest(unittest.TestCase):
    def test_polygon_and_rle_agree(self):
        poly, fmt = seg.decode(rect(10, 5, 20, 8), 30, 40)
        self.assertEqual(fmt, "polygon")
        self.assertEqual(poly[5:13, 10:30].mean(), 1.0)
        back, fmt = seg.decode(rle(poly), 30, 40)
        self.assertEqual(fmt, "rle")
        np.testing.assert_array_equal(back, poly)

    def test_unknown_format_raises(self):
        with self.assertRaises(ValueError):
            seg.decode("nope", 4, 4)


class PrepareTest(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.root = Path(self._tmp.name)

    def tearDown(self):
        self._tmp.cleanup()

    def run_prep(self, synth: float = 0.0, split: str = "train") -> dict:
        ann = write_dataset(self.root)
        return seg.run(ann, self.root / "images", self.root / "out", split, 0.3, LABELS,
                       synth_p=synth, workers=1)

    def rows(self, split: str) -> list[dict]:
        text = (self.root / "out" / f"{split}.csv").read_text(encoding="utf-8")
        return list(csv.DictReader(text.splitlines()))

    def test_masks_paint_order_parts_and_ignore(self):
        report = self.run_prep()
        self.assertEqual(report["maskFormats"], {"polygon": 36, "rle": 12})
        row = self.rows("train")[0]
        with Image.open(self.root / "out" / row["mask"]) as m:
            mask = np.asarray(m)
        with Image.open(self.root / "out" / row["image"]) as im:
            self.assertEqual(im.size, (seg.SIZE, seg.SIZE))
        self.assertEqual(mask.shape, (seg.SIZE, seg.SIZE))
        sy, sx = seg.SIZE / 300, seg.SIZE / 400
        at = lambda y, x: mask[int(y * sy), int(x * sx)]  # noqa: E731
        self.assertEqual(at(100, 120), cls("dress"))
        self.assertEqual(at(145, 120), cls("belt"), "smaller garment on top")
        self.assertEqual(at(50, 80), cls("dress"), "sleeve part is not painted")
        self.assertEqual(at(230, 320), seg.IGNORE, "excluded class")
        self.assertEqual(at(265, 275), seg.IGNORE, "crowd region")
        self.assertEqual(at(10, 380), seg.BACKGROUND)

    def test_holdout_by_photo_and_synthetic_follows_its_photo(self):
        report = self.run_prep(synth=1.0)
        train, val = self.rows("train"), self.rows("val")
        self.assertTrue(val, "holdout produced no val rows")
        self.assertFalse({r["image_id"] for r in train} & {r["image_id"] for r in val})
        self.assertEqual(sum(report["synthetic"].values()), 12)
        synth = [r for r in train + val if r["synthetic"] == "1"]
        with Image.open(self.root / "out" / synth[0]["mask"]) as m:
            mask = np.asarray(m)
        values = set(np.unique(mask).tolist())
        self.assertEqual(values, {seg.BACKGROUND, cls("dress")}, "one garment on a backdrop")
        self.assertTrue((mask[0] == seg.BACKGROUND).all(), "backdrop margin around the garment")

    def test_deterministic(self):
        a = self.run_prep(synth=0.5)
        rows_a = self.rows("train") + self.rows("val")
        b = self.run_prep_again()
        self.assertEqual(a["samples"], b["samples"])
        self.assertEqual(rows_a, self.rows("train") + self.rows("val"))

    def run_prep_again(self) -> dict:
        return seg.run(self.root / "ann.json", self.root / "images", self.root / "out", "train",
                       0.3, LABELS, synth_p=0.5, workers=1)

    def test_worker_pool_gives_the_same_result(self):
        single = self.run_prep(synth=0.5)
        rows = self.rows("train") + self.rows("val")
        pooled = seg.run(self.root / "ann.json", self.root / "images", self.root / "out",
                         "train", 0.3, LABELS, synth_p=0.5, workers=2)
        self.assertEqual(single["samples"], pooled["samples"])
        self.assertEqual(rows, self.rows("train") + self.rows("val"))

    def test_pixel_counts_feed_class_weights(self):
        report = self.run_prep(split="test")
        pixels = report["pixels"]["test"]
        self.assertGreater(pixels["dress"], pixels["belt"])
        self.assertGreater(pixels["ignore"], 0)
        self.assertEqual(report["classes"][0], "background")


if __name__ == "__main__":
    unittest.main()
