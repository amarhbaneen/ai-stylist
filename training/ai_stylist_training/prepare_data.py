"""Turns Fashionpedia (COCO-style) annotations into one-garment crops.

Usage:
  python -m ai_stylist_training.prepare_data \
      --annotations data/instances_attributes_train2020.json \
      --images data/train --out data/crops --split train --holdout 0.1
  python -m ai_stylist_training.prepare_data \
      --annotations data/instances_attributes_val2020.json \
      --images data/test --out data/crops --split test

Writes <out>/<split>/<ann_id>.jpg, <out>/<split>.csv and <out>/<split>_report.json.
With --holdout, a fraction of *images* (not crops) goes to a "val" split, so
crops from one photo never appear in both train and val.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import sys
from collections import Counter
from pathlib import Path

from PIL import Image, ImageOps

from . import label_map as lm

CROP_PADDING = 0.08  # fraction of the box added on each side
MIN_SIDE = 48  # pixels; smaller boxes are too small to classify
OUT_SHORT_SIDE = 256  # crops are stored at this short side (training uses 224)


def _split_for(image_id: int, holdout: float) -> str:
    """Deterministic train/val assignment by image (stable across runs)."""
    digest = hashlib.sha256(str(image_id).encode()).digest()
    return "val" if int.from_bytes(digest[:4], "big") / 2**32 < holdout else "train"


def resolve_classes(data: dict, labels: lm.LabelMap) -> tuple[dict[int, int], dict[str, int]]:
    """Fashionpedia category id -> class index, and all category ids by name.
    Fails, listing the available names, if a configured name is missing."""
    categories = {c["name"]: c["id"] for c in data["categories"]}
    missing = [c.fashionpedia for c in labels.classes if c.fashionpedia not in categories]
    missing += [n for n in labels.excluded if n not in categories]
    if missing:
        raise lm.LabelMapError(
            "label_map.json names not found in the annotation file: "
            + ", ".join(sorted(missing))
            + "\nAvailable: " + ", ".join(sorted(categories))
        )
    return {categories[c.fashionpedia]: i for i, c in enumerate(labels.classes)}, categories


def resolve(data: dict, labels: lm.LabelMap) -> tuple[dict[int, int], dict[int, str], dict]:
    """Maps Fashionpedia category ids to class indices and attribute ids to
    pattern codes. Fails if a configured name is missing from the file."""
    class_of, categories = resolve_classes(data, labels)

    pattern_attrs = [
        a for a in data.get("attributes", [])
        if a.get("supercategory", "").lower() == labels.pattern_supercategory.lower()
    ]
    if not pattern_attrs:
        supers = sorted({a.get("supercategory", "") for a in data.get("attributes", [])})
        raise lm.LabelMapError(
            f"no attributes with supercategory '{labels.pattern_supercategory}'. "
            f"Available: {supers}"
        )
    pattern_of = {a["id"]: labels.pattern_code_for(a["name"]) for a in pattern_attrs}
    resolved = {
        "classes": {c.label: categories[c.fashionpedia] for c in labels.classes},
        "patternAttributes": {a["name"]: pattern_of[a["id"]] for a in pattern_attrs},
    }
    return class_of, pattern_of, resolved


def pattern_label(attribute_ids: list[int], pattern_of: dict[int, str]) -> str:
    """One pattern code for a garment, or '' when it has no pattern attribute.
    A specific pattern wins over OTHER; SOLID only if nothing else is set."""
    codes = [pattern_of[a] for a in attribute_ids if a in pattern_of]
    if not codes:
        return ""
    for code in codes:
        if code not in ("OTHER", "SOLID"):
            return code
    return "OTHER" if "OTHER" in codes else "SOLID"


def crop_box(bbox: list[float], width: int, height: int) -> tuple[int, int, int, int] | None:
    x, y, w, h = bbox
    if min(w, h) < MIN_SIDE:
        return None
    pad_w, pad_h = w * CROP_PADDING, h * CROP_PADDING
    left = max(0, int(x - pad_w))
    top = max(0, int(y - pad_h))
    right = min(width, int(x + w + pad_w))
    bottom = min(height, int(y + h + pad_h))
    if right - left < MIN_SIDE or bottom - top < MIN_SIDE:
        return None
    return left, top, right, bottom


def run(annotations: Path, images: Path, out: Path, split: str, holdout: float,
        labels: lm.LabelMap, limit: int | None = None) -> dict:
    data = json.loads(annotations.read_text(encoding="utf-8"))
    class_of, pattern_of, resolved = resolve(data, labels)
    image_info = {i["id"]: i for i in data["images"]}
    licences = {l["id"]: l.get("name", str(l["id"])) for l in data.get("licenses", [])}

    by_image: dict[int, list[dict]] = {}
    for ann in data["annotations"]:
        if ann.get("iscrowd", 0) == 0 and ann["category_id"] in class_of:
            by_image.setdefault(ann["image_id"], []).append(ann)

    splits = ["train", "val"] if holdout > 0 else [split]
    writers, files = {}, {}
    for s in splits:
        (out / s).mkdir(parents=True, exist_ok=True)
        files[s] = (out / f"{s}.csv").open("w", newline="", encoding="utf-8")
        writers[s] = csv.writer(files[s])
        writers[s].writerow(["path", "type", "pattern", "image_id"])

    counts = {s: Counter() for s in splits}
    pattern_counts = {s: Counter() for s in splits}
    licence_counts: Counter = Counter()
    skipped = Counter()
    try:
        for n, (image_id, anns) in enumerate(sorted(by_image.items())):
            if limit is not None and n >= limit:
                break
            info = image_info[image_id]
            target = _split_for(image_id, holdout) if holdout > 0 else split
            path = images / info["file_name"]
            try:
                with Image.open(path) as im:
                    im = ImageOps.exif_transpose(im).convert("RGB")
                    for ann in anns:
                        box = crop_box(ann["bbox"], im.width, im.height)
                        if box is None:
                            skipped["too_small"] += 1
                            continue
                        crop = im.crop(box)
                        scale = OUT_SHORT_SIDE / min(crop.size)
                        if scale < 1:
                            crop = crop.resize(
                                (round(crop.width * scale), round(crop.height * scale)),
                                Image.Resampling.BILINEAR,
                            )
                        rel = f"{target}/{ann['id']}.jpg"
                        crop.save(out / rel, quality=90)
                        type_label = labels.classes[class_of[ann["category_id"]]].label
                        pattern = pattern_label(ann.get("attribute_ids", []), pattern_of)
                        writers[target].writerow([rel, type_label, pattern, image_id])
                        counts[target][type_label] += 1
                        pattern_counts[target][pattern or "(none)"] += 1
                licence_counts[licences.get(info.get("license"), str(info.get("license")))] += 1
            except (OSError, KeyError) as e:
                skipped[f"unreadable: {type(e).__name__}"] += 1
    finally:
        for f in files.values():
            f.close()

    report = {
        "annotations": str(annotations),
        "resolved": resolved,
        "crops": {s: dict(counts[s].most_common()) for s in splits},
        "patterns": {s: dict(pattern_counts[s].most_common()) for s in splits},
        "imageLicences": dict(licence_counts.most_common()),
        "skipped": dict(skipped),
    }
    for s in splits:
        (out / f"{s}_report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    return report


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--annotations", type=Path, required=True)
    p.add_argument("--images", type=Path, required=True)
    p.add_argument("--out", type=Path, required=True)
    p.add_argument("--split", default="train", choices=["train", "test"])
    p.add_argument("--holdout", type=float, default=0.0, help="fraction of images for val")
    p.add_argument("--label-map", type=Path, default=lm.DEFAULT_LABEL_MAP)
    p.add_argument("--limit", type=int, default=None, help="only the first N images (debug)")
    args = p.parse_args(argv)
    if not 0 <= args.holdout < 1:
        p.error("--holdout must be in [0, 1)")
    try:
        report = run(args.annotations, args.images, args.out, args.split, args.holdout,
                     lm.load(args.label_map), args.limit)
    except lm.LabelMapError as e:
        print(f"Label map error: {e}", file=sys.stderr)
        return 2
    print(json.dumps({k: report[k] for k in ("crops", "skipped")}, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
