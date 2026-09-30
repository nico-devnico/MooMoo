"""Compose a landmark sequence from several sign media clips.

Used by text→sign: download each dictionary video/GIF temporarily, extract
MediaPipe Holistic landmarks, align signers in the frame, then blend across
signs so the LandmarkViewer plays one continuous gesture.
"""

from __future__ import annotations

import tempfile
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

import numpy as np

from .datasets.discovery import Sample, media_kind
from .preprocessing.extract import HolisticExtractor
from .preprocessing.features import (
    HAND_DIMS,
    HAND_POINTS,
    LEFT_SHOULDER,
    POSE_DIMS,
    POSE_POINTS,
    RIGHT_SHOULDER,
    Layout,
    trim_inactive,
)

DEFAULT_FPS = 15.0
# Soft cross-fade between consecutive signs (barely noticeable pause).
DEFAULT_BLEND_FRAMES = 6
DEFAULT_MAX_FRAMES = 160
_MAX_DOWNLOAD_BYTES = 25 * 1024 * 1024
_USER_AGENT = "MooMoo-ML/1.0 (+text-to-sign compose)"
# Shared torso anchor so consecutive signs don't jump sideways.
_TARGET_ANCHOR = np.array([0.50, 0.42], dtype=np.float32)


def _suffix_from_url(url: str, content_type: str | None) -> str:
    path = Path(urlparse(url).path)
    if path.suffix.lower() in {
        ".gif", ".mp4", ".webm", ".mov", ".avi", ".mkv", ".m4v",
        ".png", ".jpg", ".jpeg", ".webp",
    }:
        return path.suffix.lower()
    ct = (content_type or "").split(";")[0].strip().lower()
    return {
        "image/gif": ".gif",
        "video/mp4": ".mp4",
        "video/webm": ".webm",
        "video/quicktime": ".mov",
        "image/png": ".png",
        "image/jpeg": ".jpg",
        "image/webp": ".webp",
    }.get(ct, ".mp4")


def download_temp(url: str, *, timeout_s: float = 45) -> Path:
    """Download [url] to a NamedTemporaryFile; caller must delete it."""
    import urllib.request

    req = urllib.request.Request(url, headers={"User-Agent": _USER_AGENT})
    with urllib.request.urlopen(req, timeout=timeout_s) as resp:
        content_type = resp.headers.get("Content-Type")
        suffix = _suffix_from_url(url, content_type)
        data = resp.read(_MAX_DOWNLOAD_BYTES + 1)
    if len(data) > _MAX_DOWNLOAD_BYTES:
        raise ValueError(f"média trop volumineux (>{_MAX_DOWNLOAD_BYTES // (1024 * 1024)} Mo)")
    if not data:
        raise ValueError("média vide")
    tmp = tempfile.NamedTemporaryFile(prefix="moomoo_compose_", suffix=suffix, delete=False)
    try:
        tmp.write(data)
        tmp.flush()
    finally:
        tmp.close()
    return Path(tmp.name)


def _as_clips(payload: Any) -> list[dict]:
    if isinstance(payload, dict):
        raw = payload.get("clips") or payload.get("media") or payload.get("urls")
    else:
        raw = payload
    if not isinstance(raw, list) or not raw:
        raise ValueError("clips doit être une liste non vide de {word, url}")
    clips: list[dict] = []
    for item in raw:
        if isinstance(item, str):
            clips.append({"word": "", "url": item.strip()})
            continue
        if not isinstance(item, dict):
            continue
        url = (item.get("url") or item.get("video_url") or item.get("media_url") or "").strip()
        if not url:
            continue
        clips.append({
            "word": str(item.get("word") or item.get("label") or "").strip(),
            "url": url,
            "sign_id": item.get("sign_id") or item.get("id"),
        })
    if not clips:
        raise ValueError("aucune URL média exploitable")
    return clips


def _anchor_xy(frame: np.ndarray, layout: Layout) -> np.ndarray | None:
    """Mid-shoulder (x, y) when both shoulders are detected."""
    pose = frame[layout.pose].reshape(POSE_POINTS, POSE_DIMS)
    left = pose[LEFT_SHOULDER, :2]
    right = pose[RIGHT_SHOULDER, :2]
    if not (np.any(left) and np.any(right)):
        return None
    return ((left + right) * 0.5).astype(np.float32)


def _shift_xy(frame: np.ndarray, layout: Layout, delta: np.ndarray) -> np.ndarray:
    """Translate every detected landmark by [dx, dy] (zeros stay missing)."""
    out = frame.copy()
    dx, dy = float(delta[0]), float(delta[1])

    pose = out[layout.pose].reshape(POSE_POINTS, POSE_DIMS)
    for i in range(POSE_POINTS):
        if pose[i, 0] != 0 or pose[i, 1] != 0:
            pose[i, 0] += dx
            pose[i, 1] += dy
    out[layout.pose] = pose.reshape(-1)

    for hand_slice in (layout.left_hand, layout.right_hand):
        hand = out[hand_slice].reshape(HAND_POINTS, HAND_DIMS)
        for i in range(HAND_POINTS):
            if hand[i, 0] != 0 or hand[i, 1] != 0:
                hand[i, 0] += dx
                hand[i, 1] += dy
        out[hand_slice] = hand.reshape(-1)

    face_slice = layout.face
    if face_slice is not None:
        from .preprocessing.features import FACE_DIMS, FACE_POINTS

        face = out[face_slice].reshape(FACE_POINTS, FACE_DIMS)
        for i in range(FACE_POINTS):
            if face[i, 0] != 0 or face[i, 1] != 0:
                face[i, 0] += dx
                face[i, 1] += dy
        out[face_slice] = face.reshape(-1)
    return out


