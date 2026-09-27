"""Feature vector layout and pure-numpy sequence operations.

One frame = [pose 33 x (x, y, z, visibility) | left hand 21 x (x, y, z) |
right hand 21 x (x, y, z) | optional face 468 x (x, y, z)], i.e. 258 values,
or 1662 with the face. A missing body part is all zeros.
"""

from __future__ import annotations

from dataclasses import dataclass

import numpy as np

POSE_POINTS, POSE_DIMS = 33, 4
HAND_POINTS, HAND_DIMS = 21, 3
FACE_POINTS, FACE_DIMS = 468, 3

POSE_SIZE = POSE_POINTS * POSE_DIMS
HAND_SIZE = HAND_POINTS * HAND_DIMS
FACE_SIZE = FACE_POINTS * FACE_DIMS

LEFT_SHOULDER, RIGHT_SHOULDER = 11, 12


@dataclass(frozen=True)
class Layout:
    include_face: bool = False

    @property
    def size(self) -> int:
        return POSE_SIZE + 2 * HAND_SIZE + (FACE_SIZE if self.include_face else 0)

    @property
    def pose(self) -> slice:
        return slice(0, POSE_SIZE)

    @property
    def left_hand(self) -> slice:
        return slice(POSE_SIZE, POSE_SIZE + HAND_SIZE)

    @property
    def right_hand(self) -> slice:
        return slice(POSE_SIZE + HAND_SIZE, POSE_SIZE + 2 * HAND_SIZE)

    @property
    def face(self) -> slice | None:
        if not self.include_face:
            return None
        start = POSE_SIZE + 2 * HAND_SIZE
        return slice(start, start + FACE_SIZE)

    def blocks(self) -> list[tuple[slice, int]]:
        """(slice, dims per point) of every body part."""
        out = [(self.pose, POSE_DIMS), (self.left_hand, HAND_DIMS), (self.right_hand, HAND_DIMS)]
        if self.include_face:
            out.append((self.face, FACE_DIMS))
        return out

    def describe(self) -> dict:
        return {
            "feature_dim": self.size,
            "include_face": self.include_face,
            "parts": {
                "pose": [self.pose.start, self.pose.stop, POSE_DIMS],
                "left_hand": [self.left_hand.start, self.left_hand.stop, HAND_DIMS],
                "right_hand": [self.right_hand.start, self.right_hand.stop, HAND_DIMS],
                **({"face": [self.face.start, self.face.stop, FACE_DIMS]} if self.include_face else {}),
            },
        }


def hands_present(seq: np.ndarray, layout: Layout) -> np.ndarray:
    """Boolean per frame: at least one hand detected."""
    lh = np.any(seq[:, layout.left_hand] != 0, axis=1)
    rh = np.any(seq[:, layout.right_hand] != 0, axis=1)
    return lh | rh


def trim_inactive(seq: np.ndarray, layout: Layout) -> np.ndarray:
    """Drops leading/trailing frames without any hand; keeps at least one frame."""
    active = np.where(hands_present(seq, layout))[0]
    if active.size == 0:
        return seq
    return seq[active[0]: active[-1] + 1]


def fill_missing(seq: np.ndarray, layout: Layout, max_gap: int = 4) -> np.ndarray:
    """Fills short detection drop-outs of each part by linear interpolation.

    Longer gaps stay at zero: a hand really leaving the frame is information.
    """
    out = seq.copy()
    for part, _ in layout.blocks():
        present = np.any(seq[:, part] != 0, axis=1)
        idx = np.where(present)[0]
        if idx.size < 2:
            continue
        for a, b in zip(idx[:-1], idx[1:]):
            gap = b - a - 1
            if 0 < gap <= max_gap:
                for k in range(1, gap + 1):
                    t = k / (gap + 1)
                    out[a + k, part] = (1 - t) * seq[a, part] + t * seq[b, part]
    return out


def resample(seq: np.ndarray, length: int, layout: Layout | None = None) -> np.ndarray:
    """Linear temporal resampling to exactly [length, F].

    With a [layout], a part missing on one side of an interpolation step is
    taken from the nearest frame instead of being blended towards zero.
    """
    seq = np.asarray(seq, dtype=np.float32)
    n = len(seq)
    if n == length:
        return seq.copy()
    if n == 1:
        return np.repeat(seq, length, axis=0)
    src = np.linspace(0.0, n - 1, num=length)
    lo = np.floor(src).astype(int)
    hi = np.minimum(lo + 1, n - 1)
    w = (src - lo)[:, None].astype(np.float32)
    out = (1 - w) * seq[lo] + w * seq[hi]
    if layout is not None:
        nearest = np.where(w[:, 0] < 0.5, lo, hi)
        for part, _ in layout.blocks():
            both = np.any(seq[lo][:, part] != 0, axis=1) & np.any(seq[hi][:, part] != 0, axis=1)
            out[~both, part] = seq[nearest[~both], part]
    return out.astype(np.float32)


def normalize(seq: np.ndarray, layout: Layout) -> np.ndarray:
    """Translation/scale invariance: origin between the shoulders, unit = shoulder width.

    Applied per frame to x, y, z of detected points only; visibility is kept.
    """
    out = seq.astype(np.float32, copy=True)
    pose = out[:, layout.pose].reshape(len(out), POSE_POINTS, POSE_DIMS)
    ls, rs = pose[:, LEFT_SHOULDER, :3], pose[:, RIGHT_SHOULDER, :3]
    has_shoulders = np.any(ls != 0, axis=1) & np.any(rs != 0, axis=1)
    if not has_shoulders.any():
        return out
    center = (ls + rs) / 2
    scale = np.linalg.norm((ls - rs)[:, :2], axis=1)
    # Frames without shoulders reuse the sequence's median reference.
    med_center = np.median(center[has_shoulders], axis=0)
    med_scale = float(np.median(scale[has_shoulders])) or 1.0
    center[~has_shoulders] = med_center
    scale = np.where(has_shoulders & (scale > 1e-6), scale, med_scale)

    for part, dims in layout.blocks():
        block = out[:, part].reshape(len(out), -1, dims)
        present = np.any(block != 0, axis=2)
        coords = (block[:, :, :3] - center[:, None, :]) / scale[:, None, None]
        block[:, :, :3] = np.where(present[:, :, None], coords, 0.0)
        out[:, part] = block.reshape(len(out), -1)
    return out


def to_model_input(seq: np.ndarray, layout: Layout, length: int, *,
                   do_normalize: bool = True, do_trim: bool = True) -> np.ndarray:
    """Raw extracted sequence -> model input [length, F]. Shared by training and inference."""
    seq = np.asarray(seq, dtype=np.float32)
    if seq.ndim != 2 or seq.shape[1] != layout.size:
        raise ValueError(f"expected [n, {layout.size}] landmarks, got {list(seq.shape)}")
    if do_trim:
        seq = trim_inactive(seq, layout)
    seq = fill_missing(seq, layout)
    if do_normalize:
        seq = normalize(seq, layout)
    return resample(seq, length, layout)
