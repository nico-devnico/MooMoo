"""Tests du tampon d'épellation et du prédicteur ASL (si le modèle est présent)."""

from __future__ import annotations

from pathlib import Path

import pytest

from moomoo_ml.fingerspell.buffer import SpellingBuffer, StabilityGate
from moomoo_ml.fingerspell.predictor import FingerspellUnavailable, default_model_dir


def test_spelling_buffer_builds_phrase():
    buf = SpellingBuffer()
    # Bypass gate for unit checks.
    buf.apply_raw("H")
    buf.apply_raw("I")
    buf.apply_raw("space")
    buf.apply_raw("A")
    assert buf.text == "HI A"
    buf.apply_raw("del")
    assert buf.text == "HI"
    buf.apply_raw("del")
    buf.apply_raw("del")
    assert buf.text == "H"
    buf.apply_raw("nothing")
    assert buf.text == "H"


def test_stability_gate_requires_hold():
    gate = StabilityGate(min_hold=2, cooldown_s=0)
    assert gate.push("A", accepted=True) is None
    assert gate.push("A", accepted=True) == "A"
    # Same letter again without cooldown wait is blocked when cooldown > 0;
    # with cooldown_s=0 it can commit after another hold.
    assert gate.push("A", accepted=True) is None
    assert gate.push("A", accepted=True) == "A"


def test_update_ignores_low_confidence():
    buf = SpellingBuffer(gate=StabilityGate(min_hold=1, cooldown_s=0))
    out = buf.update("A", confidence=0.2, threshold=0.55)
    assert out["committed"] is None
    assert out["text"] == ""


def test_predictor_loads_and_classifies_holdout():
    model_dir = default_model_dir()
    tflite = model_dir / "model.tflite"
    if not tflite.exists() and not (model_dir / "asl_lstm_mobile.tflite").exists():
        pytest.skip("modèle fingerspell absent")

    pytest.importorskip("tensorflow", reason="TensorFlow requis pour l'interpréteur TFLite")

    from moomoo_ml.fingerspell.predictor import FingerspellPredictor

    pred = FingerspellPredictor(model_dir)
    assert len(pred.labels) == 29
    assert pred.runtime in ("tflite", "keras")

    # Image de test du jeu holdout si disponible (ml/dataset/…).
    holdout = (
        Path(__file__).resolve().parents[1]
        / "dataset"
        / "asl_alphabet_test"
        / "asl_alphabet_test"
        / "A_test.jpg"
    )
    if not holdout.exists():
        pytest.skip("image de test A absente")

    result = pred.predict_bytes(holdout.read_bytes())
    assert result["label"] == "A"
    assert result["confidence"] > 0.5
    assert result["latency_ms"] < 2000


def test_classify_frame_session_assembles_text():
    model_dir = default_model_dir()
    if not (model_dir / "model.tflite").exists() and not (
        model_dir / "asl_lstm_mobile.tflite"
    ).exists():
        pytest.skip("modèle fingerspell absent")

    pytest.importorskip("tensorflow", reason="TensorFlow requis pour l'interpréteur TFLite")

    holdout_dir = (
        Path(__file__).resolve().parents[1]
        / "dataset"
        / "asl_alphabet_test"
        / "asl_alphabet_test"
    )
    a_img = holdout_dir / "A_test.jpg"
    b_img = holdout_dir / "B_test.jpg"
    if not a_img.exists() or not b_img.exists():
        pytest.skip("images de test absentes")

    from moomoo_ml.fingerspell.service import classify_frame

    # min_hold=2 côté service : envoyer chaque lettre deux fois.
    r1 = classify_frame(a_img.read_bytes(), session_id="test-session", reset=True)
    r2 = classify_frame(a_img.read_bytes(), session_id=r1["session_id"])
    r3 = classify_frame(b_img.read_bytes(), session_id=r1["session_id"])
    r4 = classify_frame(b_img.read_bytes(), session_id=r1["session_id"])
    assert r1["ok"] and r4["ok"]
    assert "A" in (r2["text"] + r4["text"])
    assert r4["latency_ms"] < 2000


def test_unavailable_without_model(tmp_path):
    from moomoo_ml.fingerspell.predictor import FingerspellPredictor

    with pytest.raises(FingerspellUnavailable):
        FingerspellPredictor(tmp_path)


def test_candidate_crops_closeup_returns_variants():
    import numpy as np
    from moomoo_ml.fingerspell.preprocess import candidate_crops
    import cv2

    # Petit crop type dataset.
    rgb = np.full((180, 180, 3), 140, dtype=np.uint8)
    ok, buf = cv2.imencode(".jpg", cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR))
    assert ok
    crops = candidate_crops(buf.tobytes())
    assert len(crops) >= 1
    assert all(c.rgb.ndim == 3 for c in crops)


def test_candidate_crops_fullframe_produces_several():
    import numpy as np
    from moomoo_ml.fingerspell.preprocess import candidate_crops
    import cv2

    rgb = np.full((720, 1280, 3), 80, dtype=np.uint8)
    # Tache peau au centre.
    rgb[280:480, 540:740] = (200, 160, 130)
    ok, buf = cv2.imencode(".jpg", cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR))
    assert ok
    crops = candidate_crops(buf.tobytes())
    assert len(crops) >= 2


def test_train_job_status_idle():
    from moomoo_ml.fingerspell import train_job

    st = train_job.status()
    assert st["status"] in ("idle", "running", "succeeded", "failed")
