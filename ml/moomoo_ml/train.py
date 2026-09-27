"""Training of one experiment with checkpoints, early stopping and resume."""

from __future__ import annotations

import json
import time
from pathlib import Path
from typing import Callable

import numpy as np

from .data import PreparedData
from .model import build_model, uses_sparse_labels


def class_weights(y: np.ndarray, num_classes: int) -> dict[int, float]:
    counts = np.bincount(y, minlength=num_classes).astype(np.float64)
    present = counts > 0
    weights = np.zeros(num_classes)
    weights[present] = len(y) / (present.sum() * counts[present])
    return {i: float(w) for i, w in enumerate(weights) if w > 0}


def _targets(y: np.ndarray, num_classes: int, sparse: bool) -> np.ndarray:
    if sparse:
        return y
    return np.eye(num_classes, dtype=np.float32)[y]


def _current_lr(model) -> float:
    lr = model.optimizer.learning_rate
    try:
        return float(np.array(lr))
    except TypeError:
        return float(lr(model.optimizer.iterations))


class TrainingOutcome(dict):
    """best_val_accuracy, best_val_loss, epochs_done, stopped_early, cancelled, history."""


def train_experiment(
    data: PreparedData,
    cfg: dict,
    exp_dir: Path,
    *,
    target_epochs: int,
    on_epoch: Callable[[int, dict, float, float], None] | None = None,
    should_stop: Callable[[], bool] | None = None,
    log: Callable[[str], None] | None = None,
) -> TrainingOutcome:
    """Trains up to [target_epochs] (absolute), resuming from exp_dir/last.keras."""
    from tensorflow import keras

    exp_dir.mkdir(parents=True, exist_ok=True)
    last_path = exp_dir / "last.keras"
    best_path = exp_dir / "best.keras"
    state_path = exp_dir / "state.json"

    initial_epoch = 0
    history: list[dict] = []
    best = {"val_loss": None, "val_accuracy": None}
    if last_path.exists() and state_path.exists():
        state = json.loads(state_path.read_text())
        initial_epoch = int(state.get("epoch", 0))
        history = state.get("history", [])
        best = state.get("best", best)
        model = keras.models.load_model(last_path)
        if log:
            log(f"Reprise depuis l'epoch {initial_epoch}")
    else:
        model = build_model(cfg, data.input_shape, data.num_classes)

    if initial_epoch >= target_epochs:
        return TrainingOutcome(
            best_val_accuracy=best["val_accuracy"], best_val_loss=best["val_loss"],
            epochs_done=initial_epoch, stopped_early=False, cancelled=False, history=history,
            params=int(model.count_params()),
        )

    sparse = uses_sparse_labels(cfg)
    y_train = _targets(data.y_train, data.num_classes, sparse)
    has_val = len(data.x_val) > 0
    validation = (data.x_val, _targets(data.y_val, data.num_classes, sparse)) if has_val else None
    monitor = "val_loss" if has_val else "loss"

    flags = {"cancelled": False}

    class Progress(keras.callbacks.Callback):
        def on_epoch_begin(self, epoch, logs=None):
            self._t0 = time.perf_counter()

        def on_epoch_end(self, epoch, logs=None):
            logs = {k: float(v) for k, v in (logs or {}).items()}
            lr = _current_lr(self.model)
            duration = time.perf_counter() - self._t0
            row = {"epoch": epoch + 1, **logs, "learning_rate": lr, "duration_s": duration}
            history.append(row)
            vl, va = logs.get("val_loss"), logs.get("val_accuracy")
            if vl is not None and (best["val_loss"] is None or vl < best["val_loss"]):
                best["val_loss"] = vl
            if va is not None and (best["val_accuracy"] is None or va > best["val_accuracy"]):
                best["val_accuracy"] = va
            self.model.save(last_path)
            state_path.write_text(json.dumps({"epoch": epoch + 1, "history": history, "best": best}))
            if on_epoch:
                on_epoch(epoch + 1, logs, lr, duration)
            if should_stop and should_stop():
                flags["cancelled"] = True
                self.model.stop_training = True

    early = keras.callbacks.EarlyStopping(
        monitor=monitor,
        patience=int(cfg["early_stopping_patience"]),
        restore_best_weights=True,
        start_from_epoch=min(initial_epoch, max(0, target_epochs - 1)),
    )
    callbacks = [
        keras.callbacks.ModelCheckpoint(best_path, monitor=monitor, save_best_only=True),
        early,
        keras.callbacks.ReduceLROnPlateau(
            monitor=monitor,
            factor=float(cfg["reduce_lr_factor"]),
            patience=int(cfg["reduce_lr_patience"]),
            min_lr=float(cfg["min_learning_rate"]),
        ),
        keras.callbacks.CSVLogger(str(exp_dir / "history.csv"), append=initial_epoch > 0),
        Progress(),
    ]

    weights = class_weights(data.y_train, data.num_classes) if cfg.get("class_weight") == "balanced" else None
    model.fit(
        data.x_train,
        y_train,
        validation_data=validation,
        epochs=target_epochs,
        initial_epoch=initial_epoch,
        batch_size=int(cfg["batch_size"]),
        class_weight=weights,
        shuffle=True,
        callbacks=callbacks,
        verbose=0,
    )

    epochs_done = history[-1]["epoch"] if history else initial_epoch
    return TrainingOutcome(
        best_val_accuracy=best["val_accuracy"],
        best_val_loss=best["val_loss"],
        epochs_done=epochs_done,
        stopped_early=bool(early.stopped_epoch) and not flags["cancelled"],
        cancelled=flags["cancelled"],
        history=history,
        params=int(model.count_params()),
    )


def load_best(exp_dir: Path):
    from tensorflow import keras

    path = exp_dir / "best.keras"
    if not path.exists():
        path = exp_dir / "last.keras"
    return keras.models.load_model(path)
