"""Fine-tunes the classifier on the prepared crops.

Usage:
  python -m ai_stylist_training.train --crops data/crops --out out/run1

Stage 1 trains only the two heads with the backbone frozen; stage 2 also
unfreezes the top of the backbone at a lower learning rate. The best weights
(lowest validation loss) are kept.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import keras
import numpy as np
import tensorflow as tf

from . import label_map as lm
from .data import dataset, read_rows, class_weights
from .model import build, weighted_sparse_ce


def _compile(model: keras.Model, lr: float, type_w: np.ndarray, pattern_w: np.ndarray,
             pattern_loss_weight: float) -> None:
    model.compile(
        optimizer=keras.optimizers.Adam(lr),
        loss={
            "type": weighted_sparse_ce(type_w),
            "pattern": weighted_sparse_ce(pattern_w, ignore_negative=True),
        },
        loss_weights={"type": 1.0, "pattern": pattern_loss_weight},
        metrics={"type": [keras.metrics.SparseCategoricalAccuracy(name="acc")]},
    )


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--crops", type=Path, required=True)
    p.add_argument("--out", type=Path, required=True)
    p.add_argument("--label-map", type=Path, default=lm.DEFAULT_LABEL_MAP)
    p.add_argument("--backbone", default="mobilenet_v3_large")
    p.add_argument("--batch", type=int, default=64)
    p.add_argument("--head-epochs", type=int, default=4)
    p.add_argument("--finetune-epochs", type=int, default=12)
    p.add_argument("--unfreeze-fraction", type=float, default=0.4,
                   help="top fraction of backbone layers trained in stage 2")
    p.add_argument("--pattern-loss-weight", type=float, default=0.5)
    p.add_argument("--seed", type=int, default=7)
    args = p.parse_args(argv)

    keras.utils.set_random_seed(args.seed)
    labels = lm.load(args.label_map)
    args.out.mkdir(parents=True, exist_ok=True)

    _, types, patterns = read_rows(args.crops, "train", labels)
    type_w = class_weights(np.bincount(types, minlength=len(labels.classes)))
    pattern_w = class_weights(
        np.bincount(patterns[patterns >= 0], minlength=len(labels.pattern_classes))
    )
    train_ds = dataset(args.crops, "train", labels, args.batch, training=True, seed=args.seed)
    val_ds = dataset(args.crops, "val", labels, args.batch, training=False)

    model, base = build(len(labels.classes), len(labels.pattern_classes), args.backbone)
    best = args.out / "model.keras"
    callbacks = [
        keras.callbacks.ModelCheckpoint(best, monitor="val_loss", save_best_only=True),
        keras.callbacks.CSVLogger(args.out / "history.csv", append=True),
    ]

    # Stage 1: heads only.
    base.trainable = False
    _compile(model, 1e-3, type_w, pattern_w, args.pattern_loss_weight)
    model.fit(train_ds, validation_data=val_ds, epochs=args.head_epochs, callbacks=callbacks)

    # Stage 2: top of the backbone too, with a decaying, lower learning rate.
    base.trainable = True
    cut = int(len(base.layers) * (1 - args.unfreeze_fraction))
    for layer in base.layers[:cut]:
        layer.trainable = False
    steps = args.finetune_epochs * int(tf.data.experimental.cardinality(train_ds).numpy())
    schedule = keras.optimizers.schedules.CosineDecay(1e-4, decay_steps=max(steps, 1))
    _compile(model, schedule, type_w, pattern_w, args.pattern_loss_weight)
    model.fit(
        train_ds,
        validation_data=val_ds,
        initial_epoch=args.head_epochs,
        epochs=args.head_epochs + args.finetune_epochs,
        callbacks=callbacks + [
            keras.callbacks.EarlyStopping(monitor="val_loss", patience=3, restore_best_weights=True)
        ],
    )

    (args.out / "labels.json").write_text(json.dumps(labels.labels_json(), indent=2), encoding="utf-8")
    (args.out / "train_config.json").write_text(
        json.dumps({k: str(v) for k, v in vars(args).items()}, indent=2), encoding="utf-8"
    )
    print(f"Best model: {best}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
