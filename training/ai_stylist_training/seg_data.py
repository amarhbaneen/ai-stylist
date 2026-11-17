"""tf.data pipeline over the images and masks written by seg_prepare.py."""

from __future__ import annotations

import csv
import json
from pathlib import Path

import numpy as np
import tensorflow as tf

from .data import class_weights
from .seg_prepare import IGNORE, SIZE


def read_rows(root: Path, split: str) -> tuple[list[str], list[str], np.ndarray]:
    images, masks, synthetic = [], [], []
    with (root / f"{split}.csv").open(encoding="utf-8") as f:
        for row in csv.DictReader(f):
            images.append(str(root / row["image"]))
            masks.append(str(root / row["mask"]))
            synthetic.append(int(row["synthetic"]))
    return images, masks, np.array(synthetic, np.int32)


def pixel_weights(root: Path, num_classes: int) -> np.ndarray:
    """Per-class loss weights from the train pixel counts in the report."""
    report = json.loads((root / "train_report.json").read_text(encoding="utf-8"))
    counts = report["pixels"]["train"]
    names = report["classes"]
    return class_weights(np.array([counts[n] for n in names[:num_classes]]), power=0.5, cap=10.0)


def _load(image_path: tf.Tensor, mask_path: tf.Tensor) -> tuple[tf.Tensor, tf.Tensor]:
    image = tf.cast(tf.io.decode_jpeg(tf.io.read_file(image_path), channels=3), tf.float32)
    mask = tf.io.decode_png(tf.io.read_file(mask_path), channels=1)
    return image, mask


def _augment(image: tf.Tensor, mask: tf.Tensor) -> tuple[tf.Tensor, tf.Tensor]:
    """Same random crop and flip for image and mask; lighting on the image."""
    scale = tf.random.uniform([], 0.7, 1.0)
    side = tf.cast(SIZE * scale, tf.int32)
    stacked = tf.concat([image, tf.cast(mask, tf.float32)], axis=-1)
    stacked = tf.image.random_crop(stacked, tf.stack([side, side, 4]))
    stacked = tf.image.random_flip_left_right(stacked)
    image = tf.image.resize(stacked[..., :3], [SIZE, SIZE], method="bilinear")
    mask = tf.image.resize(stacked[..., 3:], [SIZE, SIZE], method="nearest")
    image = tf.image.random_brightness(image, 25.0)
    image = tf.image.random_contrast(image, 0.8, 1.2)
    image = tf.image.random_saturation(image, 0.8, 1.2)
    return tf.clip_by_value(image, 0.0, 255.0), tf.cast(mask, tf.uint8)


def dataset(root: Path, split: str, batch: int, training: bool, seed: int = 7,
            only_synthetic: bool | None = None) -> tf.data.Dataset:
    """(image float32 0-255, mask uint8 [SIZE, SIZE, 1]) batches. With
    [only_synthetic] True/False, keeps only synthetic/real samples."""
    images, masks, synthetic = read_rows(root, split)
    if only_synthetic is not None:
        keep = synthetic == (1 if only_synthetic else 0)
        images = [p for p, k in zip(images, keep) if k]
        masks = [p for p, k in zip(masks, keep) if k]
    ds = tf.data.Dataset.from_tensor_slices((images, masks))
    if training:
        ds = ds.shuffle(min(len(images), 20000), seed=seed, reshuffle_each_iteration=True)
    ds = ds.map(_load, num_parallel_calls=tf.data.AUTOTUNE)
    if training:
        ds = ds.map(_augment, num_parallel_calls=tf.data.AUTOTUNE)
    return ds.batch(batch).prefetch(tf.data.AUTOTUNE)


__all__ = ["IGNORE", "SIZE", "dataset", "pixel_weights", "read_rows"]
