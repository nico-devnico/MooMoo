"""Lancement asynchrone de l'entraînement ASL fingerspell + publication registre."""

from __future__ import annotations

import json
import shutil
import subprocess
import sys
import threading
import time
import traceback
from datetime import datetime, timezone
from pathlib import Path

from . import registry

_lock = threading.Lock()
_state: dict = {
    "status": "idle",  # idle | running | succeeded | failed
    "started_at": None,
    "finished_at": None,
    "message": None,
    "version_id": None,
    "log_tail": [],
    "error": None,
    "pid": None,
}


def status() -> dict:
    with _lock:
        return dict(_state)


def _set(**kwargs) -> None:
    with _lock:
        line = kwargs.pop("log_line", None)
        _state.update(kwargs)
        if line is not None:
            tail = list(_state.get("log_tail") or [])
            tail.append(str(line))
            _state["log_tail"] = tail[-80:]


def _next_version_id() -> str:
    registry.ensure_layout()
    existing = [
        p.name
        for p in registry.VERSIONS_DIR.iterdir()
        if p.is_dir() and p.name.startswith("asl-lstm-v")
    ]
    nums = []
    for name in existing:
        suffix = name.replace("asl-lstm-v", "")
        if suffix.isdigit():
            nums.append(int(suffix))
    n = (max(nums) + 1) if nums else 2
    return f"asl-lstm-v{n}"


def publish_from_dataset_outputs(version_id: str | None = None, *, activate: bool = True) -> dict:
    """Copie les artefacts dataset/outputs vers une nouvelle version du registre."""
    registry.ensure_layout()
    vid = version_id or _next_version_id()
    dest = registry.VERSIONS_DIR / vid
    dest.mkdir(parents=True, exist_ok=True)

    tflite_src = registry.DATASET_OUTPUTS / "asl_lstm_mobile.tflite"
    labels_src = registry.DATASET_OUTPUTS / "labels.json"
    if not tflite_src.exists():
        raise FileNotFoundError(f"TFLite introuvable : {tflite_src}")
    if not labels_src.exists():
        raise FileNotFoundError(f"labels.json introuvable : {labels_src}")

    shutil.copy2(tflite_src, dest / "model.tflite")
    shutil.copy2(labels_src, dest / "labels.json")
    metrics = registry._load_report_metrics()
    (dest / "metrics.json").write_text(
        json.dumps(metrics, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )
    summary = metrics.get("summary") or {}
    meta = {
        "id": vid,
        "name": f"ASL CNN-BiLSTM ({vid})",
        "version": vid.replace("asl-lstm-v", "") + ".0.0",
        "dataset": "asl_alphabet",
        "architecture": summary.get("architecture") or "CNN-BiLSTM",
        "runtime": "tflite",
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    (dest / "meta.json").write_text(
        json.dumps(meta, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )
    if activate:
        registry.set_active(vid)
        from .predictor import reload_predictor

        reload_predictor().warmup()
    return registry.describe(vid, active=activate)


def _run_training(max_per_class: int | None, epochs: int | None) -> None:
    started = datetime.now(timezone.utc).isoformat()
    _set(
        status="running",
        started_at=started,
        finished_at=None,
        message="Entraînement démarré",
        version_id=None,
        log_tail=[],
        error=None,
    )
    train_script = registry.DATASET_DIR / "train.py"
    if not train_script.exists():
        _set(
            status="failed",
            finished_at=datetime.now(timezone.utc).isoformat(),
            error=f"Script introuvable : {train_script}",
            message="Échec",
        )
        return

    env = dict(**{k: v for k, v in __import__("os").environ.items()})
    # Overrides optionnels via variables lues par config si on les ajoute ;
    # pour l'instant on passe par patch temporaire du module après import.
    cmd = [sys.executable, str(train_script)]
    try:
        # Patch config avant sous-processus via env (train lit config au import).
        if max_per_class is not None:
            env["MOOMOO_FS_MAX_PER_CLASS"] = str(int(max_per_class))
        if epochs is not None:
            env["MOOMOO_FS_EPOCHS"] = str(int(epochs))

        proc = subprocess.Popen(
            cmd,
            cwd=str(registry.DATASET_DIR),
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
        )
        _set(pid=proc.pid, message=f"Processus {proc.pid}")
        assert proc.stdout is not None
        for line in proc.stdout:
            _set(log_line=line.rstrip(), message=line.strip()[:200] or _state.get("message"))
        code = proc.wait()
        if code != 0:
            _set(
                status="failed",
                finished_at=datetime.now(timezone.utc).isoformat(),
                error=f"train.py exit {code}",
                message="Entraînement échoué",
                pid=None,
            )
            return

        vid = _next_version_id()
        model = publish_from_dataset_outputs(vid, activate=True)
        _set(
            status="succeeded",
            finished_at=datetime.now(timezone.utc).isoformat(),
            version_id=vid,
            message=f"Publié {vid} (acc={model.get('accuracy')})",
            pid=None,
        )
    except Exception as exc:
        _set(
            status="failed",
            finished_at=datetime.now(timezone.utc).isoformat(),
            error=f"{exc}\n{traceback.format_exc()[-1500:]}",
            message="Exception pendant l'entraînement",
            pid=None,
        )


def start(*, max_per_class: int | None = None, epochs: int | None = None) -> dict:
    """Démarre un entraînement en arrière-plan. Refuse si déjà running."""
    with _lock:
        if _state.get("status") == "running":
            return {"ok": False, "error": "already_running", **dict(_state)}
    thread = threading.Thread(
        target=_run_training,
        kwargs={"max_per_class": max_per_class, "epochs": epochs},
        daemon=True,
        name="fingerspell-train",
    )
    thread.start()
    # Laisse le thread initialiser le statut.
    time.sleep(0.05)
    return {"ok": True, **status()}
