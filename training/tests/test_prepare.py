"""Tests for the label map and data preparation (no TensorFlow needed).

Run from training/:  python -m unittest discover -s tests -v
"""

from __future__ import annotations

import csv
import json
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from ai_stylist_training import label_map as lm  # noqa: E402
from ai_stylist_training import prepare_data as prep  # noqa: E402

LABELS = lm.load()

# Every Fashionpedia name the label map refers to, plus parts that must be ignored.
NAMES = [c.fashionpedia for c in LABELS.classes] + sorted(LABELS.excluded) + ["sleeve", "pocket"]
CATEGORIES = [{"id": i, "name": n, "supercategory": "x"} for i, n in enumerate(NAMES)]
ATTRIBUTES = [
    {"id": 100, "name": "plain (pattern)", "supercategory": "textile pattern"},
    {"id": 101, "name": "stripe", "supercategory": "textile pattern"},
    {"id": 102, "name": "floral", "supercategory": "textile pattern"},
    {"id": 103, "name": "paisley", "supercategory": "textile pattern"},
    {"id": 104, "name": "leopard", "supercategory": "textile pattern"},
    {"id": 200, "name": "symmetrical", "supercategory": "silhouette"},
]


def cat_id(name: str) -> int:
    return NAMES.index(name)


def write_dataset(root: Path, images: int = 20) -> Path:
    img_dir = root / "images"
    img_dir.mkdir()
    data = {"categories": CATEGORIES, "attributes": ATTRIBUTES, "images": [],
            "annotations": [], "licenses": [{"id": 1, "name": "Flickr"}]}
    ann_id = 1
    for i in range(images):
        name = f"{i}.jpg"
        Image.new("RGB", (400, 300), (i * 10 % 255, 80, 120)).save(img_dir / name)
        data["images"].append({"id": i, "width": 400, "height": 300, "file_name": name, "license": 1})
        for cat, bbox, attrs in [
            ("dress", [50, 20, 150, 250], [101, 200]),          # striped dress
            ("shoe", [300, 250, 40, 30], [100]),                # too small (30 px)
            ("sleeve", [60, 40, 80, 80], []),                   # part: ignored
            ("sock", [250, 100, 80, 120], []),                  # excluded class
            ("shirt, blouse", [200, 10, 150, 150], [100, 103]), # plain + paisley
        ]:
            data["annotations"].append({"id": ann_id, "image_id": i, "category_id": cat_id(cat),
                                        "bbox": bbox, "attribute_ids": attrs, "iscrowd": 0})
            ann_id += 1
    path = root / "ann.json"
    path.write_text(json.dumps(data), encoding="utf-8")
    return path


class LabelMapTest(unittest.TestCase):
    def test_codes_are_valid_app_taxonomy(self):
        for c in LABELS.classes:
            self.assertIn(c.category, lm.APP_CATEGORIES)
            if c.subcategory:
                self.assertIn(c.subcategory, lm.APP_SUBCATEGORIES)
        self.assertEqual(set(LABELS.pattern_classes), lm.APP_PATTERNS)

    def test_pattern_rules(self):
        self.assertEqual(LABELS.pattern_code_for("plain (pattern)"), "SOLID")
        self.assertEqual(LABELS.pattern_code_for("Tartan"), "CHECKED")
        self.assertEqual(LABELS.pattern_code_for("polka dot"), "DOTTED")
        self.assertEqual(LABELS.pattern_code_for("paisley"), "OTHER")

    def test_labels_file_matches_output_order(self):
        j = LABELS.labels_json()
        self.assertEqual([t["label"] for t in j["outputs"]["type"]], LABELS.type_labels)
        self.assertEqual(j["outputs"]["pattern"], list(LABELS.pattern_classes))


class PatternLabelTest(unittest.TestCase):
    pattern_of = {100: "SOLID", 101: "STRIPED", 103: "OTHER"}

    def test_specific_beats_other_and_solid(self):
        self.assertEqual(prep.pattern_label([100, 101], self.pattern_of), "STRIPED")
        self.assertEqual(prep.pattern_label([100, 103], self.pattern_of), "OTHER")
        self.assertEqual(prep.pattern_label([100], self.pattern_of), "SOLID")
        self.assertEqual(prep.pattern_label([200], self.pattern_of), "")


class PrepareTest(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.root = Path(self._tmp.name)

    def tearDown(self):
        self._tmp.cleanup()

    def test_crops_labels_and_holdout_by_image(self):
        ann = write_dataset(self.root)
        out = self.root / "crops"
        report = prep.run(ann, self.root / "images", out, "train", 0.3, LABELS)

        rows = {s: list(csv.DictReader((out / f"{s}.csv").read_text(encoding="utf-8").splitlines()))
                for s in ("train", "val")}
        all_rows = rows["train"] + rows["val"]
        self.assertEqual(len(all_rows), 40)  # dress + shirt per image
        self.assertTrue(rows["val"], "holdout produced no val rows")
        train_ids = {r["image_id"] for r in rows["train"]}
        self.assertFalse(train_ids & {r["image_id"] for r in rows["val"]})
        types = {r["type"] for r in all_rows}
        self.assertEqual(types, {"dress", "shirt_blouse"})
        self.assertEqual({r["pattern"] for r in all_rows if r["type"] == "dress"}, {"STRIPED"})
        self.assertEqual({r["pattern"] for r in all_rows if r["type"] == "shirt_blouse"}, {"OTHER"})
        self.assertEqual(report["skipped"], {"too_small": 20})
        self.assertEqual(report["imageLicences"], {"Flickr": 20})
        self.assertEqual(report["resolved"]["patternAttributes"]["leopard"], "ANIMAL")
        with Image.open(out / all_rows[0]["path"]) as im:
            self.assertLessEqual(min(im.size), prep.OUT_SHORT_SIDE)

    def test_holdout_is_deterministic(self):
        ann = write_dataset(self.root)
        a = prep.run(ann, self.root / "images", self.root / "a", "train", 0.3, LABELS)
        b = prep.run(ann, self.root / "images", self.root / "b", "train", 0.3, LABELS)
        self.assertEqual(a["crops"], b["crops"])

    def test_missing_name_fails_loudly(self):
        ann = write_dataset(self.root, images=1)
        data = json.loads(ann.read_text(encoding="utf-8"))
        data["categories"] = [c for c in data["categories"] if c["name"] != "dress"]
        ann.write_text(json.dumps(data), encoding="utf-8")
        with self.assertRaises(lm.LabelMapError) as ctx:
            prep.run(ann, self.root / "images", self.root / "c", "test", 0, LABELS)
        self.assertIn("dress", str(ctx.exception))

    def test_unreadable_image_is_skipped_not_fatal(self):
        ann = write_dataset(self.root, images=2)
        (self.root / "images" / "1.jpg").write_bytes(b"not a jpeg")
        report = prep.run(ann, self.root / "images", self.root / "d", "test", 0, LABELS)
        self.assertEqual(sum(report["crops"]["test"].values()), 2)
        self.assertIn("unreadable: UnidentifiedImageError", report["skipped"])

    def test_crop_box_padding_and_bounds(self):
        self.assertIsNone(prep.crop_box([0, 0, 40, 200], 400, 300))
        left, top, right, bottom = prep.crop_box([0, 0, 100, 100], 400, 300)
        self.assertEqual((left, top), (0, 0))
        self.assertEqual((right, bottom), (108, 108))


if __name__ == "__main__":
    unittest.main()
