"""Paths and environment for the ML service and worker."""

from __future__ import annotations

import os
from pathlib import Path

ML_ROOT = Path(__file__).resolve().parent.parent
PROJECT_ROOT = ML_ROOT.parent


def _load_env_file(path: Path) -> None:
    if not path.exists():
        return
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip())


# ml/.env first, then backend/.env: the worker shares the API's DB access.
_load_env_file(ML_ROOT / ".env")
_load_env_file(PROJECT_ROOT / "backend" / ".env")

DB_URL = os.environ.get("SUPABASE_DB_URL", "")
SUPABASE_URL = os.environ.get("SUPABASE_URL", "")
SERVICE_ROLE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")
ARTIFACT_BUCKET = os.environ.get("ML_ARTIFACT_BUCKET", "ml-models")

DATA_DIR = Path(os.environ.get("ML_DATA_DIR", ML_ROOT / "data"))
CACHE_DIR = Path(os.environ.get("ML_CACHE_DIR", ML_ROOT / "cache"))
ARTIFACTS_DIR = Path(os.environ.get("ML_ARTIFACTS_DIR", ML_ROOT / "artifacts"))

WORKER_POLL_SECONDS = float(os.environ.get("ML_WORKER_POLL_SECONDS", "3"))
HEARTBEAT_SECONDS = float(os.environ.get("ML_HEARTBEAT_SECONDS", "15"))
# A running job whose heartbeat is older than this is considered orphaned.
STALE_JOB_SECONDS = float(os.environ.get("ML_STALE_JOB_SECONDS", "600"))
MAX_JOB_ATTEMPTS = int(os.environ.get("ML_MAX_JOB_ATTEMPTS", "3"))

for directory in (DATA_DIR, CACHE_DIR, ARTIFACTS_DIR):
    directory.mkdir(parents=True, exist_ok=True)
