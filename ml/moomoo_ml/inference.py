"""Serving of the production model of each language."""

from __future__ import annotations

import json
import threading
import time
from pathlib import Path

import numpy as np

from . import artifacts, db
from .preprocessing.features import Layout, to_model_input


class NoProductionModel(LookupError):
    pass


class LoadedModel:
    def __init__(self, row: dict):
        exp = db.get_experiment(row["experiment_id"]) if row.get("experiment_id") else None
        if not exp:
            raise NoProductionModel("Le modèle en production n'a pas d'artefacts.")
        folder = artifacts.experiment_dir(exp["language_code"], exp["code"])
        self.row = row
        self.labels: list[str] = json.loads((folder / "labels.json").read_text(encoding="utf-8"))
        prep = json.loads((folder / "preprocessing.json").read_text(encoding="utf-8"))
        self.layout = Layout(include_face=bool(prep["layout"]["include_face"]))
        self.length = int(prep["sequence_length"])
        self.normalize = bool(prep.get("normalize", True))
        self.max_frames = prep.get("max_frames") or 96
        tflite = folder / "model.tflite"
        if tflite.exists():
            from .tflite_export import TFLitePredictor

            predictor = TFLitePredictor(tflite)
            self._predict = predictor.predict_one
            self.runtime = "tflite"
        else:
            from tensorflow import keras

            model = keras.models.load_model(folder / "model.keras")
            self._predict = lambda seq: model.predict(seq[None], verbose=0)[0]
            self.runtime = "keras"

    def classify(self, raw_landmarks: np.ndarray, top_k: int = 3) -> dict:
        seq = to_model_input(raw_landmarks, self.layout, self.length, do_normalize=self.normalize)
        t0 = time.perf_counter()
        probs = self._predict(seq)
        latency = (time.perf_counter() - t0) * 1000
        order = np.argsort(-probs)[:top_k]
        return {
            "label": self.labels[int(order[0])],
            "confidence": float(probs[order[0]]),
            "top": [{"label": self.labels[int(i)], "confidence": float(probs[i])} for i in order],
            "latency_ms": round(latency, 2),
            "runtime": self.runtime,
        }


class ModelCache:
    """Reloads a language's model when the production row changes."""

    def __init__(self, ttl_s: float = 30):
        self.ttl_s = ttl_s
        self._lock = threading.Lock()
        self._models: dict[str, tuple[float, LoadedModel]] = {}

    def get(self, language: str | None) -> LoadedModel:
        key = language or "*"
        with self._lock:
            cached = self._models.get(key)
            if cached and time.monotonic() - cached[0] < self.ttl_s:
                return cached[1]
            row = db.production_model(language)
            if not row:
                self._models.pop(key, None)
                raise NoProductionModel(
                    f"Aucun modèle en production pour {language or 'aucune langue'}."
                )
            if cached and cached[1].row["id"] == row["id"]:
                self._models[key] = (time.monotonic(), cached[1])
                return cached[1]
            model = LoadedModel(row)
            self._models[key] = (time.monotonic(), model)
            return model


def landmarks_from_media(path: Path, kind: str, layout: Layout, max_frames: int) -> np.ndarray:
    from .datasets.discovery import Sample
    from .preprocessing.extract import HolisticExtractor

    extractor = HolisticExtractor(layout)
    try:
        return extractor.extract(Sample(rel=path.name, kind=kind, files=[path]), max_frames)
    finally:
        extractor.close()
