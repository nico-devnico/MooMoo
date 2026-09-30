"""Entraînement du modèle CNN-BiLSTM ASL avec monitoring anti sur/sous-apprentissage."""

from __future__ import annotations

import json
import os
from datetime import datetime

# Réduire le bruit TensorFlow
os.environ.setdefault("TF_CPP_MIN_LOG_LEVEL", "2")

import matplotlib.pyplot as plt
import numpy as np
import seaborn as sns
import tensorflow as tf
from sklearn.metrics import (
    classification_report,
    confusion_matrix,
    accuracy_score,
    top_k_accuracy_score,
)
from tensorflow import keras

import config
from data_loader import collect_filepaths, make_dataset, stratified_splits
from model import build_asl_lstm_model, compile_model


def ensure_dirs() -> None:
    for d in (config.OUTPUT_DIR, config.MODELS_DIR, config.PLOTS_DIR, config.REPORTS_DIR):
        d.mkdir(parents=True, exist_ok=True)


def build_callbacks() -> list[keras.callbacks.Callback]:
    ckpt_path = config.MODELS_DIR / "best_asl_lstm.keras"
    return [
        keras.callbacks.ModelCheckpoint(
            filepath=str(ckpt_path),
            monitor="val_accuracy",
            mode="max",
            save_best_only=True,
            verbose=1,
        ),
        keras.callbacks.EarlyStopping(
            monitor="val_loss",
            patience=config.EARLY_STOP_PATIENCE,
            restore_best_weights=True,
            verbose=1,
        ),
        keras.callbacks.ReduceLROnPlateau(
            monitor="val_loss",
            factor=config.REDUCE_LR_FACTOR,
            patience=config.REDUCE_LR_PATIENCE,
            min_lr=config.MIN_LEARNING_RATE,
            verbose=1,
        ),
        keras.callbacks.CSVLogger(str(config.REPORTS_DIR / "training_log.csv")),
    ]


def plot_history(history: keras.callbacks.History) -> None:
    """Courbes loss / accuracy / top-3 / learning rate."""
    h = history.history
    epochs = range(1, len(h["loss"]) + 1)
    sns.set_theme(style="whitegrid")

    fig, axes = plt.subplots(2, 2, figsize=(12, 9))
    fig.suptitle("Entraînement ASL CNN-BiLSTM", fontsize=14, fontweight="bold")

    # Loss
    axes[0, 0].plot(epochs, h["loss"], label="Train", linewidth=2)
    axes[0, 0].plot(epochs, h["val_loss"], label="Validation", linewidth=2)
    axes[0, 0].set_title("Loss (surveillance sur/sous-apprentissage)")
    axes[0, 0].set_xlabel("Époque")
    axes[0, 0].set_ylabel("Loss")
    axes[0, 0].legend()

    # Accuracy
    axes[0, 1].plot(epochs, h["accuracy"], label="Train", linewidth=2)
    axes[0, 1].plot(epochs, h["val_accuracy"], label="Validation", linewidth=2)
    axes[0, 1].axhline(0.85, color="green", linestyle="--", label="Objectif 85%")
    axes[0, 1].set_title("Précision")
    axes[0, 1].set_xlabel("Époque")
    axes[0, 1].set_ylabel("Accuracy")
    axes[0, 1].legend()

    # Top-3
    if "top3_acc" in h:
        axes[1, 0].plot(epochs, h["top3_acc"], label="Train Top-3", linewidth=2)
        axes[1, 0].plot(epochs, h["val_top3_acc"], label="Val Top-3", linewidth=2)
        axes[1, 0].set_title("Top-3 Accuracy")
        axes[1, 0].set_xlabel("Époque")
        axes[1, 0].set_ylabel("Top-3 Acc")
        axes[1, 0].legend()
    else:
        axes[1, 0].axis("off")

    # Gap train/val = indicateur overfitting
    gap = np.array(h["accuracy"]) - np.array(h["val_accuracy"])
    axes[1, 1].plot(epochs, gap, color="crimson", linewidth=2, label="Train - Val Acc")
    axes[1, 1].axhline(0.05, color="orange", linestyle="--", label="Seuil écart 5%")
    axes[1, 1].set_title("Écart Train/Val (overfitting)")
    axes[1, 1].set_xlabel("Époque")
    axes[1, 1].set_ylabel("Écart accuracy")
    axes[1, 1].legend()

    fig.tight_layout()
    out = config.PLOTS_DIR / "training_curves.png"
    fig.savefig(out, dpi=150, bbox_inches="tight")
    plt.close(fig)
    print(f"[OK] Graphiques entrainement -> {out}")

    # Learning rate si présent
    if "lr" in h:
        fig2, ax = plt.subplots(figsize=(8, 4))
        ax.plot(epochs, h["lr"], marker="o")
        ax.set_yscale("log")
        ax.set_title("Learning Rate Schedule")
        ax.set_xlabel("Époque")
        ax.set_ylabel("LR")
        fig2.tight_layout()
        fig2.savefig(config.PLOTS_DIR / "learning_rate.png", dpi=150)
        plt.close(fig2)


