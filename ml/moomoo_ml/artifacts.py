"""Artifact layout on disk, plus optional mirroring to Supabase Storage."""

from __future__ import annotations

import json
import logging
from pathlib import Path

import requests

from . import config

logger = logging.getLogger("moomoo_ml")

UPLOADED = ("model.keras", "model.tflite", "labels.json", "preprocessing.json",
            "metadata.json", "metrics.json", "history.json", "confusion_matrix.json",
            "tflite_report.json", "training.log")


def experiment_dir(language: str, code: str) -> Path:
    path = config.ARTIFACTS_DIR / language / code
    path.mkdir(parents=True, exist_ok=True)
    return path


def write_json(folder: Path, name: str, payload) -> Path:
    path = folder / name
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2, default=str), encoding="utf-8")
    return path


def append_log(folder: Path, line: str) -> None:
    with open(folder / "training.log", "a", encoding="utf-8") as fh:
        fh.write(line.rstrip() + "\n")


def listing(folder: Path) -> dict:
    files = {}
    for p in sorted(folder.iterdir()):
        if p.is_file() and not p.name.endswith(".part"):
            files[p.name] = {"size_bytes": p.stat().st_size,
                             "path": str(p.relative_to(config.ARTIFACTS_DIR)).replace("\\", "/")}
    return {"root": str(config.ARTIFACTS_DIR), "files": files}


def mirror_to_storage(folder: Path, prefix: str) -> dict | None:
    """Uploads the main files to Supabase Storage when a service key is configured."""
    if not (config.SUPABASE_URL and config.SERVICE_ROLE_KEY):
        return None
    headers = {"Authorization": f"Bearer {config.SERVICE_ROLE_KEY}", "apikey": config.SERVICE_ROLE_KEY}
    base = config.SUPABASE_URL.rstrip("/") + "/storage/v1"
    requests.post(f"{base}/bucket", headers=headers, timeout=20,
                  json={"id": config.ARTIFACT_BUCKET, "name": config.ARTIFACT_BUCKET, "public": False})
    uploaded = {}
    for name in UPLOADED:
        path = folder / name
        if not path.exists():
            continue
        key = f"{prefix}/{name}"
        with open(path, "rb") as fh:
            r = requests.post(
                f"{base}/object/{config.ARTIFACT_BUCKET}/{key}",
                headers={**headers, "x-upsert": "true", "Content-Type": "application/octet-stream"},
                data=fh, timeout=300,
            )
        if r.ok:
            uploaded[name] = f"{config.ARTIFACT_BUCKET}/{key}"
        else:
            logger.warning("storage upload %s failed: %s %s", key, r.status_code, r.text[:200])
    return {"bucket": config.ARTIFACT_BUCKET, "objects": uploaded}
