"""Controlled landmark augmentation, applied to the training split only.

Each transform produces a plausible variation of a real performance (speed,
missing frames, camera angle and distance, sensor jitter). Plain copies are
never added: an augmented sample always differs from its source.
"""

from __future__ import annotations

from collections import Counter
from dataclasses import dataclass

import numpy as np

from .preprocessing.features import Layout, resample

DEFAULTS = {
    "enabled": True,
    "target_per_class": 30,
    "max_factor": 5,
    "time_warp": 0.2,
    "frame_drop": 0.1,
    "rotation_deg": 10.0,
    "scale": 0.1,
    "translation": 0.05,
    "noise_std": 0.01,
}


@dataclass
class AugmentConfig:
    enabled: bool = True
    target_per_class: int = 30
    max_factor: int = 5
    time_warp: float = 0.2
    frame_drop: float = 0.1
    rotation_deg: float = 10.0
    scale: float = 0.1
    translation: float = 0.05
    noise_std: float = 0.01

    @classmethod
    def from_dict(cls, d: dict | None) -> "AugmentConfig":
        merged = {**DEFAULTS, **(d or {})}
        return cls(**{k: merged[k] for k in DEFAULTS})


def _present_mask(seq: np.ndarray, layout: Layout) -> list[tuple[slice, int, np.ndarray]]:
    out = []
    for part, dims in layout.blocks():
        block = seq[:, part].reshape(len(seq), -1, dims)
        out.append((part, dims, np.any(block != 0, axis=2)))
    return out


def speed_variation(seq: np.ndarray, rng: np.random.Generator, amount: float, layout: Layout) -> np.ndarray:
    """Plays the sign faster or slower, then brings it back to the same length."""
    t = len(seq)
    factor = rng.uniform(1 - amount, 1 + amount)
    stretched = resample(seq, max(2, int(round(t * factor))), layout)
    return resample(stretched, t, layout)


def time_shift(seq: np.ndarray, rng: np.random.Generator, amount: float, layout: Layout) -> np.ndarray:
    """Crops a little at the start or end (temporal variation), then resamples."""
    t = len(seq)
    max_crop = max(1, int(t * amount / 2))
    a = int(rng.integers(0, max_crop + 1))
    b = t - int(rng.integers(0, max_crop + 1))
    if b - a < 2:
        return seq.copy()
    return resample(seq[a:b], t, layout)


def frame_dropping(seq: np.ndarray, rng: np.random.Generator, rate: float, layout: Layout) -> np.ndarray:
    """Removes random frames and interpolates over the holes."""
    t = len(seq)
    keep = rng.random(t) >= rate
    keep[0] = keep[-1] = True
    if keep.sum() < 2:
        return seq.copy()
    return resample(seq[keep], t, layout)


def spatial(seq: np.ndarray, rng: np.random.Generator, cfg: AugmentConfig, layout: Layout) -> np.ndarray:
    """Small in-plane rotation, zoom and shift of every detected point (x, y)."""
    out = seq.copy()
    theta = np.deg2rad(rng.uniform(-cfg.rotation_deg, cfg.rotation_deg))
    s = rng.uniform(1 - cfg.scale, 1 + cfg.scale)
    shift = rng.uniform(-cfg.translation, cfg.translation, size=2)
    rot = np.array([[np.cos(theta), -np.sin(theta)], [np.sin(theta), np.cos(theta)]], dtype=np.float32)
    for part, dims, present in _present_mask(seq, layout):
        block = out[:, part].reshape(len(out), -1, dims)
        xy = block[:, :, :2]
        center = xy[present].mean(axis=0) if present.any() else np.zeros(2, dtype=np.float32)
        moved = (xy - center) @ rot.T * s + center + shift
        block[:, :, :2] = np.where(present[:, :, None], moved, 0.0)
        if dims >= 3:
            block[:, :, 2] = np.where(present, block[:, :, 2] * s, 0.0)
        out[:, part] = block.reshape(len(out), -1)
    return out


def jitter(seq: np.ndarray, rng: np.random.Generator, std: float, layout: Layout) -> np.ndarray:
    """Light Gaussian noise on detected coordinates only (not on visibility)."""
    out = seq.copy()
    for part, dims, present in _present_mask(seq, layout):
        block = out[:, part].reshape(len(out), -1, dims)
        noise = rng.normal(0, std, size=block[:, :, :3].shape).astype(np.float32)
        block[:, :, :3] = np.where(present[:, :, None], block[:, :, :3] + noise, 0.0)
        out[:, part] = block.reshape(len(out), -1)
    return out


def augment_once(seq: np.ndarray, rng: np.random.Generator, cfg: AugmentConfig, layout: Layout) -> np.ndarray:
    out = seq
    if cfg.time_warp > 0:
        out = speed_variation(out, rng, cfg.time_warp, layout)
        if rng.random() < 0.5:
            out = time_shift(out, rng, cfg.time_warp, layout)
    if cfg.frame_drop > 0 and rng.random() < 0.5:
        out = frame_dropping(out, rng, cfg.frame_drop, layout)
    out = spatial(out, rng, cfg, layout)
    if cfg.noise_std > 0:
        out = jitter(out, rng, cfg.noise_std, layout)
    return out.astype(np.float32)


def augment_training_set(x: np.ndarray, y: np.ndarray, cfg: AugmentConfig, layout: Layout,
                         seed: int = 42) -> tuple[np.ndarray, np.ndarray, dict]:
    """Tops up classes below [target_per_class], capped at max_factor x real samples."""
    if not cfg.enabled or len(x) == 0:
        return x, y, {"enabled": False, "added": 0}
    rng = np.random.default_rng(seed)
    counts = Counter(y.tolist())
    new_x, new_y, added = [], [], {}
    for label, n_real in counts.items():
        target = min(cfg.target_per_class, n_real * cfg.max_factor)
        missing = max(0, target - n_real)
        if missing == 0:
            continue
        idx = np.where(y == label)[0]
        for k in range(missing):
            src = x[idx[k % len(idx)]]
            new_x.append(augment_once(src, rng, cfg, layout))
            new_y.append(label)
        added[int(label)] = missing
    if not new_x:
        return x, y, {"enabled": True, "added": 0, "per_class": {}}
    return (
        np.concatenate([x, np.stack(new_x)]),
        np.concatenate([y, np.array(new_y, dtype=y.dtype)]),
        {"enabled": True, "added": len(new_x), "per_class": added},
    )
