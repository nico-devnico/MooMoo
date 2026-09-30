"""Chemins et registre des modèles d'épellation ASL."""

from __future__ import annotations

import json
import shutil
from pathlib import Path

from .. import config

IMG_SIZE = 64
MODELS_ROOT = config.ML_ROOT / "models" / "fingerspell"
VERSIONS_DIR = MODELS_ROOT / "versions"
ACTIVE_FILE = MODELS_ROOT / "active.json"
DATASET_DIR = config.ML_ROOT / "dataset"
DATASET_OUTPUTS = DATASET_DIR / "outputs" / "models"
DATASET_REPORTS = DATASET_DIR / "outputs" / "reports"

_ensuring = False


def ensure_layout() -> None:
    """Crée la structure et enregistre le modèle livré s'il n'y a encore aucune version."""
    global _ensuring
    if _ensuring:
        return
    _ensuring = True
    try:
        VERSIONS_DIR.mkdir(parents=True, exist_ok=True)
        seeded = VERSIONS_DIR / "asl-lstm-v1"
        if not any(VERSIONS_DIR.iterdir()):
            seeded.mkdir(parents=True, exist_ok=True)
            src_tflite = MODELS_ROOT / "model.tflite"
            src_labels = MODELS_ROOT / "labels.json"
            if not src_tflite.exists() and (DATASET_OUTPUTS / "asl_lstm_mobile.tflite").exists():
                src_tflite = DATASET_OUTPUTS / "asl_lstm_mobile.tflite"
            if not src_labels.exists() and (DATASET_OUTPUTS / "labels.json").exists():
                src_labels = DATASET_OUTPUTS / "labels.json"
            if src_tflite.exists():
                shutil.copy2(src_tflite, seeded / "model.tflite")
            if src_labels.exists():
                shutil.copy2(src_labels, seeded / "labels.json")
            metrics = _load_report_metrics()
            (seeded / "metrics.json").write_text(
                json.dumps(metrics, indent=2, ensure_ascii=False),
                encoding="utf-8",
            )
            (seeded / "meta.json").write_text(
                json.dumps(
                    {
                        "id": "asl-lstm-v1",
                        "name": "ASL CNN-BiLSTM",
                        "version": "1.0.0",
                        "dataset": "asl_alphabet",
                        "runtime": "tflite",
                    },
                    indent=2,
                    ensure_ascii=False,
                ),
                encoding="utf-8",
            )
            _write_active("asl-lstm-v1")
            _mirror_active(seeded)
        elif not ACTIVE_FILE.exists():
            first = next((p for p in VERSIONS_DIR.iterdir() if p.is_dir()), None)
            if first is not None:
                _write_active(first.name)
                _mirror_active(first)
    finally:
        _ensuring = False


def _write_active(version_id: str) -> None:
    ACTIVE_FILE.write_text(
        json.dumps({"id": version_id}, indent=2),
        encoding="utf-8",
    )


def _mirror_active(folder: Path) -> None:
    for name in ("model.tflite", "labels.json"):
        src = folder / name
        if src.exists():
            shutil.copy2(src, MODELS_ROOT / name)


def _load_report_metrics() -> dict:
    summary = DATASET_REPORTS / "metrics_summary.json"
    report = DATASET_REPORTS / "classification_report.json"
    log = DATASET_REPORTS / "training_log.csv"
    out: dict = {}
    if summary.exists():
        out["summary"] = json.loads(summary.read_text(encoding="utf-8"))
    if report.exists():
        out["classification"] = json.loads(report.read_text(encoding="utf-8"))
    if log.exists():
        rows = []
        lines = log.read_text(encoding="utf-8").strip().splitlines()
        if lines:
            headers = [h.strip() for h in lines[0].split(",")]
            for line in lines[1:]:
                parts = [p.strip() for p in line.split(",")]
                if len(parts) != len(headers):
                    continue
                row = {}
                for h, p in zip(headers, parts):
                    try:
                        row[h] = float(p)
                    except ValueError:
                        row[h] = p
                rows.append(row)
        out["history"] = rows
    return out


def _read_active_id() -> str | None:
    if not ACTIVE_FILE.exists():
        return None
    data = json.loads(ACTIVE_FILE.read_text(encoding="utf-8"))
    return data.get("id")


def active_id() -> str | None:
    ensure_layout()
    return _read_active_id()


def active_dir() -> Path:
    ensure_layout()
    aid = _read_active_id()
    if aid:
        folder = VERSIONS_DIR / aid
        if (folder / "model.tflite").exists() or (folder / "labels.json").exists():
            return folder
    # Repli : dossier racine fingerspell.
    return MODELS_ROOT


def set_active(version_id: str) -> dict:
    ensure_layout()
    folder = VERSIONS_DIR / version_id
    if not folder.is_dir():
        raise FileNotFoundError(f"Version inconnue : {version_id}")
    _write_active(version_id)
    _mirror_active(folder)
    return describe(version_id, active=True)


def list_versions() -> list[dict]:
    ensure_layout()
    current = _read_active_id()
    items = []
    for folder in sorted(VERSIONS_DIR.iterdir()):
        if folder.is_dir():
            items.append(describe(folder.name, active=(folder.name == current)))
    return items


def describe(version_id: str, active: bool | None = None) -> dict:
    folder = VERSIONS_DIR / version_id
    if not folder.is_dir():
        raise FileNotFoundError(f"Version inconnue : {version_id}")
    meta_path = folder / "meta.json"
    metrics_path = folder / "metrics.json"
    meta = json.loads(meta_path.read_text(encoding="utf-8")) if meta_path.exists() else {
        "id": version_id,
        "name": version_id,
        "version": "?",
        "dataset": "asl_alphabet",
    }
    metrics = json.loads(metrics_path.read_text(encoding="utf-8")) if metrics_path.exists() else {}
    summary = metrics.get("summary") or {}
    if active is None:
        active = version_id == _read_active_id()
    return {
        **meta,
        "id": version_id,
        "active": active,
        "has_tflite": (folder / "model.tflite").exists(),
        "accuracy": summary.get("test", {}).get("accuracy")
        or summary.get("best_val_accuracy"),
        "top3_accuracy": summary.get("test", {}).get("top3_accuracy"),
        "latency_hint_ms": None,
        "dataset": meta.get("dataset") or "asl_alphabet",
        "dataset_dir": str(DATASET_DIR),
        "architecture": summary.get("architecture") or meta.get("architecture") or "CNN-BiLSTM",
        "input_shape": summary.get("input_shape") or [IMG_SIZE, IMG_SIZE, 3],
        "num_classes": summary.get("num_classes"),
        "epochs_ran": summary.get("epochs_ran"),
        "max_per_class": summary.get("max_per_class"),
        "tflite_size_kb": summary.get("tflite_size_kb"),
        "val_accuracy": (summary.get("val") or {}).get("accuracy"),
        "test_samples": (summary.get("test") or {}).get("n_samples"),
        "val_samples": (summary.get("val") or {}).get("n_samples"),
        "metrics": metrics,
    }
