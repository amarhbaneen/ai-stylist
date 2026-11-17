"""tf.data input pipeline over the crops written by prepare_data.py."""

from __future__ import annotations

import csv
from pathlib import Path

import numpy as np
import tensorflow as tf

from . import label_map as lm

IMAGE_SIZE = 224
NO_PATTERN = -1  # pattern label for garments without a pattern attribute


def read_rows(crops: Path, split: str, labels: lm.LabelMap) -> tuple[list[str], np.ndarray, np.ndarray]:
    """Paths, type indices and pattern indices (-1 = no pattern label)."""
    type_index = {label: i for i, label in enumerate(labels.type_labels)}
    pattern_index = {code: i for i, code in enumerate(labels.pattern_classes)}
    paths, types, patterns = [], [], []
    with (crops / f"{split}.csv").open(encoding="utf-8") as f:
        for row in csv.DictReader(f):
            paths.append(str(crops / row["path"]))
            types.append(type_index[row["type"]])
            patterns.append(pattern_index.get(row["pattern"], NO_PATTERN))
    return paths, np.array(types, np.int32), np.array(patterns, np.int32)


def _load(path: tf.Tensor) -> tf.Tensor:
    image = tf.io.decode_jpeg(tf.io.read_file(path), channels=3)
    return tf.cast(image, tf.float32)  # 0-255, as the app will feed it


def _augment(image: tf.Tensor) -> tf.Tensor:
    """Random crop, flip and lighting, so worn-garment crops look more like
    varied phone photos."""
    shape = tf.shape(image)
    scale = tf.random.uniform([], 0.65, 1.0)
    h = tf.cast(tf.cast(shape[0], tf.float32) * scale, tf.int32)
    w = tf.cast(tf.cast(shape[1], tf.float32) * scale, tf.int32)
    image = tf.image.random_crop(image, tf.stack([h, w, 3]))
    image = tf.image.resize(image, [IMAGE_SIZE, IMAGE_SIZE])
    image = tf.image.random_flip_left_right(image)
    image = tf.image.random_brightness(image, 25.0)
    image = tf.image.random_contrast(image, 0.8, 1.2)
    image = tf.image.random_saturation(image, 0.8, 1.2)
    return tf.clip_by_value(image, 0.0, 255.0)


def _center(image: tf.Tensor) -> tf.Tensor:
    """What the app does: the whole photo, resized (no crop)."""
    return tf.image.resize(image, [IMAGE_SIZE, IMAGE_SIZE])


def dataset(crops: Path, split: str, labels: lm.LabelMap, batch: int,
            training: bool, seed: int = 7) -> tf.data.Dataset:
    paths, types, patterns = read_rows(crops, split, labels)
    ds = tf.data.Dataset.from_tensor_slices((paths, types, patterns))
    if training:
        ds = ds.shuffle(min(len(paths), 20000), seed=seed, reshuffle_each_iteration=True)
    prep = _augment if training else _center
    ds = ds.map(
        lambda p, t, q: (prep(_load(p)), {"type": t, "pattern": q}),
        num_parallel_calls=tf.data.AUTOTUNE,
    )
    return ds.batch(batch).prefetch(tf.data.AUTOTUNE)


def class_weights(counts: np.ndarray, power: float = 0.5, cap: float = 10.0) -> np.ndarray:
    """Softened inverse-frequency weights (mean 1), so rare classes are not
    ignored without letting them dominate."""
    counts = np.maximum(counts.astype(np.float64), 1.0)
    weights = (counts.max() / counts) ** power
    weights = np.minimum(weights, cap)
    return (weights / weights.mean()).astype(np.float32)