def plot_confusion(y_true: np.ndarray, y_pred: np.ndarray, title: str, filename: str) -> None:
    cm = confusion_matrix(y_true, y_pred)
    fig, ax = plt.subplots(figsize=(14, 12))
    sns.heatmap(
        cm,
        annot=False,
        cmap="Blues",
        xticklabels=config.CLASSES,
        yticklabels=config.CLASSES,
        ax=ax,
        cbar_kws={"label": "Count"},
    )
    ax.set_title(title)
    ax.set_xlabel("Prédit")
    ax.set_ylabel("Réel")
    fig.tight_layout()
    path = config.PLOTS_DIR / filename
    fig.savefig(path, dpi=150, bbox_inches="tight")
    plt.close(fig)
    print(f"[OK] Matrice de confusion -> {path}")


def plot_per_class_metrics(y_true: np.ndarray, y_pred: np.ndarray) -> dict:
    report = classification_report(
        y_true,
        y_pred,
        target_names=config.CLASSES,
        output_dict=True,
        zero_division=0,
    )
    recalls = [report[c]["recall"] for c in config.CLASSES]
    precisions = [report[c]["precision"] for c in config.CLASSES]
    f1s = [report[c]["f1-score"] for c in config.CLASSES]
    fail_rates = [1.0 - r for r in recalls]

    x = np.arange(len(config.CLASSES))
    width = 0.35
    fig, ax = plt.subplots(figsize=(16, 6))
    ax.bar(x - width / 2, precisions, width, label="Précision", color="#2a9d8f")
    ax.bar(x + width / 2, recalls, width, label="Rappel", color="#264653")
    ax.axhline(0.85, color="green", linestyle="--", label="Seuil 85%")
    ax.set_xticks(x)
    ax.set_xticklabels(config.CLASSES, rotation=45, ha="right")
    ax.set_ylim(0, 1.05)
    ax.set_title("Précision & Rappel par classe")
    ax.legend()
    fig.tight_layout()
    fig.savefig(config.PLOTS_DIR / "per_class_precision_recall.png", dpi=150)
    plt.close(fig)

    fig2, ax2 = plt.subplots(figsize=(16, 5))
    colors = ["#e76f51" if f > 0.15 else "#e9c46a" if f > 0.05 else "#2a9d8f" for f in fail_rates]
    ax2.bar(config.CLASSES, fail_rates, color=colors)
    ax2.set_title("Taux d'echec (1 - rappel) par classe")
    ax2.set_ylabel("Taux d'échec")
    ax2.set_xticklabels(config.CLASSES, rotation=45, ha="right")
    fig2.tight_layout()
    fig2.savefig(config.PLOTS_DIR / "failure_rate.png", dpi=150)
    plt.close(fig2)

    fig3, ax3 = plt.subplots(figsize=(16, 5))
    ax3.bar(config.CLASSES, f1s, color="#457b9d")
    ax3.axhline(0.85, color="green", linestyle="--")
    ax3.set_title("F1-score par classe")
    ax3.set_xticklabels(config.CLASSES, rotation=45, ha="right")
    ax3.set_ylim(0, 1.05)
    fig3.tight_layout()
    fig3.savefig(config.PLOTS_DIR / "f1_per_class.png", dpi=150)
    plt.close(fig3)

    print(f"[OK] Metriques par classe -> {config.PLOTS_DIR}")
    return report


def evaluate_split(
    model: keras.Model,
    ds: tf.data.Dataset,
    split_name: str,
) -> dict:
    y_true, y_prob = [], []
    for batch_x, batch_y in ds:
        probs = model.predict(batch_x, verbose=0)
        y_prob.append(probs)
        y_true.append(batch_y.numpy())
    y_true = np.concatenate(y_true)
    y_prob = np.concatenate(y_prob)
    y_pred = np.argmax(y_prob, axis=1)

    acc = float(accuracy_score(y_true, y_pred))
    top3 = float(top_k_accuracy_score(y_true, y_prob, k=3, labels=list(range(config.NUM_CLASSES))))
    fail = 1.0 - acc

    plot_confusion(
        y_true,
        y_pred,
        title=f"Matrice de confusion - {split_name} (acc={acc:.2%})",
        filename=f"confusion_{split_name}.png",
    )
    report = plot_per_class_metrics(y_true, y_pred) if split_name == "test" else None

    metrics = {
        "split": split_name,
        "accuracy": acc,
        "top3_accuracy": top3,
        "failure_rate": fail,
        "n_samples": int(len(y_true)),
    }
    if report is not None:
        metrics["classification_report"] = report

    print(
        f"[{split_name.upper()}] accuracy={acc:.2%} | top3={top3:.2%} | "
                f"echec={fail:.2%} | n={len(y_true)}"
    )
    return metrics


