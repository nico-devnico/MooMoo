"""Tests du tampon d'épellation et du prédicteur ASL (si le modèle est présent)."""

from __future__ import annotations

from pathlib import Path

import pytest

from moomoo_ml.fingerspell.buffer import SpellingBuffer, StabilityGate
from moomoo_ml.fingerspell.predictor import FingerspellUnavailable, default_model_dir


def test_spelling_buffer_builds_phrase():
    buf = SpellingBuffer()
    buf.apply_raw("H")
    buf.apply_raw("I")
    buf.apply_raw("space")
    buf.apply_raw("A")
    assert buf.text == "HI A"
    buf.apply_raw("del")  # retire A → "HI "
    assert buf.text == "HI "
    buf.apply_raw("del")  # retire l'espace → "HI"
    assert buf.text == "HI"
    buf.apply_raw("del")  # retire I → "H"
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


def test_no_hand_emits_space_once():
    """Sans main → un seul espace, puis skip jusqu'au retour de la main."""
    model_dir = default_model_dir()
    if not (model_dir / "model.tflite").exists() and not (
        model_dir / "asl_lstm_mobile.tflite"
    ).exists():
        pytest.skip("modèle fingerspell absent")

    pytest.importorskip("tensorflow", reason="TensorFlow requis pour l'interpréteur TFLite")

    from moomoo_ml.fingerspell.service import classify_frame

    blank = b"\xff\xd8\xff\xd9"  # JPEG minimal (jamais décodé si hand_detected=False)
    r1 = classify_frame(
        blank,
        session_id="no-hand-session",
        reset=True,
        hand_detected=False,
        live=True,
    )
    assert r1["ok"]
    assert r1["label"] == "space"
    # Buffer vide → pas d'espace leading, mais l'événement est consommé.
    assert r1["committed"] is None
    assert r1["text"] == ""

    r2 = classify_frame(
        blank,
        session_id=r1["session_id"],
        hand_detected=False,
        live=True,
    )
    assert r2["committed"] is None
    assert r2["runtime"] == "skip"
    assert r2["text"] == r1["text"]

    # Main de nouveau → autorise un futur espace.
    holdout = (
        Path(__file__).resolve().parents[1]
        / "dataset"
        / "asl_alphabet_test"
        / "asl_alphabet_test"
        / "A_test.jpg"
    )
    if not holdout.exists():
        return
    r3 = classify_frame(
        holdout.read_bytes(),
        session_id=r1["session_id"],
        hand_detected=True,
        live=True,
        threshold=0.35,
        single_shot=True,
    )
    assert r3["ok"]
    # Force une lettre dans le buffer si le modèle n'a pas commit.
    if not (r3.get("text") or "").strip():
        from moomoo_ml.fingerspell.service import _store

        _, sess = _store.get(r1["session_id"])
        sess.buffer.apply_raw("A")
    r4 = classify_frame(
        blank,
        session_id=r1["session_id"],
        hand_detected=False,
        live=True,
    )
    assert r4["committed"] == "space"
    assert r4["text"].endswith(" ")
    from moomoo_ml.fingerspell.service import _store

    _, sess = _store.get(r1["session_id"])
    assert sess.buffer.chars and sess.buffer.chars[-1] == " "


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


def test_sample_jpeg_frames_from_synthetic_video(tmp_path):
    import cv2
    import numpy as np
    from moomoo_ml.fingerspell.video_frames import sample_jpeg_frames

    path = tmp_path / "clip.mp4"
    writer = cv2.VideoWriter(
        str(path),
        cv2.VideoWriter_fourcc(*"mp4v"),
        10.0,
        (160, 120),
    )
    for i in range(20):
        frame = np.full((120, 160, 3), 40 + i * 5, dtype=np.uint8)
        # Tache peau approximative au centre.
        frame[40:90, 50:110] = (180, 140, 110)
        writer.write(frame)
    writer.release()

    frames = sample_jpeg_frames(path.read_bytes(), filename="clip.mp4", max_frames=6)
    assert len(frames) >= 3
    # Chaque frame doit être un JPEG décodable.
    for blob in frames:
        arr = np.frombuffer(blob, dtype=np.uint8)
        img = cv2.imdecode(arr, cv2.IMREAD_COLOR)
        assert img is not None


def test_classify_media_video_assembles_letters(tmp_path):
    import cv2
    import numpy as np
    from moomoo_ml.fingerspell.predictor import default_model_dir
    from moomoo_ml.fingerspell.service import classify_media

    model_dir = default_model_dir()
    if not (model_dir / "model.tflite").exists() and not (
        model_dir / "asl_lstm_mobile.tflite"
    ).exists():
        pytest.skip("modèle fingerspell absent")

    holdout = (
        Path(__file__).resolve().parents[1]
        / "dataset"
        / "asl_alphabet_test"
        / "asl_alphabet_test"
        / "A_test.jpg"
    )
    if not holdout.exists():
        pytest.skip("image de test A absente")

    # Fabrique un mini « clip » en répétant l'image holdout comme frames JPEG
    # collées via VideoWriter (simulation flux caméra).
    img = cv2.imread(str(holdout))
    assert img is not None
    h, w = img.shape[:2]
    path = tmp_path / "a_sign.mp4"
    writer = cv2.VideoWriter(
        str(path),
        cv2.VideoWriter_fourcc(*"mp4v"),
        8.0,
        (w, h),
    )
    for _ in range(12):
        writer.write(img)
    writer.release()

    result = classify_media(
        path.read_bytes(),
        filename="a_sign.mp4",
        session_id="live-test",
        reset=True,
        threshold=0.35,
    )
    assert result["ok"]
    assert result.get("frames_scored", 0) >= 2
    assert result["label"].upper() == "A" or "A" in (result.get("text") or "")
