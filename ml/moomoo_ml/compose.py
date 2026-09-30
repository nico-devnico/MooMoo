"""Compose a landmark sequence from several sign media clips.

Used by text→sign: download each dictionary video/GIF temporarily, extract
MediaPipe Holistic landmarks, then concatenate them (with a short hold between
signs) into one playable sequence for the Flutter LandmarkViewer.
"""

from __future__ import annotations

import tempfile
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

import numpy as np

from .datasets.discovery import Sample, media_kind
from .preprocessing.extract import HolisticExtractor
from .preprocessing.features import Layout, trim_inactive

DEFAULT_FPS = 15.0
DEFAULT_GAP_FRAMES = 4
DEFAULT_MAX_FRAMES = 160
_MAX_DOWNLOAD_BYTES = 25 * 1024 * 1024
_USER_AGENT = "MooMoo-ML/1.0 (+text-to-sign compose)"


def _suffix_from_url(url: str, content_type: str | None) -> str:
    path = Path(urlparse(url).path)
    if path.suffix.lower() in {".gif", ".mp4", ".webm", ".mov", ".avi", ".mkv", ".m4v", ".png", ".jpg", ".jpeg", ".webp"}:
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


def compose_landmarks(
    payload: dict | list,
    *,
    fps: float = DEFAULT_FPS,
    gap_frames: int = DEFAULT_GAP_FRAMES,
    max_frames_per_clip: int = DEFAULT_MAX_FRAMES,
    include_face: bool = False,
) -> dict:
    """Download → extract → concatenate. Returns a SignLandmarks-compatible dict."""
    clips = _as_clips(payload)
    layout = Layout(include_face=bool(include_face))
    extractor = HolisticExtractor(layout)
    parts: list[np.ndarray] = []
    segments: list[dict] = []
    missing: list[dict] = []
    cursor = 0

    try:
        for i, clip in enumerate(clips):
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

                start = cursor
                parts.append(seq.astype(np.float32, copy=False))
                cursor += int(seq.shape[0])
                segments.append({
                    "word": word,
                    "sign_id": clip.get("sign_id"),
                    "url": url,
                    "start_frame": start,
                    "frames": int(seq.shape[0]),
                })

                # Hold the last pose briefly so consecutive signs don't slam together.
                if gap_frames > 0 and i < len(clips) - 1:
                    hold = np.stack([seq[-1]] * int(gap_frames))
                    parts.append(hold)
                    cursor += int(gap_frames)
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

    if not parts:
        return {
            "ok": False,
            "error": "no_landmarks",
            "detail": "Aucun geste extrait depuis les médias du dictionnaire.",
            "fps": float(fps),
            "frames": [],
            "segments": [],
            "missing": missing,
        }

    frames = np.concatenate(parts, axis=0)
    return {
        "ok": True,
        "fps": float(fps),
        "frames": frames.tolist(),
        "frame_count": int(frames.shape[0]),
        "feature_dim": int(frames.shape[1]),
        "segments": segments,
        "missing": missing,
        "layout": layout.describe(),
    }
