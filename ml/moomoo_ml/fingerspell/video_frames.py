"""Échantillonnage de frames JPEG depuis un clip vidéo / GIF (flux caméra live)."""

from __future__ import annotations

import tempfile
from pathlib import Path

VIDEO_SUFFIXES = {".mp4", ".webm", ".mov", ".avi", ".mkv", ".m4v", ".gif"}


def is_video_filename(filename: str | None) -> bool:
    if not filename:
        return False
    return Path(filename).suffix.lower() in VIDEO_SUFFIXES


def sample_jpeg_frames(
    data: bytes,
    *,
    filename: str = "clip.mp4",
    max_frames: int = 10,
) -> list[bytes]:
    """Décode un clip et renvoie jusqu'à [max_frames] JPEG RGB centrés dans le temps.

    Utilisé pour l'épellation temps réel sur un flux vidéo appareil
    (enregistrements courts successifs), sans dépendre d'un modèle motion.
    """
    if not data:
        return []
    suffix = Path(filename).suffix.lower() or ".mp4"
    if suffix not in VIDEO_SUFFIXES:
        suffix = ".mp4"

    import cv2
    import numpy as np

    frames: list[bytes] = []
    with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
        tmp.write(data)
        path = Path(tmp.name)
    try:
        # GIF : OpenCV lit souvent mal ; PIL + JPEG.
        if suffix == ".gif":
            from PIL import Image, ImageSequence

            with Image.open(path) as im:
                seq = list(ImageSequence.Iterator(im))
            if not seq:
                return []
            indices = _keep_indices(len(seq), max_frames)
            for i in indices:
                rgb = np.asarray(seq[i].convert("RGB"))
                ok, buf = cv2.imencode(".jpg", cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR), [int(cv2.IMWRITE_JPEG_QUALITY), 88])
                if ok:
                    frames.append(buf.tobytes())
            return frames

        cap = cv2.VideoCapture(str(path))
        try:
            total = int(cap.get(cv2.CAP_PROP_FRAME_COUNT) or 0)
            keep = _keep_indices(total, max_frames) if total > 0 else None
            i = 0
            while True:
                ok, bgr = cap.read()
                if not ok:
                    break
                take = (i in keep) if keep is not None else (i % 3 == 0)
                if take:
                    ok2, buf = cv2.imencode(
                        ".jpg",
                        bgr,
                        [int(cv2.IMWRITE_JPEG_QUALITY), 88],
                    )
                    if ok2:
                        frames.append(buf.tobytes())
                        if len(frames) >= max_frames:
                            break
                i += 1
        finally:
            cap.release()
    finally:
        path.unlink(missing_ok=True)

    return frames


def _keep_indices(total: int, max_frames: int) -> set[int]:
    if total <= 0:
        return set()
    if total <= max_frames:
        return set(range(total))
    # Répartition uniforme, en évitant les toutes premières frames (exposition).
    start = max(0, min(2, total // 10))
    usable = total - start
    step = usable / max_frames
    return {min(total - 1, start + int(step * i + step / 2)) for i in range(max_frames)}
