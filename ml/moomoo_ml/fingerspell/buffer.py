"""Tampon d'épellation : assemble lettres / space / del en phrase.

La stabilité évite de répéter la même lettre à chaque frame caméra.
"""

from __future__ import annotations

import time
from dataclasses import dataclass, field


SPECIAL = frozenset({"del", "nothing", "space", "DEL", "NOTHING", "SPACE"})


@dataclass
class StabilityGate:
    """N'accepte un label que s'il reste stable assez longtemps.

    - [min_hold] prédictions consécutives identiques et acceptées
    - [cooldown_s] avant de pouvoir recommiter la même lettre
    """

    min_hold: int = 2
    cooldown_s: float = 0.45
    _pending: str | None = None
    _count: int = 0
    _last_committed: str | None = None
    _last_at: float = 0.0

    def push(self, label: str | None, *, accepted: bool) -> str | None:
        """Retourne le label à appliquer au tampon, ou None si trop tôt."""
        if not accepted or not label or label.lower() == "nothing":
            self._pending = None
            self._count = 0
            return None

        key = label
        now = time.monotonic()
        if key != self._pending:
            self._pending = key
            self._count = 1
        else:
            self._count += 1
        if self._count < self.min_hold:
            return None

        # Même lettre trop tôt → ignorer (main encore posée).
        if (
            key == self._last_committed
            and key.lower() not in ("del", "space")
            and (now - self._last_at) < self.cooldown_s
        ):
            return None

        self._last_committed = key
        self._last_at = now
        self._pending = None
        self._count = 0
        return key

    def reset(self) -> None:
        self._pending = None
        self._count = 0
        self._last_committed = None
        self._last_at = 0.0


@dataclass
class SpellingBuffer:
    """Construit une phrase à partir des labels ASL d'épellation."""

    gate: StabilityGate = field(default_factory=StabilityGate)
    chars: list[str] = field(default_factory=list)

    def apply_raw(self, label: str, *, accepted: bool = True) -> str:
        """Applique un label déjà validé (sans gate) — utile pour les tests."""
        if not accepted:
            return self.text
        low = label.lower()
        if low == "nothing":
            return self.text
        if low == "del":
            if self.chars:
                self.chars.pop()
            return self.text
        if low == "space":
            if self.chars and self.chars[-1] != " ":
                self.chars.append(" ")
            return self.text
        # Lettre : une seule majuscule normalisée.
        letter = label.strip().upper()[:1]
        if letter:
            self.chars.append(letter)
        return self.text

    def update(self, label: str | None, *, confidence: float, threshold: float = 0.55,
               margin: float | None = None, min_margin: float = 0.12) -> dict:
        """Pousse une prédiction frame : gate + tampon.

        Retourne `{text, committed, accepted}` où `committed` est la lettre
        réellement ajoutée (ou None).
        [margin] = top1 - top2 ; si fourni et trop faible, on refuse.
        """
        accepted = bool(label) and confidence >= threshold and label.lower() != "nothing"
        if accepted and margin is not None and margin < min_margin:
            accepted = False
        committed = self.gate.push(label, accepted=accepted)
        if committed:
            self.apply_raw(committed, accepted=True)
        return {
            "text": self.text,
            "committed": committed,
            "accepted": accepted,
            "label": label,
            "confidence": confidence,
        }

    @property
    def text(self) -> str:
        # Garde un espace final unique (séparateur visible), sans espaces multiples.
        s = "".join(self.chars)
        if s.endswith(" "):
            return s.rstrip() + " "
        return s

    def reset(self) -> None:
        self.chars.clear()
        self.gate.reset()
