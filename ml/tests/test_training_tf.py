"""End-to-end LSTM training, resume and TFLite export on small generated tensors.

Skipped when TensorFlow is not installed. The tensors only exercise the code
path; nothing is written to the database or the model registry.
"""

import numpy as np
import pytest

tf = pytest.importorskip("tensorflow")

from moomoo_ml.data import PreparedData  # noqa: E402
from moomoo_ml.evaluate import evaluate_split, keras_predictor  # noqa: E402
from moomoo_ml.model import architecture_summary, build_model, merge_config  # noqa: E402
from moomoo_ml.tflite_export import benchmark, convert  # noqa: E402
from moomoo_ml.train import load_best, train_experiment  # noqa: E402
from tests.conftest import make_sequence  # noqa: E402


def _data(layout, per_class=8, length=30) -> PreparedData:
    xs, ys = [], []
    for c in range(3):
        for i in range(per_class):
            xs.append(make_sequence(length, layout, seed=c * 100 + i, class_shift=0.15 * c))
            ys.append(c)
    x, y = np.stack(xs).astype(np.float32), np.array(ys, dtype=np.int32)
    idx = np.random.default_rng(0).permutation(len(x))
    x, y = x[idx], y[idx]
    return PreparedData(x[:16], y[:16], x[16:20], y[16:20], x[20:], y[20:],
                        labels=["a", "b", "c"], layout=layout, sequence_length=length,
                        preprocessing={})


def test_default_architecture_shapes(layout):
    cfg = merge_config(None)
    model = build_model(cfg, (30, layout.size), 5)
    lstm = [l for l in model.layers if isinstance(l, tf.keras.layers.LSTM)]
    assert [l.units for l in lstm] == [128, 256, 128]
    assert model.output_shape == (None, 5)
    summary = architecture_summary(cfg, (30, layout.size), 5)
    assert summary["layers"][0] == {"type": "Input", "shape": [30, layout.size]}
    assert summary["text"].startswith("Input([30, 258]) -> LSTM(128) -> LSTM(256) -> LSTM(128)")


def test_train_resume_evaluate_and_export(tmp_path, layout):
    data = _data(layout)
    cfg = merge_config({"lstm_units": [16], "batch_size": 8, "epochs": 4,
                        "early_stopping_patience": 10, "reduce_lr_patience": 2})
    seen = []
    first = train_experiment(data, cfg, tmp_path, target_epochs=2,
                             on_epoch=lambda e, logs, lr, d: seen.append((e, lr)))
    assert first["epochs_done"] == 2 and [e for e, _ in seen] == [1, 2]
    assert (tmp_path / "last.keras").exists() and (tmp_path / "state.json").exists()

    resumed = train_experiment(data, cfg, tmp_path, target_epochs=4,
                               on_epoch=lambda e, logs, lr, d: seen.append((e, lr)))
    assert resumed["epochs_done"] == 4
    assert [e for e, _ in seen] == [1, 2, 3, 4], "resume continues, it does not restart"
    assert len(resumed["history"]) == 4

    model = load_best(tmp_path)
    metrics = evaluate_split(keras_predictor(model), data.x_test, data.y_test, data.labels)
    assert len(metrics["confusion_matrix"]) == 3

    report = convert(model, data.input_shape, tmp_path / "model.tflite", "dynamic")
    assert report["size_bytes"] > 0
    bench = benchmark(tmp_path / "model.tflite", data.x_test, data.y_test, data.labels,
                      keras_probs=model.predict(data.x_test, verbose=0))
    assert bench["samples"] == len(data.x_test)
    assert bench["latency_ms_mean"] > 0
    assert bench["agreement_with_keras"] >= 0.75


def test_cancellation_stops_after_current_epoch(tmp_path, layout):
    data = _data(layout)
    cfg = merge_config({"lstm_units": [8], "batch_size": 8})
    out = train_experiment(data, cfg, tmp_path, target_epochs=10, should_stop=lambda: True)
    assert out["cancelled"] is True and out["epochs_done"] == 1
