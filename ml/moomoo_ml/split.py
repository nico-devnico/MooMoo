"""Train / validation / test split without leakage.

Groups never straddle two splits:
  - signer-independent when at least 3 signers are known (a signer's samples
    all land in the same split, so the test set measures unseen people);
  - otherwise every sample is its own group, stratified by label;
  - exact duplicate files are always merged into one group.
Split folders present in the dataset (train/val/test) are honoured when asked.
"""

from __future__ import annotations

from collections import Counter, defaultdict

import numpy as np

DEFAULT_RATIOS = {"train": 0.7, "val": 0.15, "test": 0.15}
MIN_SIGNERS_FOR_GROUP_SPLIT = 3
_HINTS = {"train": "train", "training": "train", "val": "val", "valid": "val",
          "validation": "val", "dev": "val", "test": "test", "testing": "test"}


def _normalize_ratios(ratios: dict | None) -> dict:
    r = {**DEFAULT_RATIOS, **(ratios or {})}
    total = sum(max(0.0, float(v)) for v in r.values())
    if total <= 0:
        return dict(DEFAULT_RATIOS)
    return {k: max(0.0, float(v)) / total for k, v in r.items()}


def _groups(entries: list[dict], by_signer: bool) -> list[list[int]]:
    """Union-find over signer (optional) and file fingerprint."""
    parent = list(range(len(entries)))

    def find(i: int) -> int:
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i

    def union(a: int, b: int) -> None:
        ra, rb = find(a), find(b)
        if ra != rb:
            parent[rb] = ra

    first: dict[tuple, int] = {}
    for i, e in enumerate(entries):
        keys = [("fp", e.get("fingerprint"))] if e.get("fingerprint") else []
        if by_signer and e.get("signer"):
            keys.append(("signer", e["signer"]))
        for key in keys:
            if key in first:
                union(first[key], i)
            else:
                first[key] = i
    groups: dict[int, list[int]] = defaultdict(list)
    for i in range(len(entries)):
        groups[find(i)].append(i)
    return list(groups.values())


def split_entries(entries: list[dict], ratios: dict | None = None, *, seed: int = 42,
                  strategy: str = "auto") -> tuple[dict[str, list[int]], dict]:
    """Returns indices per split and a report describing how it was done.

    strategy: auto | signer | stratified | predefined
    """
    r = _normalize_ratios(ratios)
    rng = np.random.default_rng(seed)
    signers = {e["signer"] for e in entries if e.get("signer")}
    hints = [_HINTS.get((e.get("split_hint") or "").lower()) for e in entries]

    if strategy == "predefined" or (strategy == "auto" and all(hints) and {"train", "test"} <= set(hints)):
        out = {"train": [], "val": [], "test": []}
        for i, h in enumerate(hints):
            out[h or "train"].append(i)
        report = {"strategy": "predefined", "signer_independent": False}
        return out, _finish(report, out, entries, r)

    by_signer = strategy == "signer" or (
        strategy == "auto" and len(signers) >= MIN_SIGNERS_FOR_GROUP_SPLIT
    )
    groups = _groups(entries, by_signer)
    labels = [e["label"] for e in entries]
    n = len(entries)
    targets = {k: v * n for k, v in r.items()}
    out = {"train": [], "val": [], "test": []}
    label_totals = Counter(labels)
    label_in = {k: Counter() for k in out}

    # Largest groups first, each to the split furthest below its target,
    # preferring the split that most needs the group's labels.
    order = sorted(groups, key=lambda g: (-len(g), rng.random()))
    for g in order:
        g_labels = Counter(labels[i] for i in g)

        def need(split: str) -> float:
            deficit = targets[split] - len(out[split])
            label_need = sum(
                max(0.0, label_totals[lab] * r[split] - label_in[split][lab]) * c
                for lab, c in g_labels.items()
            )
            return deficit + 0.5 * label_need

        candidates = [s for s in out if r[s] > 0]
        best = max(candidates, key=need)
        out[best].extend(g)
        label_in[best].update(g_labels)

    report = {
        "strategy": "signer" if by_signer else "stratified",
        "signer_independent": by_signer,
        "signers_total": len(signers),
    }
    if by_signer:
        report["signers"] = {
            k: sorted({entries[i]["signer"] for i in v if entries[i].get("signer")}) for k, v in out.items()
        }
    return out, _finish(report, out, entries, r)


def _finish(report: dict, out: dict[str, list[int]], entries: list[dict], ratios: dict) -> dict:
    labels = [e["label"] for e in entries]
    train_labels = {labels[i] for i in out["train"]}
    report.update({
        "ratios": {k: round(v, 3) for k, v in ratios.items()},
        "sizes": {k: len(v) for k, v in out.items()},
        "classes_missing_in_train": sorted({labels[i] for s in ("val", "test") for i in out[s]} - train_labels),
        "classes_missing_in_test": sorted(set(labels) - {labels[i] for i in out["test"]}),
    })
    warnings = []
    if not report["signer_independent"]:
        warnings.append(
            "Split non indépendant des signataires : les scores de test peuvent être optimistes."
        )
    if report["classes_missing_in_test"]:
        warnings.append(
            f"{len(report['classes_missing_in_test'])} classe(s) absente(s) du test : "
            "trop peu d'exemples ou de signataires."
        )
    if report["classes_missing_in_train"]:
        warnings.append(
            f"{len(report['classes_missing_in_train'])} classe(s) du val/test absente(s) de l'entraînement."
        )
    report["warnings"] = warnings
    return report
