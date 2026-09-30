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
) -> dict:
    """Classifie une image et met à jour le tampon d'épellation de la session."""
    try:
        predictor = get_predictor()
    except FingerspellUnavailable as exc:
        raise

    if reset and session_id:
        _store.reset(session_id)

    sid, buf = _store.get(session_id)
    pred = predictor.predict_bytes(image_bytes)
    update = buf.update(pred["label"], confidence=pred["confidence"], threshold=threshold)
    return {
        "ok": True,
        "mode": "fingerspell",
        "session_id": sid,
        "label": pred["label"],
        "confidence": pred["confidence"],
        "top": pred["top"],
        "latency_ms": pred["latency_ms"],
        "runtime": pred["runtime"],
        "text": update["text"],
        "committed": update["committed"],
        "accepted": update["accepted"],
        "model": {
            "id": "fingerspell-asl",
            "name": "ASL Fingerspell CNN-BiLSTM",
            "version": "1.0.0",
            "dataset": "asl_alphabet",
        },
    }
