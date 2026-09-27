"""Classification metrics computed on real predictions."""

from __future__ import annotations

import time
from typing import Callable

import numpy as np
from sklearn.metrics import (
    accuracy_score,
    confusion_matrix,
    precision_recall_fscore_support,
)


def classification_metrics(y_true: np.ndarray, probs: np.ndarray, labels: list[str]) -> dict:
    y_pred = probs.argmax(axis=1)
    idx = list(range(len(labels)))
    p_w, r_w, f_w, _ = precision_recall_fscore_support(
        y_true, y_pred, labels=idx, average="weighted", zero_division=0
    )
    p_m, r_m, f_m, _ = precision_recall_fscore_support(
        y_true, y_pred, labels=idx, average="macro", zero_division=0
    )
    p_c, r_c, f_c, s_c = precision_recall_fscore_support(
        y_true, y_pred, labels=idx, average=None, zero_division=0
    )
    k = min(3, len(labels))
    topk = np.argsort(-probs, axis=1)[:, :k]
    top3 = float(np.mean([t in row for t, row in zip(y_true, topk)])) if len(y_true) else None
    return {
        "samples": int(len(y_true)),
        "accuracy": float(accuracy_score(y_true, y_pred)) if len(y_true) else None,
        "precision": float(p_w),
        "recall": float(r_w),
        "f1": float(f_w),
        "macro_precision": float(p_m),
        "macro_recall": float(r_m),
        "macro_f1": float(f_m),
        "top3_accuracy": top3,
        "per_class": [
            {"label": labels[i], "precision": float(p_c[i]), "recall": float(r_c[i]),
             "f1": float(f_c[i]), "support": int(s_c[i])}
            for i in idx
        ],
        "confusion_matrix": confusion_matrix(y_true, y_pred, labels=idx).tolist(),
    }


def evaluate_split(predict: Callable[[np.ndarray], np.ndarray], x: np.ndarray, y: np.ndarray,
                   labels: list[str], batch_size: int = 64) -> dict | None:
    if len(x) == 0:
        return None
    t0 = time.perf_counter()
    probs = np.concatenate([predict(x[i:i + batch_size]) for i in range(0, len(x), batch_size)])
    elapsed = time.perf_counter() - t0
    metrics = classification_metrics(y, probs, labels)
    metrics["latency_ms_per_sample"] = elapsed / len(x) * 1000
    return metrics


def keras_predictor(model) -> Callable[[np.ndarray], np.ndarray]:
    return lambda batch: model.predict(batch, verbose=0)
