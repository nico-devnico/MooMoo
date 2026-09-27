"""Dataset Analyzer: structure, classes, integrity, duplicates, media stats."""

from __future__ import annotations

import hashlib
import statistics
from collections import Counter, defaultdict
from pathlib import Path
from typing import Callable

from .discovery import Sample, discover_samples, list_media_files, media_kind

MIN_SAMPLES_PER_CLASS = 10
LISTED_LIMIT = 50


def file_fingerprint(path: Path) -> str:
    """Content hash; large files hash their head, tail and size only."""
    size = path.stat().st_size
    h = hashlib.sha1(str(size).encode())
    with open(path, "rb") as fh:
        if size <= 8 << 20:
            h.update(fh.read())
        else:
            h.update(fh.read(1 << 20))
            fh.seek(-(1 << 20), 2)
            h.update(fh.read())
    return h.hexdigest()


def probe_media(path: Path) -> dict:
    """Opens the file and returns its properties, or {'error': ...}."""
    kind = media_kind(path)
    try:
        if kind == "image":
            from PIL import Image

            with Image.open(path) as im:
                im.verify()
            with Image.open(path) as im:
                return {"width": im.width, "height": im.height, "frames": 1}
        if kind == "gif":
            from PIL import Image

            with Image.open(path) as im:
                frames = getattr(im, "n_frames", 1)
                durations = []
                for i in range(frames):
                    im.seek(i)
                    durations.append(im.info.get("duration", 100) or 100)
                total_ms = sum(durations)
                return {
                    "width": im.width,
                    "height": im.height,
                    "frames": frames,
                    "duration_s": round(total_ms / 1000, 3),
                    "fps": round(frames / (total_ms / 1000), 2) if total_ms else None,
                }
        if kind == "video":
            import cv2

            cap = cv2.VideoCapture(str(path))
            try:
                if not cap.isOpened():
                    return {"error": "illisible"}
                ok, _ = cap.read()
                if not ok:
                    return {"error": "aucune image décodable"}
                fps = cap.get(cv2.CAP_PROP_FPS) or 0
                frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT) or 0)
                return {
                    "width": int(cap.get(cv2.CAP_PROP_FRAME_WIDTH)),
                    "height": int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT)),
                    "frames": frames,
                    "fps": round(fps, 2) if fps else None,
                    "duration_s": round(frames / fps, 3) if fps and frames else None,
                }
            finally:
                cap.release()
    except Exception as exc:  # corrupted files raise all sorts of errors
        return {"error": f"{type(exc).__name__}: {exc}"[:200]}
    return {"error": "format non pris en charge"}


def _summary(values: list[float]) -> dict | None:
    values = [v for v in values if v is not None]
    if not values:
        return None
    return {
        "min": round(min(values), 3),
        "max": round(max(values), 3),
        "mean": round(statistics.fmean(values), 3),
        "median": round(statistics.median(values), 3),
    }


