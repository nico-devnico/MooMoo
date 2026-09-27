"""Keras -> TensorFlow Lite conversion, quantization and on-CPU verification."""

from __future__ import annotations

import time
from pathlib import Path

import numpy as np

from .evaluate import classification_metrics

QUANTIZATIONS = ("none", "dynamic", "float16")


def convert(model, input_shape: tuple[int, int], out_path: Path, quantization: str = "dynamic") -> dict:
    import tensorflow as tf

    if quantization not in QUANTIZATIONS:
        raise ValueError(f"quantization inconnue (attendu : {', '.join(QUANTIZATIONS)})")

    @tf.function(input_signature=[tf.TensorSpec([1, *input_shape], tf.float32, name="landmarks")])
    def serve(x):
        return model(x, training=False)

    concrete = serve.get_concrete_function()

    def make(select_ops: bool):
        conv = tf.lite.TFLiteConverter.from_concrete_functions([concrete], model)
        if quantization in ("dynamic", "float16"):
            conv.optimizations = [tf.lite.Optimize.DEFAULT]
        if quantization == "float16":
            conv.target_spec.supported_types = [tf.float16]
        if select_ops:
            conv.target_spec.supported_ops = [
                tf.lite.OpsSet.TFLITE_BUILTINS,
                tf.lite.OpsSet.SELECT_TF_OPS,
            ]
            conv._experimental_lower_tensor_list_ops = False
        return conv.convert()

    # Builtin ops only first: that is what runs on stock TFLite on Android/iOS.
    try:
        blob = make(select_ops=False)
        builtin_only = True
        note = None
    except Exception as exc:
        blob = make(select_ops=True)
        builtin_only = False
        note = f"Opérateurs TF (Flex) requis : {str(exc).splitlines()[0][:200]}"

    out_path.write_bytes(blob)
    return {
        "path": str(out_path),
        "quantization": quantization,
        "size_bytes": len(blob),
        "builtin_ops_only": builtin_only,
        "mobile_compatible": builtin_only,
        "requires_flex_delegate": not builtin_only,
        "note": note,
        "input_shape": [1, *input_shape],
    }


class TFLitePredictor:
    def __init__(self, path: Path):
        import tensorflow as tf

        self.interpreter = tf.lite.Interpreter(model_path=str(path), num_threads=2)
        self.interpreter.allocate_tensors()
        self.inp = self.interpreter.get_input_details()[0]
        self.out = self.interpreter.get_output_details()[0]

    def predict_one(self, seq: np.ndarray) -> np.ndarray:
        self.interpreter.set_tensor(self.inp["index"], seq[None].astype(np.float32))
        self.interpreter.invoke()
        return self.interpreter.get_tensor(self.out["index"])[0]

    def predict(self, batch: np.ndarray) -> np.ndarray:
        return np.stack([self.predict_one(s) for s in batch])


def benchmark(path: Path, x: np.ndarray, y: np.ndarray, labels: list[str],
              keras_probs: np.ndarray | None = None, max_samples: int = 500) -> dict:
    predictor = TFLitePredictor(path)
    x, y = x[:max_samples], y[:max_samples]
    if len(x) == 0:
        return {"samples": 0}
    predictor.predict_one(x[0])  # warm-up
    latencies, probs = [], []
    for seq in x:
        t0 = time.perf_counter()
        probs.append(predictor.predict_one(seq))
        latencies.append((time.perf_counter() - t0) * 1000)
    probs = np.stack(probs)
    metrics = classification_metrics(y, probs, labels)
    report = {
        "samples": int(len(x)),
        "accuracy": metrics["accuracy"],
        "macro_f1": metrics["macro_f1"],
        "latency_ms_mean": float(np.mean(latencies)),
        "latency_ms_p95": float(np.percentile(latencies, 95)),
        "size_bytes": path.stat().st_size,
    }
    if keras_probs is not None and len(keras_probs) >= len(x):
        report["agreement_with_keras"] = float(
            np.mean(keras_probs[: len(x)].argmax(1) == probs.argmax(1))
        )
    return report
