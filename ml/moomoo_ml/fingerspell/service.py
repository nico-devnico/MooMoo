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
    # Espace déjà ajouté suite à « pas de main » — jusqu'à ce qu'une main revienne.
    no_hand_space_done: bool = False


class SpellSessionStore:
    """Tampons par session_id, expirés après [ttl_s] d'inactivité."""

    def __init__(self, ttl_s: float = 300):
        self.ttl_s = ttl_s
        self._lock = threading.Lock()
        self._sessions: dict[str, _Session] = {}

    def get(self, session_id: str | None) -> tuple[str, _Session]:
        self._purge()
        with self._lock:
            if session_id and session_id in self._sessions:
                s = self._sessions[session_id]
                s.touched = time.monotonic()
                return session_id, s
            new_id = session_id or uuid.uuid4().hex
            self._sessions[new_id] = _Session()
            return new_id, self._sessions[new_id]

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
    hand_detected: bool | None = None,
    live: bool = False,
) -> dict:
    """Classifie une image et met à jour le tampon d'épellation de la session.

    [hand_detected]=False → traite comme « space », une seule fois jusqu'à
    ce qu'une main soit à nouveau détectée.
    [live]=True → hold allégé pour coller à l'import image (réponse rapide).
    """
    try:
        get_predictor()
    except FingerspellUnavailable:
        raise

    if reset and session_id:
        _store.reset(session_id)

    sid, session = _store.get(session_id)
    buf = session.buffer

    if single_shot:
        buf.gate.min_hold = 1
        buf.gate.cooldown_s = 0.0
    elif live:
        # Même sensibilité que l'import, avec un léger cooldown anti-doublon.
        buf.gate.min_hold = 1
        buf.gate.cooldown_s = 0.35

    # Pas de main → un seul espace (jamais deux, jamais une fausse lettre).
    if hand_detected is False:
        model_meta = {
            "id": "fingerspell-asl",
            "name": "ASL Fingerspell CNN-BiLSTM",
            "version": "1.0.0",
            "dataset": "asl_alphabet",
        }
        if session.no_hand_space_done:
            return {
                "ok": True,
                "mode": "fingerspell",
                "session_id": sid,
                "label": "space",
                "confidence": 1.0,
                "top": [{"label": "space", "confidence": 1.0}],
                "latency_ms": 0.0,
                "runtime": "skip",
                "hand_detected": False,
                "text": buf.text,
                "committed": None,
                "accepted": False,
                "model": model_meta,
            }
        # Applique immédiatement (hors gate) — une seule fois jusqu'au retour de main.
        # Sur buffer vide, pas d'espace leading (no-op) mais on marque quand même
        # pour ne pas spammer tant que la main n'est pas revenue.
        session.no_hand_space_done = True
        committed = None
        if buf.chars and buf.chars[-1] != " ":
            buf.apply_raw("space")
            committed = "space"
        buf.gate.reset()
        return {
            "ok": True,
            "mode": "fingerspell",
            "session_id": sid,
            "label": "space",
            "confidence": 1.0,
            "top": [{"label": "space", "confidence": 1.0}],
            "latency_ms": 0.0,
            "runtime": "space",
            "hand_detected": False,
            "text": buf.text,
            "committed": committed,
            "accepted": committed is not None,
            "model": model_meta,
        }

    # Une main est visible → on peut à nouveau émettre un espace plus tard.
    if hand_detected is True:
        session.no_hand_space_done = False

    from .predictor import get_predictor as _gp

    pred = _gp().predict_bytes(image_bytes)
    # Si le modèle lui-même signale pas de main claire.
    if pred.get("hand_detected") is False and hand_detected is None:
        return classify_frame(
            image_bytes,
            session_id=sid,
            threshold=threshold,
            reset=False,
            single_shot=single_shot,
            hand_detected=False,
            live=live,
        )

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
    hand_detected: bool | None = None,
    live: bool = False,
) -> dict:
    """Classifie une image OU un clip vidéo."""
    from .video_frames import is_video_filename, sample_jpeg_frames

    if not is_video_filename(filename):
        return classify_frame(
            data,
            session_id=session_id,
            threshold=threshold,
            reset=reset,
            single_shot=single_shot,
            hand_detected=hand_detected,
            live=live,
        )

    frames = sample_jpeg_frames(data, filename=filename, max_frames=5)
    if not frames:
        return classify_frame(
            data,
            session_id=session_id,
            threshold=threshold,
            reset=reset,
            single_shot=single_shot,
            hand_detected=hand_detected,
            live=live,
        )

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
            hand_detected=hand_detected if i == 0 else True,
            live=True,
        )
        sid = result.get("session_id") or sid
        do_reset = False

    assert result is not None
    result["frames_scored"] = len(frames)
    result["source"] = "video_clip"
    return result
