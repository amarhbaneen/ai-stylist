"""Garment segmentation model: MobileNetV3-Large encoder + light decoder.

The decoder follows the LR-ASPP idea from the MobileNetV3 paper (a cheap
attention branch on the deepest features), plus stride-8 and stride-4 skips
for sharp garment edges, which matter for cutouts. Every op (1x1/3x3 conv,
global pooling, sigmoid, bilinear resize, add, concat) is a standard LiteRT
builtin that XNNPACK supports.
"""

from __future__ import annotations

import keras
import tensorflow as tf

from .seg_prepare import IGNORE, SIZE


def feature_at(base: keras.Model, stride: int):
    """Output of the last backbone layer at 1/stride resolution. Found by
    shape, so it does not depend on Keras layer names."""
    target = SIZE // stride
    found = None
    for layer in base.layers:
        shape = getattr(layer, "output", None)
        shape = getattr(shape, "shape", None)
        if shape is not None and len(shape) == 4 and shape[1] == target and shape[2] == target:
            found = layer.output
    if found is None:
        raise ValueError(f"no backbone feature at stride {stride}")
    return found


def _conv(x, filters: int, kernel: int = 1, name: str | None = None):
    x = keras.layers.Conv2D(filters, kernel, padding="same", use_bias=False, name=name)(x)
    x = keras.layers.BatchNormalization()(x)
    return keras.layers.ReLU()(x)


def build(num_classes: int) -> tuple[keras.Model, keras.Model]:
    """Returns (model, backbone). Input float32 RGB 0-255 [SIZE, SIZE, 3];
    output logits [SIZE, SIZE, num_classes]."""
    base = keras.applications.MobileNetV3Large(
        input_shape=(SIZE, SIZE, 3), include_top=False, weights="imagenet",
        include_preprocessing=True,
    )
    encoder = keras.Model(
        base.input,
        [feature_at(base, 4), feature_at(base, 8), base.output],
        name="encoder",
    )
    inputs = keras.Input((SIZE, SIZE, 3), name="image")
    f4, f8, f32 = encoder(inputs, training=False)

    # LR-ASPP: features x attention, at stride 32.
    x = _conv(f32, 128)
    attention = keras.layers.GlobalAveragePooling2D(keepdims=True)(f32)
    attention = keras.layers.Conv2D(128, 1, activation="sigmoid")(attention)
    x = keras.layers.Multiply()([x, attention])
    x = keras.layers.UpSampling2D(4, interpolation="bilinear")(x)  # -> stride 8

    x = keras.layers.Concatenate()([x, _conv(f8, 64)])
    x = _conv(x, 96, 3)
    x = keras.layers.UpSampling2D(2, interpolation="bilinear")(x)  # -> stride 4
    x = keras.layers.Concatenate()([x, _conv(f4, 32)])
    x = _conv(x, 64, 3)
    x = keras.layers.Conv2D(num_classes, 1, name="classes")(x)
    logits = keras.layers.UpSampling2D(4, interpolation="bilinear", name="logits")(x)
    return keras.Model(inputs, logits, name="garment_segmenter"), base


def seg_loss(weights, dice_weight: float = 0.5):
    """Weighted cross-entropy (ignore=255) plus a soft Dice term on
    garment-vs-background, which drives clean cutout edges."""
    weights = tf.constant(weights, tf.float32)

    def loss(y_true, logits):
        y = tf.cast(tf.squeeze(y_true, -1), tf.int32)
        valid = tf.cast(y != IGNORE, tf.float32)
        safe = tf.where(y == IGNORE, 0, y)
        ce = tf.keras.losses.sparse_categorical_crossentropy(safe, logits, from_logits=True)
        w = tf.gather(weights, safe) * valid
        ce = tf.reduce_sum(ce * w) / tf.maximum(tf.reduce_sum(valid), 1.0)

        fg_prob = 1.0 - tf.nn.softmax(logits)[..., 0]
        fg_true = tf.cast(safe > 0, tf.float32)
        inter = tf.reduce_sum(fg_prob * fg_true * valid)
        total = tf.reduce_sum((fg_prob + fg_true) * valid)
        dice = 1.0 - (2.0 * inter + 1.0) / (total + 1.0)
        return ce + dice_weight * dice

    return loss


class ForegroundIoU(keras.metrics.Metric):
    """Garment-vs-background IoU (what a cutout needs), ignoring 255."""

    def __init__(self, name: str = "fg_iou", **kwargs):
        super().__init__(name=name, **kwargs)
        self.inter = self.add_weight(name="inter", initializer="zeros")
        self.union = self.add_weight(name="union", initializer="zeros")

    def update_state(self, y_true, logits, sample_weight=None):
        y = tf.cast(tf.squeeze(y_true, -1), tf.int32)
        valid = y != IGNORE
        pred = tf.argmax(logits, -1, output_type=tf.int32) > 0
        true = (y > 0) & valid
        pred = pred & valid
        self.inter.assign_add(tf.reduce_sum(tf.cast(pred & true, tf.float32)))
        self.union.assign_add(tf.reduce_sum(tf.cast(pred | true, tf.float32)))

    def result(self):
        return self.inter / tf.maximum(self.union, 1.0)

    def reset_state(self):
        self.inter.assign(0.0)
        self.union.assign(0.0)


def with_softmax(model: keras.Model) -> keras.Model:
    """Inference model for export: per-pixel class probabilities."""
    inputs = keras.Input((SIZE, SIZE, 3), name="image")
    probs = keras.layers.Softmax(name="mask")(model(inputs, training=False))
    return keras.Model(inputs, {"mask": probs}, name="garment_segmenter_inference")
