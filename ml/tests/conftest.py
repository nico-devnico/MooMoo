import sys
from pathlib import Path

import numpy as np
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from moomoo_ml.preprocessing.features import Layout  # noqa: E402


def make_sequence(frames: int, layout: Layout, *, seed: int = 0, hands: bool = True,
                  class_shift: float = 0.0) -> np.ndarray:
    """Plausible landmark sequence: shoulders, moving hands, zeros elsewhere."""
    rng = np.random.default_rng(seed)
    seq = np.zeros((frames, layout.size), dtype=np.float32)
    t = np.linspace(0, 1, frames)
    pose = seq[:, layout.pose].reshape(frames, 33, 4)
    pose[:, :, 0] = 0.5 + rng.normal(0, 0.01, (frames, 33))
    pose[:, :, 1] = 0.5 + rng.normal(0, 0.01, (frames, 33))
    pose[:, :, 3] = 0.9
    pose[:, 11, :2] = [0.6, 0.4]
    pose[:, 12, :2] = [0.4, 0.4]
    seq[:, layout.pose] = pose.reshape(frames, -1)
    if hands:
        for part, sign in ((layout.left_hand, 1), (layout.right_hand, -1)):
            hand = np.zeros((frames, 21, 3), dtype=np.float32)
            hand[:, :, 0] = 0.5 + sign * (0.1 + class_shift) * np.sin(2 * np.pi * t)[:, None]
            hand[:, :, 1] = 0.6 + class_shift * t[:, None]
            hand += rng.normal(0, 0.005, hand.shape).astype(np.float32)
            seq[:, part] = hand.reshape(frames, -1)
    return seq


@pytest.fixture
def layout() -> Layout:
    return Layout(include_face=False)
