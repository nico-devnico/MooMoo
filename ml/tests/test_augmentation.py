import numpy as np

from moomoo_ml.augmentation import AugmentConfig, augment_once, augment_training_set
from tests.conftest import make_sequence


def test_augmented_sequence_keeps_shape_and_missing_parts(layout):
    seq = make_sequence(30, layout)
    seq[:, layout.left_hand] = 0
    out = augment_once(seq, np.random.default_rng(0), AugmentConfig.from_dict(None), layout)
    assert out.shape == seq.shape
    assert not np.any(out[:, layout.left_hand]), "an absent hand must stay absent"
    assert not np.allclose(out, seq), "augmentation must change the sequence"


def test_top_up_is_capped_and_never_touches_real_samples(layout):
    x = np.stack([make_sequence(30, layout, seed=i) for i in range(6)])
    y = np.array([0, 0, 0, 0, 0, 1], dtype=np.int32)
    cfg = AugmentConfig.from_dict({"target_per_class": 10, "max_factor": 3})
    x2, y2, report = augment_training_set(x, y, cfg, layout, seed=0)
    np.testing.assert_array_equal(x2[:6], x)
    assert (y2 == 0).sum() == 10
    assert (y2 == 1).sum() == 3  # capped at 3 x the single real sample
    assert report["added"] == 7


def test_disabled_augmentation_is_a_no_op(layout):
    x = np.stack([make_sequence(30, layout, seed=i) for i in range(3)])
    y = np.array([0, 1, 1], dtype=np.int32)
    x2, y2, report = augment_training_set(x, y, AugmentConfig.from_dict({"enabled": False}), layout)
    assert x2 is x and y2 is y and report["added"] == 0
