"""Random search + Hyperband scheduling (Li et al., 2018).

Configurations are sampled at random; each Hyperband bracket trains many of
them on a small epoch budget and keeps the best 1/eta for a larger budget.
Survivors resume from their checkpoint instead of restarting from scratch.
"""

from __future__ import annotations

import math
import random
from dataclasses import dataclass

DEFAULT_SPACE = {
    "lstm_layers": [1, 2, 3],
    "lstm_units": [64, 128, 256],
    "dropout": [0.0, 0.5],
    "dense_layers": [0, 1],
    "dense_units": [64, 128],
    "learning_rate": [1e-4, 3e-3],
    "batch_size": [16, 32, 64],
    "optimizer": ["adam", "adamw"],
}


@dataclass(frozen=True)
class Rung:
    configs: int
    epochs: int


@dataclass(frozen=True)
class Bracket:
    index: int
    rungs: tuple[Rung, ...]

    @property
    def initial_configs(self) -> int:
        return self.rungs[0].configs


def hyperband_schedule(max_epochs: int, eta: int = 3, max_trials: int | None = None,
                       min_epochs: int = 1) -> list[Bracket]:
    """Brackets of successive halving. [max_trials] caps the sampled configs."""
    if max_epochs < 1 or eta < 2:
        raise ValueError("max_epochs >= 1 et eta >= 2 requis")
    s_max = max(0, int(math.floor(math.log(max(max_epochs / max(min_epochs, 1), 1), eta) + 1e-9)))
    brackets = []
    for s in range(s_max, -1, -1):
        n = int(math.ceil((s_max + 1) / (s + 1) * eta ** s))
        r = max_epochs * eta ** (-s)
        rungs = []
        for i in range(s + 1):
            n_i = max(1, int(math.floor(n * eta ** (-i))))
            r_i = max(min_epochs, int(round(r * eta ** i)))
            rungs.append(Rung(n_i, min(r_i, max_epochs)))
        brackets.append(Bracket(s, tuple(rungs)))

    if max_trials:
        total = sum(b.initial_configs for b in brackets)
        if total > max_trials:
            scale = max_trials / total
            scaled = []
            for b in brackets:
                n0 = max(1, int(round(b.initial_configs * scale)))
                rungs = []
                for i, rung in enumerate(b.rungs):
                    rungs.append(Rung(max(1, int(math.floor(n0 * eta ** (-i)))), rung.epochs))
                scaled.append(Bracket(b.index, tuple(rungs)))
            brackets = scaled
            # Rounding can overshoot: drop the widest brackets until we fit.
            while sum(b.initial_configs for b in brackets) > max_trials and len(brackets) > 1:
                brackets.pop(0)
    return brackets


def sample_config(space: dict, rng: random.Random, base: dict) -> dict:
    """Random configuration: dropout [lo, hi] and learning_rate [lo, hi] (log scale)
    are ranges; every other key is a list of choices."""
    s = {**DEFAULT_SPACE, **(space or {})}

    def choice(key):
        return rng.choice(list(s[key]))

    def uniform(key):
        lo, hi = s[key]
        return rng.uniform(float(lo), float(hi))

    def log_uniform(key):
        lo, hi = s[key]
        return math.exp(rng.uniform(math.log(float(lo)), math.log(float(hi))))

    layers = int(choice("lstm_layers"))
    cfg = dict(base)
    cfg["lstm_units"] = [int(choice("lstm_units")) for _ in range(layers)]
    cfg["dropout"] = round(uniform("dropout"), 3) if len(s["dropout"]) == 2 else float(choice("dropout"))
    dense_layers = int(choice("dense_layers"))
    cfg["dense_units"] = [int(choice("dense_units")) for _ in range(dense_layers)]
    cfg["learning_rate"] = float(f"{log_uniform('learning_rate'):.2e}")
    cfg["batch_size"] = int(choice("batch_size"))
    cfg["optimizer"] = str(choice("optimizer"))
    return cfg


def config_key(cfg: dict) -> tuple:
    return (
        tuple(cfg["lstm_units"]), round(cfg["dropout"], 2), tuple(cfg["dense_units"]),
        cfg["learning_rate"], cfg["batch_size"], cfg["optimizer"],
    )


def sample_unique(space: dict, n: int, rng: random.Random, base: dict, seen: set) -> list[dict]:
    out = []
    attempts = 0
    while len(out) < n and attempts < n * 50:
        attempts += 1
        cfg = sample_config(space, rng, base)
        key = config_key(cfg)
        if key in seen:
            continue
        seen.add(key)
        out.append(cfg)
    return out
