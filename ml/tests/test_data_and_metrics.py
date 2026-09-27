import json

import numpy as np

from moomoo_ml.data import prepare
from moomoo_ml.evaluate import classification_metrics
from tests.conftest import make_sequence


def _write_index(folder, layout, per_class: dict[str, int], signers: int):
    entries = []
    k = 0
    for c, (label, n) in enumerate(per_class.items()):
        for i in range(n):
            name = f"s{k}.npy"
            np.save(folder / name, make_sequence(40 + i, layout, seed=k, class_shift=0.1 * c))
            entries.append({"rel": f"{label}/{i}", "file": name, "label": label,
                            "signer": f"signer-{i % signers}", "split_hint": None,
                            "frames": 40 + i, "hand_ratio": 1.0, "fingerprint": f"fp{k}"})
            k += 1
    summary = {"dir": str(folder), "layout": layout.describe(), "max_frames": 96}
    (folder / "index.json").write_text(json.dumps({"summary": summary, "samples": entries}))
    return summary


def test_prepare_builds_leak_free_tensors(tmp_path, layout):
    summary = _write_index(tmp_path, layout, {"a": 12, "b": 12, "c": 12, "rare": 1}, signers=6)
    data = prepare(summary, {"sequence_length": 30, "augmentation": {"enabled": False}}, seed=0)
    assert data.labels == ["a", "b", "c"]
    assert data.report["classes_dropped"] == ["rare"]
    assert data.input_shape == (30, 258)
    assert data.x_train.shape[1:] == (30, 258)
    assert data.report["split"]["signer_independent"] is True
    total = len(data.x_train) + len(data.x_val) + len(data.x_test)
    assert total == 36


def test_prepare_warns_when_augmenting_few_signers(tmp_path, layout):
    summary = _write_index(tmp_path, layout, {"a": 6, "b": 6}, signers=2)
    data = prepare(summary, {"augmentation": {"target_per_class": 10}}, seed=0)
    assert data.report["real_train_samples"] < len(data.x_train)
    assert any("signataires" in w for w in data.report["warnings"])


def test_classification_metrics_on_known_predictions():
    labels = ["a", "b", "c"]
    y = np.array([0, 0, 1, 1, 2, 2])
    probs = np.eye(3)[[0, 0, 1, 2, 2, 2]] * 0.8 + 0.2 / 3
    m = classification_metrics(y, probs, labels)
    assert m["accuracy"] == round(5 / 6, 4) or abs(m["accuracy"] - 5 / 6) < 1e-3
    assert m["confusion_matrix"] == [[2, 0, 0], [0, 1, 1], [0, 0, 2]]
    per = {p["label"]: p for p in m["per_class"]}
    assert per["b"]["recall"] == 0.5 and per["c"]["precision"] < 1
    assert 0 < m["macro_f1"] < 1
