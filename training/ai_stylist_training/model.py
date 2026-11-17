"""The two-head classifier and its losses."""

from __future__ import annotations

import keras
import tensorflow as tf

from .data import IMAGE_SIZE

BACKBONES = {
    # ~5.4M params, ~5-6 MB after int8: the default.
    "mobilenet_v3_large": keras.applications.MobileNetV3Large,
    # ~2.5M params: smaller and faster, less accurate.
    "mobilenet_v3_small": keras.applications.MobileNetV3Small,
}


def build(num_types: int, num_patterns: int, backbone: str = "mobilenet_v3_large",
          dropout: float = 0.2) -> tuple[keras.Model, keras.Model]:
    """Returns (model, backbone). The model takes float32 RGB 0-255 images
    (the backbone includes its own preprocessing) and outputs logits."""
    base = BACKBONES[backbone](
        input_shape=(IMAGE_SIZE, IMAGE_SIZE, 3),
        include_top=False,
        weights="imagenet",
        include_preprocessing=True,
        pooling="avg",
    )
    inputs = keras.Input((IMAGE_SIZE, IMAGE_SIZE, 3), name="image")
    # training=False keeps BatchNorm statistics frozen, also while fine-tuning.
    features = base(inputs, training=False)
    features = keras.layers.Dropout(dropout)(features)
    outputs = {
        "type": keras.layers.Dense(num_types, name="type")(features),
        "pattern": keras.layers.Dense(num_patterns, name="pattern")(features),
    }
    return keras.Model(inputs, outputs, name="garment_classifier"), base


def weighted_sparse_ce(weights: tf.Tensor, ignore_negative: bool = False):
    """Sparse cross-entropy on logits with per-class weights. With
    [ignore_negative], labels < 0 contribute nothing (no pattern label)."""
    weights = tf.constant(weights, tf.float32)

    def loss(y_true, logits):
        y_true = tf.reshape(tf.cast(y_true, tf.int32), [-1])
        mask = tf.cast(y_true >= 0, tf.float32) if ignore_negative else tf.ones_like(y_true, tf.float32)
        safe = tf.maximum(y_true, 0)
        ce = tf.keras.losses.sparse_categorical_crossentropy(safe, logits, from_logits=True)
        w = tf.gather(weights, safe) * mask
        return tf.reduce_sum(ce * w) / tf.maximum(tf.reduce_sum(mask), 1.0)

    return loss


def with_softmax(model: keras.Model, temperatures: dict[str, float]) -> keras.Model:
    """Inference model for export: calibrated probabilities per head."""
    inputs = keras.Input((IMAGE_SIZE, IMAGE_SIZE, 3), name="image")
    logits = model(inputs, training=False)
    outputs = {
        name: keras.layers.Softmax(name=name)(
            keras.layers.Rescaling(1.0 / temperatures.get(name, 1.0))(logits[name])
        )
        for name in ("type", "pattern")
    }
    return keras.Model(inputs, outputs, name="garment_classifier_inference")
