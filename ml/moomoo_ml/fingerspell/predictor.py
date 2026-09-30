"""Inférence rapide d'une lettre ASL à partir d'une image (TFLite prioritaire)."""

from __future__ import annotations

import json
import threading
import time
from pathlib import Path

import numpy as np

from .. import config

IMG_SIZE = 64


class FingerspellUnavailable(LookupError):
    pass


def default_model_dir() -> Path:
    """Cherche le modèle empaqueté, puis le dossier dataset/outputs."""
    bundled = config.ML_ROOT / "models" / "fingerspell"
    if (bundled / "model.tflite").exists() or (bundled / "labels.json").exists():
        return bundled
    legacy = config.PROJECT_ROOT / "dataset" / "outputs" / "models"
    return legacy


class FingerspellPredictor:
    """Charge une fois le TFLite (ou Keras) et classifie des images 64×64."""

    def __init__(self, model_dir: Path | None = None):
        self.model_dir = Path(model_dir) if model_dir else default_model_dir()
        labels_path = self.model_dir / "labels.json"
        if not labels_path.exists():
            raise FingerspellUnavailable(f"labels.json introuvable dans {self.model_dir}")
        self.labels: list[str] = json.loads(labels_path.read_text(encoding="utf-8"))

        tflite = self.model_dir / "model.tflite"
        if not tflite.exists():
            # Noms historiques du dossier dataset/
            alt = self.model_dir / "asl_lstm_mobile.tflite"
            tflite = alt if alt.exists() else tflite

        self._lock = threading.Lock()
        if tflite.exists():
            try:
                import tensorflow as tf

                self.interpreter = tf.lite.Interpreter(model_path=str(tflite), num_threads=2)
            except ImportError:
                from tflite_runtime.interpreter import Interpreter

                self.interpreter = Interpreter(model_path=str(tflite), num_threads=2)
            self.interpreter.allocate_tensors()
            self._inp = self.interpreter.get_input_details()[0]
            self._out = self.interpreter.get_output_details()[0]
            self.runtime = "tflite"
            self._keras = None
            self._tf = None
            try:
                import tensorflow as tf

                self._tf = tf
            except ImportError:
                self._tf = None
        else:
            from tensorflow import keras

            keras_path = self.model_dir / "best_asl_lstm.keras"
            if not keras_path.exists():
                keras_path = self.model_dir / "asl_lstm_final.keras"
            if not keras_path.exists():
                raise FingerspellUnavailable(f"Aucun modèle TFLite/Keras dans {self.model_dir}")
            self._keras = keras.models.load_model(keras_path)
            self.interpreter = None
            self.runtime = "keras"
            import tensorflow as tf

            self._tf = tf

    def preprocess_bytes(self, data: bytes) -> np.ndarray:
        """Décode JPEG/PNG → float32 [H,W,3] dans [0, 255] (comme l'entraînement)."""
        if self._tf is not None:
            tf = self._tf
            img = tf.io.decode_image(data, channels=3, expand_animations=False)
            img = tf.image.convert_image_dtype(img, tf.float32)
            img = tf.image.resize(img, [IMG_SIZE, IMG_SIZE])
            return (img * 255.0).numpy().astype(np.float32)

        # Sans TensorFlow : Pillow + numpy (TFLite-only).
        from io import BytesIO

        from PIL import Image

        img = Image.open(BytesIO(data)).convert("RGB").resize((IMG_SIZE, IMG_SIZE))
        return np.asarray(img, dtype=np.float32)

    def preprocess_array(self, rgb: np.ndarray) -> np.ndarray:
        """rgb uint8/float [H,W,3] → [64,64,3] float32 [0,255]."""
        if self._tf is not None:
            tf = self._tf
            t = tf.convert_to_tensor(rgb)
            if t.dtype != tf.float32:
                t = tf.image.convert_image_dtype(t, tf.float32)
            elif float(tf.reduce_max(t)) > 1.5:
                t = t / 255.0
            t = tf.image.resize(t, [IMG_SIZE, IMG_SIZE])
            return (t * 255.0).numpy().astype(np.float32)

        from PIL import Image

        arr = np.asarray(rgb)
        if arr.dtype != np.uint8:
            if arr.max() <= 1.5:
                arr = (arr * 255.0).astype(np.uint8)
            else:
                arr = arr.astype(np.uint8)
        img = Image.fromarray(arr).convert("RGB").resize((IMG_SIZE, IMG_SIZE))
        return np.asarray(img, dtype=np.float32)

    def predict(self, image: np.ndarray, top_k: int = 3) -> dict:
        """Classifie une image déjà prétraitée [64,64,3]."""
        x = image.astype(np.float32)
        if x.ndim == 3:
            batch = x[None]
        else:
            batch = x
        t0 = time.perf_counter()
        with self._lock:
            if self.runtime == "tflite":
                self.interpreter.set_tensor(self._inp["index"], batch)
                self.interpreter.invoke()
                probs = self.interpreter.get_tensor(self._out["index"])[0]
            else:
                probs = self._keras.predict(batch, verbose=0)[0]
        latency = (time.perf_counter() - t0) * 1000
        order = np.argsort(-probs)[:top_k]
        idx = int(order[0])
        return {
            "label": self.labels[idx],
            "confidence": float(probs[idx]),
            "top": [{"label": self.labels[int(i)], "confidence": float(probs[i])} for i in order],
            "latency_ms": round(latency, 2),
            "runtime": self.runtime,
        }

    def predict_bytes(self, data: bytes, top_k: int = 3) -> dict:
        return self.predict(self.preprocess_bytes(data), top_k=top_k)


_predictor: FingerspellPredictor | None = None
_predictor_lock = threading.Lock()


def get_predictor() -> FingerspellPredictor:
    global _predictor
    with _predictor_lock:
        if _predictor is None:
            _predictor = FingerspellPredictor()
        return _predictor
