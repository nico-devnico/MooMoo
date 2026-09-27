import numpy as np
import pytest

from moomoo_ml.preprocessing.features import (
    Layout, fill_missing, hands_present, normalize, resample, to_model_input, trim_inactive,
)
from tests.conftest import make_sequence


def test_layout_sizes():
    assert Layout().size == 258
    assert Layout(include_face=True).size == 1662
    parts = Layout().describe()["parts"]
    assert parts["pose"] == [0, 132, 4]
    assert parts["right_hand"][1] == 258


@pytest.mark.parametrize("frames", [1, 7, 30, 95])
def test_resample_exact_length(layout, frames):
    seq = make_sequence(frames, layout)
    out = resample(seq, 30, layout)
    assert out.shape == (30, layout.size)
    assert out.dtype == np.float32


def test_resample_does_not_blend_missing_hand_towards_zero(layout):
    seq = make_sequence(10, layout)
    seq[5:, layout.left_hand] = 0
    out = resample(seq, 37, layout)
    lh = out[:, layout.left_hand]
    present = np.any(lh != 0, axis=1)
    # Every present frame keeps full-magnitude coordinates (no half-blended values).
    assert np.all(np.abs(lh[present]).max(axis=1) > 0.3)


def test_trim_inactive_and_hands_present(layout):
    seq = make_sequence(20, layout)
    seq[:4, layout.left_hand] = 0
    seq[:4, layout.right_hand] = 0
    seq[-3:, layout.left_hand] = 0
    seq[-3:, layout.right_hand] = 0
    assert hands_present(seq, layout).sum() == 13
    assert len(trim_inactive(seq, layout)) == 13


def test_fill_missing_short_gap_only(layout):
    seq = make_sequence(20, layout)
    seq[5:7, layout.right_hand] = 0      # gap 2 -> filled
    seq[10:17, layout.left_hand] = 0     # gap 7 -> kept (hand really gone)
    out = fill_missing(seq, layout, max_gap=4)
    assert np.all(np.any(out[5:7, layout.right_hand] != 0, axis=1))
    assert not np.any(out[10:17, layout.left_hand])


def test_normalize_is_translation_and_scale_invariant(layout):
    seq = make_sequence(12, layout)
    moved = seq.copy()
    for part, dims in layout.blocks():
        block = moved[:, part].reshape(len(moved), -1, dims)
        present = np.any(block != 0, axis=2)
        block[:, :, :2] = np.where(present[:, :, None], block[:, :, :2] * 2.0 + 0.1, 0)
        moved[:, part] = block.reshape(len(moved), -1)
    a, b = normalize(seq, layout), normalize(moved, layout)
    np.testing.assert_allclose(a[:, layout.left_hand][:, 0::3], b[:, layout.left_hand][:, 0::3], atol=1e-4)


def test_to_model_input_rejects_wrong_width(layout):
    with pytest.raises(ValueError):
        to_model_input(np.zeros((10, 100)), layout, 30)
    assert to_model_input(make_sequence(50, layout), layout, 30).shape == (30, 258)