def align_sequence(seq: np.ndarray, layout: Layout, target: np.ndarray = _TARGET_ANCHOR) -> np.ndarray:
    """Shift the whole clip so its torso sits on a shared anchor."""
    anchor = None
    for frame in seq:
        anchor = _anchor_xy(frame, layout)
        if anchor is not None:
            break
    if anchor is None:
        return seq
    delta = target - anchor
    if float(np.linalg.norm(delta)) < 1e-4:
        return seq
    return np.stack([_shift_xy(f, layout, delta) for f in seq]).astype(np.float32)


def _smoothstep(t: float) -> float:
    return t * t * (3.0 - 2.0 * t)


def blend_transition(a: np.ndarray, b: np.ndarray, n: int) -> np.ndarray:
    """n intermediate frames morphing from [a] to [b] (endpoints excluded)."""
    if n <= 0:
        return np.zeros((0, a.shape[0]), dtype=np.float32)
    frames = []
    for i in range(1, n + 1):
        t = _smoothstep(i / (n + 1))
        # Keep missing parts (all zeros) as zeros instead of inventing ghosts.
        mask_a = a != 0
        mask_b = b != 0
        both = mask_a & mask_b
        only_a = mask_a & ~mask_b
        only_b = mask_b & ~mask_a
        out = np.zeros_like(a)
        out[both] = (1.0 - t) * a[both] + t * b[both]
        if t < 0.5:
            out[only_a] = a[only_a]
        else:
            out[only_b] = b[only_b]
        frames.append(out.astype(np.float32))
    return np.stack(frames)


def compose_landmarks(
    payload: dict | list,
    *,
    fps: float = DEFAULT_FPS,
    gap_frames: int | None = None,
    blend_frames: int | None = None,
    max_frames_per_clip: int = DEFAULT_MAX_FRAMES,
    include_face: bool = True,
) -> dict:
    """Download → extract → align → blend → concatenate."""
    clips = _as_clips(payload)
    layout = Layout(include_face=bool(include_face))
    extractor = HolisticExtractor(layout)
    # Prefer blend_frames; keep gap_frames as alias for older clients.
    n_blend = DEFAULT_BLEND_FRAMES
    if blend_frames is not None:
        n_blend = max(0, int(blend_frames))
    elif gap_frames is not None:
        n_blend = max(0, int(gap_frames))

    sequences: list[np.ndarray] = []
    segments: list[dict] = []
    missing: list[dict] = []

    try:
        for clip in clips:
            url = clip["url"]
            word = clip.get("word") or ""
            path: Path | None = None
            try:
                path = download_temp(url)
                kind = media_kind(path)
                if kind not in ("video", "gif", "image"):
                    raise ValueError(f"type média non supporté ({path.suffix})")
                sample = Sample(rel=path.name, kind=kind, files=[path], label=word or None)
                seq = extractor.extract(sample, max_frames=int(max_frames_per_clip))
                if seq.ndim != 2 or seq.shape[0] == 0 or not np.any(seq):
                    raise ValueError("aucun landmark détecté")
                if kind != "image":
                    seq = trim_inactive(seq, layout)
                if seq.shape[0] == 0:
                    raise ValueError("aucun landmark après nettoyage")
                seq = align_sequence(seq.astype(np.float32, copy=False), layout)
                sequences.append(seq)
                segments.append({
                    "word": word,
                    "sign_id": clip.get("sign_id"),
                    "url": url,
                    "frames": int(seq.shape[0]),
                })
            except Exception as exc:
                missing.append({
                    "word": word,
                    "sign_id": clip.get("sign_id"),
                    "url": url,
                    "reason": str(exc)[:240],
                })
            finally:
                if path is not None:
                    path.unlink(missing_ok=True)
    finally:
        extractor.close()

    if not sequences:
        return {
            "ok": False,
            "error": "no_landmarks",
            "detail": "Aucun geste extrait depuis les médias du dictionnaire.",
            "fps": float(fps),
            "frames": [],
            "segments": [],
            "missing": missing,
        }

    parts: list[np.ndarray] = []
    cursor = 0
    placed: list[dict] = []
    for i, seq in enumerate(sequences):
        if i > 0 and n_blend > 0:
            blend = blend_transition(sequences[i - 1][-1], seq[0], n_blend)
            if len(blend):
                parts.append(blend)
                cursor += int(blend.shape[0])
        start = cursor
        parts.append(seq)
        cursor += int(seq.shape[0])
        meta = dict(segments[i])
        meta["start_frame"] = start
        placed.append(meta)

    frames = np.concatenate(parts, axis=0)
    return {
        "ok": True,
        "fps": float(fps),
        "frames": frames.tolist(),
        "frame_count": int(frames.shape[0]),
        "feature_dim": int(frames.shape[1]),
        "segments": placed,
        "missing": missing,
        "layout": layout.describe(),
        "blend_frames": n_blend,
    }