def analyze_dataset(root: Path, *, is_structured: bool, is_labeled: bool,
                    label_mapping: dict | None, media_format: str,
                    progress: Callable[[float, str], None] | None = None,
                    should_stop: Callable[[], bool] | None = None) -> dict:
    all_files = list_media_files(root)
    other_files = [p for p in root.rglob("*") if p.is_file() and p not in set(all_files)]
    samples = discover_samples(
        root,
        is_structured=is_structured,
        is_labeled=is_labeled,
        label_mapping=label_mapping,
        media_format=media_format,
    )

    ext_counts = Counter(p.suffix.lower() for p in all_files)
    kind_counts = Counter(s.kind for s in samples)

    invalid: list[dict] = []
    fingerprints: dict[str, list[str]] = defaultdict(list)
    probes: dict[str, dict] = {}
    total = max(len(all_files), 1)
    for i, path in enumerate(all_files):
        if should_stop and should_stop():
            raise InterruptedError("analyse annulée")
        rel = path.relative_to(root).as_posix()
        info = probe_media(path)
        probes[rel] = info
        if "error" in info:
            invalid.append({"path": rel, "error": info["error"]})
        else:
            fingerprints[file_fingerprint(path)].append(rel)
        if progress and (i % 25 == 0 or i == total - 1):
            progress((i + 1) / total * 100, f"Analyse {i + 1}/{total} fichiers")

    duplicates = [paths for paths in fingerprints.values() if len(paths) > 1]
    invalid_set = {d["path"] for d in invalid}

    valid_samples = [
        s for s in samples
        if not any(f.relative_to(root).as_posix() in invalid_set for f in s.files)
    ]
    labeled = [s for s in valid_samples if s.label]
    unlabeled = [s for s in valid_samples if not s.label]

    class_counts = Counter(s.label for s in labeled)
    counts = sorted(class_counts.values())
    imbalance = round(counts[-1] / counts[0], 2) if counts else None

    signer_counts = Counter(s.signer for s in labeled if s.signer)
    signers_per_class = {
        label: len({s.signer for s in labeled if s.label == label and s.signer})
        for label in class_counts
    }

    videos = [probes[f.relative_to(root).as_posix()] for s in valid_samples
              if s.kind in ("video", "gif") for f in s.files]
    resolutions = Counter(
        f"{p['width']}x{p['height']}" for p in probes.values()
        if "width" in p and "height" in p
    )

    warnings: list[str] = []
    recommendations: list[str] = []
    if not all_files:
        warnings.append("Aucun fichier média reconnu (images, GIF, vidéos).")
    if invalid:
        warnings.append(f"{len(invalid)} fichier(s) illisible(s) ou corrompu(s) seront exclus.")
    if duplicates:
        n_dup = sum(len(g) - 1 for g in duplicates)
        warnings.append(
            f"{n_dup} doublon(s) exact(s) : ils seront regroupés dans le même split pour éviter toute fuite."
        )
    if unlabeled:
        warnings.append(f"{len(unlabeled)} échantillon(s) sans label : ils ne seront pas utilisés.")
        recommendations.append(
            "Fournir un label_mapping (chemin ou dossier -> label) ou un fichier labels.csv "
            "(colonnes path,label[,signer]) : les labels ne sont jamais devinés."
        )
    small = sorted(label for label, c in class_counts.items() if c < MIN_SAMPLES_PER_CLASS)
    if small:
        warnings.append(
            f"{len(small)} classe(s) ont moins de {MIN_SAMPLES_PER_CLASS} exemples."
        )
        recommendations.append(
            "Activer l'augmentation contrôlée pour ces classes et, surtout, collecter "
            "des exemples supplémentaires (autres signataires)."
        )
    if imbalance and imbalance > 3:
        warnings.append(f"Déséquilibre marqué entre classes (ratio max/min = {imbalance}).")
        recommendations.append("Utiliser les poids de classes (class_weight = balanced).")
    if len(class_counts) == 1:
        warnings.append("Une seule classe : un classifieur ne peut pas être entraîné.")
    if signer_counts:
        if len(signer_counts) < 3:
            warnings.append(
                f"Seulement {len(signer_counts)} signataire(s) : la généralisation à de "
                "nouvelles personnes sera faible."
            )
    else:
        warnings.append(
            "Aucune information de signataire détectée : le split ne pourra pas être "
            "indépendant des signataires (risque de surestimer les performances)."
        )

    return {
        "root": str(root),
        "files_total": len(all_files),
        "other_files": len(other_files),
        "extensions": dict(ext_counts),
        "sample_kinds": dict(kind_counts),
        "samples_total": len(samples),
        "samples_valid": len(valid_samples),
        "samples_labeled": len(labeled),
        "samples_unlabeled": len(unlabeled),
        "unlabeled_examples": [s.rel for s in unlabeled[:LISTED_LIMIT]],
        "classes_count": len(class_counts),
        "classes": dict(sorted(class_counts.items(), key=lambda kv: (-kv[1], kv[0]))),
        "class_balance": {
            "min": counts[0] if counts else 0,
            "max": counts[-1] if counts else 0,
            "mean": round(statistics.fmean(counts), 2) if counts else 0,
            "imbalance_ratio": imbalance,
            "classes_below_min": small[:LISTED_LIMIT],
            "min_recommended": MIN_SAMPLES_PER_CLASS,
        },
        "invalid_count": len(invalid),
        "invalid": invalid[:LISTED_LIMIT],
        "invalid_paths": sorted(invalid_set),
        "duplicate_groups": len(duplicates),
        "duplicates": duplicates[:LISTED_LIMIT],
        "media": {
            "fps": _summary([v.get("fps") for v in videos]),
            "duration_s": _summary([v.get("duration_s") for v in videos]),
            "frames": _summary([v.get("frames") for v in videos]),
            "resolutions": dict(resolutions.most_common(5)),
        },
        "signers_count": len(signer_counts),
        "signers": dict(signer_counts.most_common(LISTED_LIMIT)),
        "signers_per_class_min": min(signers_per_class.values()) if signers_per_class else 0,
        "split_hints": dict(Counter(s.split_hint for s in labeled if s.split_hint)),
        "warnings": warnings,
        "recommendations": recommendations,
        "trainable": len(class_counts) >= 2 and len(labeled) >= 4,
    }


def samples_for_training(root: Path, dataset: dict) -> list[Sample]:
    """Labeled samples whose files all open; the analyzer's view of the data."""
    samples = discover_samples(
        root,
        is_structured=dataset.get("is_structured", True),
        is_labeled=dataset.get("is_labeled", True),
        label_mapping=dataset.get("label_mapping") or {},
        media_format=dataset.get("media_format", "auto"),
    )
    invalid = set((dataset.get("analysis") or {}).get("invalid_paths", []))
    return [
        s for s in samples
        if s.label and not any(f.relative_to(root).as_posix() in invalid for f in s.files)
    ]
