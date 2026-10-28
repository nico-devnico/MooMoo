"""Fine-tune le CNN-BiLSTM pour fermer le gap import (100%) ↔ caméra live.

Reprend les meilleurs poids Keras, ré-entraîne avec une augmentation
« webcam » agressive, puis exporte TFLite + labels pour publication registre.
"""

from __future__ import annotations

import json
import os
from datetime import datetime

os.environ.setdefault("TF_CPP_MIN_LOG_LEVEL", "2")

import numpy as np
import tensorflow as tf
from tensorflow import keras

import config
from data_loader import collect_filepaths, make_dataset, stratified_splits
from model import compile_model
from train import build_callbacks, ensure_dirs, evaluate_split, plot_history


def main() -> None:
    ensure_dirs()
    tf.keras.utils.set_random_seed(config.RANDOM_SEED)

    max_per_class = int(os.environ.get("MOOMOO_FS_MAX_PER_CLASS", "1200"))
    epochs = int(os.environ.get("MOOMOO_FS_EPOCHS", "18"))
    lr = float(os.environ.get("MOOMOO_FS_LR", "2.5e-4"))

    best_path = config.MODELS_DIR / "best_asl_lstm.keras"
    if not best_path.exists():
        raise SystemExit(f"Poids de base introuvables : {best_path}")

    print("=" * 60)
    print("ASL fine-tune LIVE DOMAIN")
    print("=" * 60)
    print(f"Base weights : {best_path}")
    print(f"Max/classe   : {max_per_class}")
    print(f"Epochs       : {epochs}")
    print(f"LR           : {lr}")

    # Override config for this run (collect_filepaths reads config.MAX_PER_CLASS).
    config.MAX_PER_CLASS = max_per_class
    config.EPOCHS = epochs
    config.LEARNING_RATE = lr
    config.EARLY_STOP_PATIENCE = 6
    config.AUGMENT = True

    paths, labels = collect_filepaths(max_per_class=max_per_class)
    splits = stratified_splits(paths, labels)
    for name, (p, _y) in splits.items():
        print(f"  {name:5s}: {len(p):6d} images")

    train_ds = make_dataset(*splits["train"], shuffle=True, augment=True)
    val_ds = make_dataset(*splits["val"], shuffle=False, augment=False)
    test_ds = make_dataset(*splits["test"], shuffle=False, augment=False)

    model = keras.models.load_model(best_path)
    model = compile_model(model, learning_rate=lr)

    class LRLogger(keras.callbacks.Callback):
        def on_epoch_end(self, epoch, logs=None):
            logs = logs or {}
            rate = self.model.optimizer.learning_rate
            logs["lr"] = float(rate.numpy() if hasattr(rate, "numpy") else rate)

    history = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=epochs,
        callbacks=build_callbacks() + [LRLogger()],
        verbose=1,
    )
    plot_history(history)

    if best_path.exists():
        model = keras.models.load_model(best_path)

    val_metrics = evaluate_split(model, val_ds, "val")
    test_metrics = evaluate_split(model, test_ds, "test")

    final_path = config.MODELS_DIR / "asl_lstm_final.keras"
    model.save(final_path)

    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS,
        tf.lite.OpsSet.SELECT_TF_OPS,
    ]
    converter._experimental_lower_tensor_list_ops = False
    tflite_model = converter.convert()
    tflite_path = config.MODELS_DIR / "asl_lstm_mobile.tflite"
    tflite_path.write_bytes(tflite_model)

    labels_path = config.MODELS_DIR / "labels.json"
    labels_path.write_text(json.dumps(config.CLASSES, indent=2), encoding="utf-8")

    summary = {
        "timestamp": datetime.now().isoformat(timespec="seconds"),
        "architecture": "CNN-BiLSTM",
        "mode": "finetune_live_domain",
        "input_shape": list(config.INPUT_SHAPE),
        "num_classes": config.NUM_CLASSES,
        "max_per_class": max_per_class,
        "epochs_ran": len(history.history["loss"]),
        "best_val_accuracy": float(max(history.history["val_accuracy"])),
        "val": val_metrics,
        "test": {k: v for k, v in test_metrics.items() if k != "classification_report"},
        "model_keras": str(final_path),
        "model_tflite": str(tflite_path),
        "tflite_size_kb": round(tflite_path.stat().st_size / 1024, 1),
        "target_accuracy_met": test_metrics["accuracy"] >= 0.85,
        "base_weights": str(best_path),
        "learning_rate": lr,
    }
    if "classification_report" in test_metrics:
        (config.REPORTS_DIR / "classification_report.json").write_text(
            json.dumps(test_metrics["classification_report"], indent=2),
            encoding="utf-8",
        )
    (config.REPORTS_DIR / "metrics_summary.json").write_text(
        json.dumps(summary, indent=2),
        encoding="utf-8",
    )

    print("=" * 60)
    print(f"Val  accuracy : {val_metrics['accuracy']:.2%}")
    print(f"Test accuracy : {test_metrics['accuracy']:.2%}")
    print(f"TFLite        : {tflite_path}")
    print("Publier avec : python -c \"from moomoo_ml.fingerspell.train_job import publish_from_dataset_outputs; print(publish_from_dataset_outputs())\"")
    print("=" * 60)


if __name__ == "__main__":
    main()
