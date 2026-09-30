"""Sessions d'épellation côté serveur (optionnel) + classification d'une frame."""

from __future__ import annotations

import threading
import time
import uuid
from dataclasses import dataclass, field

from .buffer import SpellingBuffer
from .predictor import FingerspellUnavailable, get_predictor


@dataclass
class _Session:
    buffer: SpellingBuffer = field(default_factory=SpellingBuffer)
    touched: float = field(default_factory=time.monotonic)


class SpellSessionStore:
    """Tampons par session_id, expirés après [ttl_s] d'inactivité."""

    def __init__(self, ttl_s: float = 300):
        self.ttl_s = ttl_s
        self._lock = threading.Lock()
        self._sessions: dict[str, _Session] = {}

    def get(self, session_id: str | None) -> tuple[str, SpellingBuffer]:
        self._purge()
        with self._lock:
            if session_id and session_id in self._sessions:
                s = self._sessions[session_id]
                s.touched = time.monotonic()
                return session_id, s.buffer
            new_id = session_id or uuid.uuid4().hex
            self._sessions[new_id] = _Session()
            return new_id, self._sessions[new_id].buffer

    def reset(self, session_id: str) -> None:
        with self._lock:
            self._sessions.pop(session_id, None)

    def _purge(self) -> None:
        now = time.monotonic()
        with self._lock:
            dead = [k for k, v in self._sessions.items() if now - v.touched > self.ttl_s]
            for k in dead:
                del self._sessions[k]


_store = SpellSessionStore()


def classify_frame(
    image_bytes: bytes,
    *,
    session_id: str | None = None,
    threshold: float = 0.55,
    reset: bool = False,
    single_shot: bool = False,
) -> dict:
    """Classifie une image et met à jour le tampon d'épellation de la session."""
    try:
        predictor = get_predictor()
    except FingerspellUnavailable as exc:
        raise

    if reset and session_id:
        _store.reset(session_id)

    sid, buf = _store.get(session_id)
    # Import d'une seule image : commit immédiat (pas de hold multi-frames).
    if single_shot:
        buf.gate.min_hold = 1
        buf.gate.cooldown_s = 0.0

    pred = predictor.predict_bytes(image_bytes)
    update = buf.update(pred["label"], confidence=pred["confidence"], threshold=threshold)

    display_text = update["text"]
    if (
        not display_text
        and single_shot
        and update.get("accepted")
        and pred["label"]
        and pred["label"].lower() not in ("nothing", "del", "space")
    ):
        display_text = pred["label"].strip().upper()[:1]

    return {
        "ok": True,
        "mode": "fingerspell",
        "session_id": sid,
        "label": pred["label"],
        "confidence": pred["confidence"],
        "top": pred["top"],
        "latency_ms": pred["latency_ms"],
        "runtime": pred["runtime"],
        "hand_detected": pred.get("hand_detected", True),
        "text": display_text or update["text"],
        "committed": update["committed"],
        "accepted": update["accepted"],
        "model": {
            "id": pred.get("model_id") or "fingerspell-asl",
            "name": "ASL Fingerspell CNN-BiLSTM",
            "version": pred.get("model_id") or "1.0.0",
            "dataset": "asl_alphabet",
        },
    }


def classify_media(
    data: bytes,
    *,
    filename: str = "frame.jpg",
    session_id: str | None = None,
    threshold: float = 0.55,
    reset: bool = False,
    single_shot: bool = False,
) -> dict:
    """Classifie une image OU un clip vidéo (flux caméra temps réel).

    Pour une vidéo : échantillonne plusieurs frames et les enchaîne dans la
    même session d'épellation — c'est le chemin live appareil.
    """
    from .video_frames import is_video_filename, sample_jpeg_frames

    if not is_video_filename(filename):
        return classify_frame(
            data,
            session_id=session_id,
            threshold=threshold,
            reset=reset,
            single_shot=single_shot,
        )

    frames = sample_jpeg_frames(data, filename=filename, max_frames=5)
    if not frames:
        # Fallback : tenter comme image (certains webm courts).
        return classify_frame(
            data,
            session_id=session_id,
            threshold=threshold,
            reset=reset,
            single_shot=single_shot,
        )

    # Clip live : hold allégé (plusieurs frames du même signe dans le clip).
    result: dict | None = None
    sid = session_id
    do_reset = reset
    for i, frame in enumerate(frames):
        result = classify_frame(
            frame,
            session_id=sid,
            threshold=threshold,
            reset=do_reset and i == 0,
            single_shot=False,
        )
        sid = result.get("session_id") or sid
        do_reset = False
        # Accélère le gate pour les frames suivantes du même clip.
        if i == 0 and sid:
            _, buf = _store.get(sid)
            buf.gate.min_hold = max(1, min(buf.gate.min_hold, 2))
            buf.gate.cooldown_s = min(buf.gate.cooldown_s, 0.25)

    assert result is not None
    result["frames_scored"] = len(frames)
    result["source"] = "video_clip"
    return result
