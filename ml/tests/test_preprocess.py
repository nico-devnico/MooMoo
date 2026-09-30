"""Tests détection main + normalisation luminosité."""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pytest

from moomoo_ml.fingerspell.preprocess import (
    TARGET_MEAN,
    match_training_brightness,
    prepare_hand_image,
)


def test_brightness_matches_training_mean():
    dark = np.full((64, 64, 3), 40, dtype=np.uint8)
    out = match_training_brightness(dark)
    assert abs(float(out.mean()) - TARGET_MEAN) < 12


def test_prepare_holdout_keeps_letter_a():
    holdout = (
        Path(__file__).resolve().parents[1]
        / "dataset"
        / "asl_alphabet_test"
        / "asl_alphabet_test"
        / "A_test.jpg"
    )
    if not holdout.exists():
        pytest.skip("image holdout absente")
    crop = prepare_hand_image(holdout.read_bytes())
    assert crop.rgb.ndim == 3
    assert crop.rgb.shape[0] == crop.rgb.shape[1]
    assert abs(float(crop.rgb.mean()) - TARGET_MEAN) < 20
    assert crop.detected is True
