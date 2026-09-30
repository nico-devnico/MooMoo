"""Inférence rapide d'une lettre ASL à partir d'une image (TFLite prioritaire)."""

from __future__ import annotations

import json
import threading
import time
from pathlib import Path

import numpy as np

from . import registry

IMG_SIZE = registry.IMG_SIZE


class FingerspellUnavailable(LookupError):
    pass


def default_model_dir() -> Path:
    """Dossier de la version active (registre), avec repli sur dataset/outputs."""
    try:
        folder = registry.active_dir()
        if (folder / "model.tflite").exists() or (folder / "labels.json").exists():
            return folder
    except Exception:
        pass
    legacy = registry.DATASET_OUTPUTS
    if legacy.exists():
        return legacy
    return registry.MODELS_ROOT


class FingerspellPredictor:
    """Charge une fois le TFLite (ou Keras) et classifie des images 64×64."""

    def __init__(self, model_dir: Path | None = None):
        self.model_dir = Path(model_dir) if model_dir else default_model_dir()
        labels_path = self.model_dir / "labels.json"
        if not labels_path.exists():
            raise FingerspellUnavailable(f"labels.json introuvable dans {self.model_dir}")
        self.labels: list[str] = json.loads(labels_path.read_text(encoding="utf-8"))
        self.version_id = self.model_dir.name if self.model_dir.parent.name == "versions" else "default"

        tflite = self.model_dir / "model.tflite"
        if not tflite.exists():
            alt = self.model_dir / "asl_lstm_mobile.tflite"
            tflite = alt if alt.exists() else tflite

        self._lock = threading.Lock()
        if tflite.exists():
            try:
                import tensorflow as tf

                self.interpreter = tf.lite.Interpreter(model_path=str(tflite), num_threads=2)
                self._tf = tf
            except ImportError:
                from tflite_runtime.interpreter import Interpreter

                self.interpreter = Interpreter(model_path=str(tflite), num_threads=2)
                self._tf = None
            self.interpreter.allocate_tensors()
            self._inp = self.interpreter.get_input_details()[0]
            self._out = self.interpreter.get_output_details()[0]
            self.runtime = "tflite"
            self._keras = None
        else:
            from tensorflow import keras
            import tensorflow as tf

            keras_path = self.model_dir / "best_asl_lstm.keras"
            if not keras_path.exists():
                keras_path = self.model_dir / "asl_lstm_final.keras"
            if not keras_path.exists():
                raise FingerspellUnavailable(f"Aucun modèle TFLite/Keras dans {self.model_dir}")
            self._keras = keras.models.load_model(keras_path)
            self.interpreter = None
            self.runtime = "keras"
            self._tf = tf

    def _resize_to_model(self, rgb_u8: np.ndarray) -> np.ndarray:
        """RGB uint8 quelconque → float32 [IMG_SIZE, IMG_SIZE, 3] dans [0, 255]."""
        if self._tf is not None:
            tf = self._tf
            t = tf.convert_to_tensor(rgb_u8)
            t = tf.image.convert_image_dtype(t, tf.float32)
            if float(tf.reduce_max(t)) > 1.5:
                t = t / 255.0
            t = tf.image.resize(t, [IMG_SIZE, IMG_SIZE])
            return (t * 255.0).numpy().astype(np.float32)

        from PIL import Image

        arr = np.asarray(rgb_u8)
        if arr.dtype != np.uint8:
            if arr.max() <= 1.5:
                arr = (arr * 255.0).astype(np.uint8)
            else:
                arr = np.clip(arr, 0, 255).astype(np.uint8)
        img = Image.fromarray(arr).convert("RGB").resize((IMG_SIZE, IMG_SIZE))
        return np.asarray(img, dtype=np.float32)

    def preprocess_bytes(self, data: bytes) -> tuple[np.ndarray, bool]:
        """Décode + crop main + luminosité dataset → tenseur modèle.

        Retourne (image, hand_detected). Le preview UI n'est pas touché.
        """
        from .preprocess import prepare_hand_image

        crop = prepare_hand_image(data)
        return self._resize_to_model(crop.rgb), crop.detected

    def preprocess_array(self, rgb: np.ndarray) -> np.ndarray:
        return self._resize_to_model(rgb)

    def predict(self, image: np.ndarray, top_k: int = 3, *, hand_detected: bool = True) -> dict:
        x = image.astype(np.float32)
        batch = x[None] if x.ndim == 3 else x
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
        label = self.labels[idx]
        confidence = float(probs[idx])
        # Sans main claire : n'engage pas de lettre (évite le bruit de fond).
        if not hand_detected:
            nothing_idx = next((i for i, l in enumerate(self.labels) if l == "nothing"), None)
            if nothing_idx is not None:
                label = "nothing"
                confidence = float(probs[nothing_idx])
            else:
                confidence = min(confidence, 0.2)
        return {
            "label": label,
            "confidence": confidence,
            "top": [{"label": self.labels[int(i)], "confidence": float(probs[i])} for i in order],
            "latency_ms": round(latency, 2),
            "runtime": self.runtime,
            "model_id": self.version_id,
            "hand_detected": hand_detected,
        }

    def predict_bytes(self, data: bytes, top_k: int = 3) -> dict:
        image, hand_detected = self.preprocess_bytes(data)
        return self.predict(image, top_k=top_k, hand_detected=hand_detected)

    def warmup(self) -> float:
        """Prédit une image noire pour charger les kernels TF (évite le timeout du 1er appel)."""
        blank = np.zeros((IMG_SIZE, IMG_SIZE, 3), dtype=np.float32)
        return float(self.predict(blank)["latency_ms"])


_predictor: FingerspellPredictor | None = None
_predictor_lock = threading.Lock()


def get_predictor(*, force_reload: bool = False) -> FingerspellPredictor:
    global _predictor
    with _predictor_lock:
        if force_reload or _predictor is None:
            registry.ensure_layout()
            _predictor = FingerspellPredictor()
        return _predictor


def reload_predictor() -> FingerspellPredictor:
    return get_predictor(force_reload=True)
