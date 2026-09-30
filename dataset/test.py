"""Programme de test / évaluation du modèle ASL CNN-BiLSTM."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path

os.environ.setdefault("TF_CPP_MIN_LOG_LEVEL", "2")

import matplotlib.pyplot as plt
import numpy as np
import seaborn as sns
import tensorflow as tf
from sklearn.metrics import (
    accuracy_score,
    classification_report,
    confusion_matrix,
    top_k_accuracy_score,
)
from tensorflow import keras

import config
from data_loader import (
    collect_filepaths,
    load_holdout_test_images,
    make_dataset,
    stratified_splits,
)


def resolve_model(path: str | None) -> keras.Model:
    candidates = []
    if path:
        candidates.append(Path(path))
    candidates.extend(
        [
            config.MODELS_DIR / "best_asl_lstm.keras",
            config.MODELS_DIR / "asl_lstm_final.keras",
        ]
    )
    for p in candidates:
        if p.exists():
            print(f"Chargement modèle : {p}")
            return keras.models.load_model(p)
    raise FileNotFoundError(
        "Aucun modèle trouvé. Lancez d'abord : python train.py"
    )


def predict_dataset(model: keras.Model, ds: tf.data.Dataset):
    y_true, y_prob = [], []
    for bx, by in ds:
        y_prob.append(model.predict(bx, verbose=0))
        y_true.append(by.numpy())
    y_true = np.concatenate(y_true)
    y_prob = np.concatenate(y_prob)
    y_pred = np.argmax(y_prob, axis=1)
    return y_true, y_pred, y_prob


def save_confusion(y_true, y_pred, out: Path, title: str) -> None:
    cm = confusion_matrix(y_true, y_pred)
    fig, ax = plt.subplots(figsize=(14, 12))
    sns.heatmap(
        cm,
        cmap="Blues",
        xticklabels=config.CLASSES,
        yticklabels=config.CLASSES,
        ax=ax,
    )
    ax.set_title(title)
    ax.set_xlabel("Prédit")
    ax.set_ylabel("Réel")
    fig.tight_layout()
    out.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out, dpi=150, bbox_inches="tight")
    plt.close(fig)


def run_internal_test(model: keras.Model) -> dict:
    """Évalue sur le split test stratifié (issu du train)."""
    paths, labels = collect_filepaths()
    splits = stratified_splits(paths, labels)
    test_ds = make_dataset(*splits["test"], shuffle=False, augment=False)
    y_true, y_pred, y_prob = predict_dataset(model, test_ds)

    acc = float(accuracy_score(y_true, y_pred))
    top3 = float(
        top_k_accuracy_score(y_true, y_prob, k=3, labels=list(range(config.NUM_CLASSES)))
    )
    report = classification_report(
        y_true, y_pred, target_names=config.CLASSES, digits=4, zero_division=0
    )
    print("\n=== Split test interne ===")
    print(report)
    print(f"Accuracy : {acc:.2%} | Top-3 : {top3:.2%} | Echec : {1 - acc:.2%}")

    out = config.PLOTS_DIR / "test_confusion_internal.png"
    save_confusion(y_true, y_pred, out, f"Test interne - acc={acc:.2%}")
    return {"accuracy": acc, "top3_accuracy": top3, "failure_rate": 1 - acc, "n": len(y_true)}


def run_holdout_folder(model: keras.Model) -> dict:
    """Évalue le dossier officiel asl_alphabet_test (28 images)."""
    images, names, labels = load_holdout_test_images()
    probs = model.predict(images, verbose=0)
    preds = np.argmax(probs, axis=1)

    print("\n=== Holdout asl_alphabet_test ===")
    print(f"{'Fichier':<16} {'Attendu':<10} {'Prédit':<10} {'Confiance':>10} {'OK?'}")
    print("-" * 60)
    correct = 0
    evaluated = 0
    details = []
    for i, name in enumerate(names):
        pred_cls = config.IDX_TO_CLASS[int(preds[i])]
        conf = float(probs[i, preds[i]])
        expected = name
        ok = pred_cls == expected
        if labels[i] is not None:
            evaluated += 1
            correct += int(ok)
        mark = "OK" if ok else "FAIL"
        print(f"{name + '_test.jpg':<16} {expected:<10} {pred_cls:<10} {conf:>9.1%} {mark}")
        details.append(
            {
                "file": f"{name}_test.jpg",
                "expected": expected,
                "predicted": pred_cls,
                "confidence": round(conf, 4),
                "correct": ok,
            }
        )

    acc = correct / evaluated if evaluated else 0.0
    print(f"\nHoldout accuracy : {acc:.2%} ({correct}/{evaluated})")

    # Barres confiance
    fig, ax = plt.subplots(figsize=(12, 5))
    colors = ["#2a9d8f" if d["correct"] else "#e76f51" for d in details]
    ax.bar([d["expected"] for d in details], [d["confidence"] for d in details], color=colors)
    ax.set_ylim(0, 1.05)
    ax.set_title(f"Confiance holdout - accuracy {acc:.0%}")
    ax.set_ylabel("Confiance softmax")
    ax.set_xticks(range(len(details)))
    ax.set_xticklabels([d["expected"] for d in details], rotation=45, ha="right")
    fig.tight_layout()
    config.PLOTS_DIR.mkdir(parents=True, exist_ok=True)
    fig.savefig(config.PLOTS_DIR / "holdout_confidence.png", dpi=150)
    plt.close(fig)

    return {"accuracy": acc, "correct": correct, "n": evaluated, "details": details}


def predict_image(model: keras.Model, image_path: str, top_k: int = 5) -> None:
    raw = tf.io.read_file(image_path)
    img = tf.io.decode_image(raw, channels=3, expand_animations=False)
    img = tf.image.convert_image_dtype(img, tf.float32)
    img = tf.image.resize(img, [config.IMG_SIZE, config.IMG_SIZE])
    img = img * 255.0
    batch = tf.expand_dims(img, 0)
    probs = model.predict(batch, verbose=0)[0]
    top_idx = np.argsort(probs)[::-1][:top_k]
    print(f"\nImage : {image_path}")
    for rank, i in enumerate(top_idx, 1):
        print(f"  #{rank} {config.IDX_TO_CLASS[int(i)]:<10} {probs[i]:.2%}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Test du modèle ASL LSTM")
    parser.add_argument("--model", type=str, default=None, help="Chemin .keras")
    parser.add_argument("--image", type=str, default=None, help="Image unique à prédire")
    parser.add_argument("--skip-internal", action="store_true")
    parser.add_argument("--skip-holdout", action="store_true")
    args = parser.parse_args()

    model = resolve_model(args.model)

    if args.image:
        predict_image(model, args.image)
        return

    results = {}
    if not args.skip_internal:
        results["internal_test"] = run_internal_test(model)
    if not args.skip_holdout:
        results["holdout_test"] = run_holdout_folder(model)

    config.REPORTS_DIR.mkdir(parents=True, exist_ok=True)
    out = config.REPORTS_DIR / "test_results.json"
    # serialisable
    serialisable = json.loads(json.dumps(results))
    out.write_text(json.dumps(serialisable, indent=2), encoding="utf-8")
    print(f"\nResultats sauvegardes -> {out}")

    if "internal_test" in results:
        met = results["internal_test"]["accuracy"] >= 0.85
        print(
            f"Objectif precision >= 85% : "
            f"{'ATTEINT' if met else 'NON ATTEINT'} "
            f"({results['internal_test']['accuracy']:.2%})"
        )


if __name__ == "__main__":
    main()