def main() -> None:
    ensure_dirs()
    tf.keras.utils.set_random_seed(config.RANDOM_SEED)

    print("=" * 60)
    print("ASL Sign Language -> Text | CNN-BiLSTM Training")
    print("=" * 60)
    print(f"Input        : {config.INPUT_SHAPE}")
    print(f"Classes      : {config.NUM_CLASSES}")
    print(f"Max/classe   : {config.MAX_PER_CLASS}")
    print(f"Batch / Epochs: {config.BATCH_SIZE} / {config.EPOCHS}")

    paths, labels = collect_filepaths()
    splits = stratified_splits(paths, labels)
    for name, (p, y) in splits.items():
        print(f"  {name:5s}: {len(p):6d} images")

    train_ds = make_dataset(*splits["train"], shuffle=True, augment=True)
    val_ds = make_dataset(*splits["val"], shuffle=False, augment=False)
    test_ds = make_dataset(*splits["test"], shuffle=False, augment=False)

    model = compile_model(build_asl_lstm_model())
    model.summary()

    # Log LR dans history (compatible Keras 3)
    class LRLogger(keras.callbacks.Callback):
        def on_epoch_end(self, epoch, logs=None):
            logs = logs or {}
            lr = self.model.optimizer.learning_rate
            logs["lr"] = float(lr.numpy() if hasattr(lr, "numpy") else lr)

    history = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=config.EPOCHS,
        callbacks=build_callbacks() + [LRLogger()],
        verbose=1,
    )

    plot_history(history)

    # Recharger meilleurs poids
    best_path = config.MODELS_DIR / "best_asl_lstm.keras"
    if best_path.exists():
        model = keras.models.load_model(best_path)

    val_metrics = evaluate_split(model, val_ds, "val")
    test_metrics = evaluate_split(model, test_ds, "test")

    # Sauvegardes finales
    final_path = config.MODELS_DIR / "asl_lstm_final.keras"
    model.save(final_path)

    # Export TFLite mobile
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    # LSTM nécessite SELECT_TF_OPS parfois
    converter.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS,
        tf.lite.OpsSet.SELECT_TF_OPS,
    ]
    converter._experimental_lower_tensor_list_ops = False
    tflite_model = converter.convert()
    tflite_path = config.MODELS_DIR / "asl_lstm_mobile.tflite"
    tflite_path.write_bytes(tflite_model)
    print(f"[OK] Modele TFLite mobile -> {tflite_path} ({tflite_path.stat().st_size / 1024:.1f} KB)")

    # Labels
    labels_path = config.MODELS_DIR / "labels.json"
    labels_path.write_text(json.dumps(config.CLASSES, indent=2), encoding="utf-8")

    summary = {
        "timestamp": datetime.now().isoformat(timespec="seconds"),
        "architecture": "CNN-BiLSTM",
        "input_shape": list(config.INPUT_SHAPE),
        "num_classes": config.NUM_CLASSES,
        "max_per_class": config.MAX_PER_CLASS,
        "epochs_ran": len(history.history["loss"]),
        "best_val_accuracy": float(max(history.history["val_accuracy"])),
        "val": val_metrics,
        "test": {k: v for k, v in test_metrics.items() if k != "classification_report"},
        "model_keras": str(final_path),
        "model_tflite": str(tflite_path),
        "tflite_size_kb": round(tflite_path.stat().st_size / 1024, 1),
        "target_accuracy_met": test_metrics["accuracy"] >= 0.85,
    }
    report_path = config.REPORTS_DIR / "metrics_summary.json"
    # classification_report séparé (lourd)
    if "classification_report" in test_metrics:
        (config.REPORTS_DIR / "classification_report.json").write_text(
            json.dumps(test_metrics["classification_report"], indent=2),
            encoding="utf-8",
        )
    report_path.write_text(json.dumps(summary, indent=2), encoding="utf-8")

    print("=" * 60)
    print(f"Val  accuracy : {val_metrics['accuracy']:.2%}")
    print(f"Test accuracy : {test_metrics['accuracy']:.2%}")
    print(f"Test failure  : {test_metrics['failure_rate']:.2%}")
    print(f"Objectif >=85% : {'OUI' if summary['target_accuracy_met'] else 'NON'}")
    print(f"Rapport       : {report_path}")
    print("=" * 60)


if __name__ == "__main__":
    main()
