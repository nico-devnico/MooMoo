"""Inférence rapide + démo traduction lettre → texte (app mobile / prototype)."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path

os.environ.setdefault("TF_CPP_MIN_LOG_LEVEL", "2")

import numpy as np
import tensorflow as tf
from tensorflow import keras

import config


class SignLanguageTranslator:
    """Convertit des images de signes ASL en texte (lettres / commandes)."""

    def __init__(self, model_path: str | Path | None = None):
        path = Path(model_path) if model_path else config.MODELS_DIR / "best_asl_lstm.keras"
        if not path.exists():
            alt = config.MODELS_DIR / "asl_lstm_final.keras"
            if alt.exists():
                path = alt
            else:
                raise FileNotFoundError(f"Modèle introuvable : {path}")
        self.model = keras.models.load_model(path)
        labels_file = config.MODELS_DIR / "labels.json"
        if labels_file.exists():
            self.classes = json.loads(labels_file.read_text(encoding="utf-8"))
        else:
            self.classes = config.CLASSES
        self.text_buffer: list[str] = []

    def preprocess(self, image_path: str) -> np.ndarray:
        raw = tf.io.read_file(image_path)
        img = tf.io.decode_image(raw, channels=3, expand_animations=False)
        img = tf.image.convert_image_dtype(img, tf.float32)
        img = tf.image.resize(img, [config.IMG_SIZE, config.IMG_SIZE])
        return (img * 255.0).numpy()

    def predict(self, image_path: str, threshold: float = 0.5) -> dict:
        x = self.preprocess(image_path)
        probs = self.model.predict(np.expand_dims(x, 0), verbose=0)[0]
        idx = int(np.argmax(probs))
        conf = float(probs[idx])
        label = self.classes[idx]
        return {
            "label": label,
            "confidence": conf,
            "accepted": conf >= threshold,
            "top3": [
                {"label": self.classes[i], "confidence": float(probs[i])}
                for i in np.argsort(probs)[::-1][:3]
            ],
        }

    def update_text(self, prediction: dict) -> str:
        """Applique del / space / nothing / lettre au buffer texte."""
        if not prediction["accepted"]:
            return self.get_text()
        label = prediction["label"]
        if label == "nothing":
            return self.get_text()
        if label == "del":
            if self.text_buffer:
                self.text_buffer.pop()
        elif label == "space":
            self.text_buffer.append(" ")
        else:
            self.text_buffer.append(label)
        return self.get_text()

    def get_text(self) -> str:
        return "".join(self.text_buffer)

    def reset(self) -> None:
        self.text_buffer.clear()


def main() -> None:
    parser = argparse.ArgumentParser(description="Traduction ASL → texte")
    parser.add_argument("images", nargs="+", help="Une ou plusieurs images de signes")
    parser.add_argument("--model", default=None)
    parser.add_argument("--threshold", type=float, default=0.5)
    args = parser.parse_args()

    translator = SignLanguageTranslator(args.model)
    for img in args.images:
        pred = translator.predict(img, threshold=args.threshold)
        text = translator.update_text(pred)
        print(
            f"{Path(img).name:30s} -> {pred['label']:<8} "
            f"({pred['confidence']:.1%}) | texte: '{text}'"
        )
    print(f"\nTraduction finale : '{translator.get_text()}'")


if __name__ == "__main__":
    main()
