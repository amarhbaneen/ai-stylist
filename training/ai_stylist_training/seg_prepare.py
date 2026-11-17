"""Builds garment segmentation data from Fashionpedia masks.

Usage:
  python -m ai_stylist_training.seg_prepare --annotations ann.json --images DIR \
      --out data/seg --split train --holdout 0.1 [--synthetic 0.5]

For every photo it writes a SIZE x SIZE image (the whole photo, resized
without cropping, as the app does) and a label mask:

  0         background (including skin and hair: only clothing is cut out)
  1..N      garment type, in config/label_map.json order (same as the classifier)
  255       ignore (crowd regions and excluded classes like socks or tights)

Garment parts (sleeve, pocket, collar...) are not painted: they lie inside
their garment. Larger garments are painted first so a belt or bag drawn
later stays on top of the dress beneath it.

Synthetic flat-lays: with probability --synthetic, the photo's largest
garment is also cut out with its mask and placed on a plain backdrop. This
teaches the model the app's usual case (one item on a bed, floor or wall)
using only Fashionpedia data.

Masks may be COCO polygons, uncompressed RLE or compressed RLE; the report
counts which formats were seen. Compressed RLE needs pycocotools.
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import sys
from collections import Counter
from multiprocessing import Pool
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

from . import label_map as lm
from .prepare_data import _split_for, resolve_classes

SIZE = 256
IGNORE = 255
BACKGROUND = 0
SYNTH_MIN_SHARE = 0.04  # a garment must cover >= 4% of the photo to be cut out
SYNTH_MIN_SIDE = 64
# Plain backdrops seen in wardrobe photos: white, off-white, grey, beige,
# wood, dark.
BACKDROPS = [(245, 245, 242), (232, 228, 220), (200, 200, 200), (215, 200, 175),
             (160, 120, 85), (60, 60, 64), (235, 235, 235), (190, 180, 165)]


def decode(seg, height: int, width: int) -> tuple[np.ndarray, str]:
    """Binary mask (height, width) and the format name."""
    if isinstance(seg, list):
        canvas = Image.new("L", (width, height), 0)
        draw = ImageDraw.Draw(canvas)
        for poly in seg:
            if len(poly) >= 6:
                draw.polygon(list(zip(poly[0::2], poly[1::2])), fill=1)
        return np.asarray(canvas, bool), "polygon"
    if isinstance(seg, dict) and "counts" in seg:
        rh, rw = seg["size"]
        counts = seg["counts"]
        if isinstance(counts, list):
            flat = np.zeros(rh * rw, bool)
            pos, value = 0, False
            for run in counts:
                if value:
                    flat[pos:pos + run] = True
                pos += run
                value = not value
            mask = flat.reshape((rh, rw), order="F")  # COCO RLE is column-major
            fmt = "rle"
        else:
            from pycocotools import mask as coco_mask  # type: ignore[import-not-found]

            raw = counts.encode() if isinstance(counts, str) else counts
            mask = coco_mask.decode({"size": [rh, rw], "counts": raw}).astype(bool)
            fmt = "rle_compressed"
        if mask.shape != (height, width):
            mask = np.asarray(Image.fromarray(mask).resize((width, height), Image.NEAREST), bool)
        return mask, fmt
    raise ValueError(f"unknown segmentation format: {type(seg).__name__}")


def paint(anns: list[dict], height: int, width: int, class_of: dict[int, int],
          excluded: set[int]) -> tuple[np.ndarray, Counter, list[tuple[int, np.ndarray, float]]]:
    """Label mask, formats seen, and (class, mask, area) for each garment."""
    label = np.full((height, width), BACKGROUND, np.uint8)
    formats: Counter = Counter()
    garments = []
    for ann in sorted(anns, key=lambda a: -float(a.get("area") or 0)):
        cat = ann["category_id"]
        if cat not in class_of and cat not in excluded:
            continue  # parts: inside their garment
        mask, fmt = decode(ann["segmentation"], height, width)
        formats[fmt] += 1
        if ann.get("iscrowd") or cat in excluded:
            label[mask] = IGNORE
            continue
        label[mask] = class_of[cat] + 1
        garments.append((class_of[cat], mask, float(mask.sum())))
    return label, formats, garments


def synthetic(image: np.ndarray, garments: list[tuple[int, np.ndarray, float]],
              rng: np.random.Generator) -> tuple[np.ndarray, np.ndarray] | None:
    """The largest garment on a plain backdrop, or None if none is big enough."""
    h, w = image.shape[:2]
    big = [g for g in garments if g[2] >= SYNTH_MIN_SHARE * h * w]
    if not big:
        return None
    cls, mask, _ = max(big, key=lambda g: g[2])
    ys, xs = np.nonzero(mask)
    top, bottom, left, right = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    if min(bottom - top, right - left) < SYNTH_MIN_SIDE:
        return None
    pad = rng.uniform(0.1, 0.35)
    ph, pw = int((bottom - top) * pad), int((right - left) * pad)
    crop_img = image[top:bottom, left:right]
    crop_mask = mask[top:bottom, left:right]
    out_h, out_w = (bottom - top) + 2 * ph, (right - left) + 2 * pw
    colour = np.array(BACKDROPS[rng.integers(len(BACKDROPS))], np.float32)
    colour += rng.uniform(-12, 12, 3)
    gradient = np.linspace(-10, 10, out_h, dtype=np.float32)[:, None, None] * rng.choice([-1, 1])
    backdrop = colour[None, None, :] + gradient + rng.normal(0, 3, (out_h, out_w, 3))
    canvas = np.clip(backdrop, 0, 255).astype(np.uint8)
    region = canvas[ph:ph + crop_img.shape[0], pw:pw + crop_img.shape[1]]
    region[crop_mask] = crop_img[crop_mask]
    label = np.zeros((out_h, out_w), np.uint8)
    label[ph:ph + crop_mask.shape[0], pw:pw + crop_mask.shape[1]][crop_mask] = cls + 1
    return canvas, label


def _save(image: np.ndarray, label: np.ndarray, image_path: Path, mask_path: Path) -> np.ndarray:
    small = Image.fromarray(label).resize((SIZE, SIZE), Image.NEAREST)
    Image.fromarray(image).resize((SIZE, SIZE), Image.BILINEAR).save(image_path, quality=92)
    small.save(mask_path)
    return np.bincount(np.asarray(small).ravel(), minlength=256)


def _work(job: tuple) -> dict:
    """Processes one photo (runs in a worker process)."""
    (info, anns, images, out, split, class_of, excluded, synth_p, num_classes) = job
    result = {"rows": [], "pixels": np.zeros(256, np.int64), "formats": Counter(),
              "skipped": None, "synthetic": 0}
    try:
        with Image.open(images / info["file_name"]) as im:
            image = np.asarray(im.convert("RGB"))
    except (OSError, ValueError) as e:
        result["skipped"] = f"unreadable: {type(e).__name__}"
        return result
    h, w = image.shape[:2]
    if (h, w) != (info["height"], info["width"]):
        result["skipped"] = "size_mismatch"
        return result
    try:
        label, formats, garments = paint(anns, h, w, class_of, excluded)
    except (ValueError, ImportError) as e:
        result["skipped"] = f"mask: {type(e).__name__}: {e}"
        return result
    result["formats"] = formats
    if not garments:
        result["skipped"] = "no_garment"
        return result
    stem = str(info["id"])
    for d in ("images", "masks"):
        (out / split / d).mkdir(parents=True, exist_ok=True)
    rel_img, rel_mask = f"{split}/images/{stem}.jpg", f"{split}/masks/{stem}.png"
    result["pixels"] += _save(image, label, out / rel_img, out / rel_mask)
    result["rows"].append({"image": rel_img, "mask": rel_mask, "image_id": info["id"], "synthetic": 0})

    rng = np.random.default_rng(int(info["id"]))
    if rng.random() < synth_p:
        made = synthetic(image, garments, rng)
        if made is not None:
            rel_img, rel_mask = f"{split}/images/{stem}_s.jpg", f"{split}/masks/{stem}_s.png"
            result["pixels"] += _save(made[0], made[1], out / rel_img, out / rel_mask)
            result["rows"].append({"image": rel_img, "mask": rel_mask, "image_id": info["id"], "synthetic": 1})
            result["synthetic"] = 1
    return result


def run(annotations: Path, images: Path, out: Path, split: str, holdout: float,
        labels: lm.LabelMap, synth_p: float = 0.5, workers: int | None = None,
        limit: int | None = None) -> dict:
    data = json.loads(annotations.read_text(encoding="utf-8"))
    class_of, categories = resolve_classes(data, labels)
    excluded = {categories[n] for n in labels.excluded}
    by_image: dict[int, list[dict]] = {}
    for ann in data["annotations"]:
        by_image.setdefault(ann["image_id"], []).append(ann)
    infos = data["images"][:limit] if limit else data["images"]
    licence_names = {l["id"]: l.get("name", str(l["id"])) for l in data.get("licenses", [])}

    def split_of(info: dict) -> str:
        return split if split == "test" else _split_for(info["id"], holdout)

    jobs = [(info, by_image.get(info["id"], []), images, out, split_of(info), class_of,
             excluded, synth_p, len(labels.classes)) for info in infos]
    out.mkdir(parents=True, exist_ok=True)
    rows: dict[str, list[dict]] = {}
    pixels = {}
    formats: Counter = Counter()
    skipped: Counter = Counter()
    synth = Counter()
    licences = Counter(licence_names.get(i.get("license"), "unknown") for i in infos)
    if workers == 1:
        results = map(_work, jobs)
        pool = None
    else:
        pool = Pool(workers or os.cpu_count())
        results = pool.imap(_work, jobs, chunksize=16)
    try:
        for job, r in zip(jobs, results):
            s = job[4]
            if r["skipped"]:
                skipped[r["skipped"]] += 1
            rows.setdefault(s, []).extend(r["rows"])
            pixels[s] = pixels.get(s, np.zeros(256, np.int64)) + r["pixels"]
            formats.update(r["formats"])
            synth[s] += r["synthetic"]
    finally:
        if pool is not None:
            pool.close()
            pool.join()

    names = ["background"] + labels.type_labels
    report = {"split": split, "size": SIZE, "classes": names, "samples": {}, "synthetic": dict(synth),
              "pixels": {}, "maskFormats": dict(formats), "skipped": dict(skipped),
              "imageLicences": dict(licences)}
    for s, rs in sorted(rows.items()):
        rs.sort(key=lambda r: (r["image_id"], r["synthetic"]))
        with (out / f"{s}.csv").open("w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=["image", "mask", "image_id", "synthetic"])
            writer.writeheader()
            writer.writerows(rs)
        report["samples"][s] = len(rs)
        counts = pixels[s]
        report["pixels"][s] = {n: int(counts[i]) for i, n in enumerate(names)} | {"ignore": int(counts[IGNORE])}
    (out / f"{split}_report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    return report


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--annotations", type=Path, required=True)
    p.add_argument("--images", type=Path, required=True)
    p.add_argument("--out", type=Path, required=True)
    p.add_argument("--split", choices=["train", "test"], required=True)
    p.add_argument("--holdout", type=float, default=0.1, help="share of train photos used for val")
    p.add_argument("--synthetic", type=float, default=0.5, help="chance of a flat-lay copy per photo")
    p.add_argument("--label-map", type=Path, default=lm.DEFAULT_LABEL_MAP)
    p.add_argument("--workers", type=int, default=None)
    p.add_argument("--limit", type=int, default=None, help="first N photos only (quick checks)")
    args = p.parse_args(argv)
    report = run(args.annotations, args.images, args.out, args.split, args.holdout,
                 lm.load(args.label_map), args.synthetic, args.workers, args.limit)
    print(json.dumps({k: report[k] for k in ("samples", "synthetic", "maskFormats", "skipped")}, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
