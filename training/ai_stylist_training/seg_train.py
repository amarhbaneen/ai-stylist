"""Trains the garment segmentation model on seg_prepare.py output.

Usage:
  python -m ai_stylist_training.seg_train --data data/seg --out out/seg1

Stage 1 trains the decoder with the backbone frozen; stage 2 also trains
the top of the backbone with a decaying learning rate. The best weights
(lowest validation loss) are kept as model.keras.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import keras
import tensorflow as tf

from . import label_map as lm
from .seg_data import dataset, pixel_weights
from .seg_model import ForegroundIoU, build, seg_loss


def _compile(model: keras.Model, lr, weights, dice_weight: float) -> None:
    model.compile(
        optimizer=keras.optimizers.Adam(lr),
        loss=seg_loss(weights, dice_weight),
        metrics=[ForegroundIoU()],
    )


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--data", type=Path, required=True)
    p.add_argument("--out", type=Path, required=True)
    p.add_argument("--label-map", type=Path, default=lm.DEFAULT_LABEL_MAP)
    p.add_argument("--batch", type=int, default=16)
    p.add_argument("--head-epochs", type=int, default=3)
    p.add_argument("--finetune-epochs", type=int, default=15)
    p.add_argument("--unfreeze-fraction", type=float, default=0.5)
    p.add_argument("--dice-weight", type=float, default=0.5)
    p.add_argument("--seed", type=int, default=7)
    args = p.parse_args(argv)

    keras.utils.set_random_seed(args.seed)
    labels = lm.load(args.label_map)
    num_classes = len(labels.classes) + 1  # + background
    args.out.mkdir(parents=True, exist_ok=True)

    weights = pixel_weights(args.data, num_classes)
    train_ds = dataset(args.data, "train", args.batch, training=True, seed=args.seed)
    val_ds = dataset(args.data, "val", args.batch, training=False)

    model, base = build(num_classes)
    best = args.out / "model.keras"
    callbacks = [
        keras.callbacks.ModelCheckpoint(best, monitor="val_loss", save_best_only=True),
        keras.callbacks.CSVLogger(args.out / "history.csv", append=True),
    ]

    base.trainable = False
    _compile(model, 1e-3, weights, args.dice_weight)
    model.fit(train_ds, validation_data=val_ds, epochs=args.head_epochs, callbacks=callbacks)

    base.trainable = True
    cut = int(len(base.layers) * (1 - args.unfreeze_fraction))
    for layer in base.layers[:cut]:
        layer.trainable = False
    steps = args.finetune_epochs * int(tf.data.experimental.cardinality(train_ds).numpy())
    schedule = keras.optimizers.schedules.CosineDecay(3e-4, decay_steps=max(steps, 1))
    _compile(model, schedule, weights, args.dice_weight)
    model.fit(
        train_ds,
        validation_data=val_ds,
        initial_epoch=args.head_epochs,
        epochs=args.head_epochs + args.finetune_epochs,
        callbacks=callbacks + [
            keras.callbacks.EarlyStopping(monitor="val_loss", patience=3, restore_best_weights=True)
        ],
    )

    (args.out / "train_config.json").write_text(
        json.dumps({k: str(v) for k, v in vars(args).items()} | {"weights": weights.tolist()},
                   indent=2), encoding="utf-8")
    print(f"Best model: {best}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
