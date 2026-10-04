"""Surveille la fin de train.py, publie asl-lstm-vN, écrit capture 12 (sans toucher 01–11)."""

from __future__ import annotations

import json
import os
import sys
import time
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ML = ROOT / "ml"
CAP = ROOT / "assets" / "captures"
sys.path.insert(0, str(ML))

LOG = CAP / "11_train_log.txt"
DONE = CAP / "12_train_done.txt"
METRICS = ML / "dataset" / "outputs" / "reports" / "metrics_summary.json"


def _log_mentions_exit() -> bool:
    try:
        raw = LOG.read_bytes()
    except OSError:
        return False
    try:
        text = raw.decode("utf-16")
    except Exception:
        text = raw.decode("utf-8", errors="replace")
    return "exit_code=" in text or "[OK] Modele TFLite" in text or "metrics_summary" in text.lower()


def _render_done(body: str) -> None:
    from PIL import Image, ImageDraw, ImageFont

    DONE.write_text(body, encoding="utf-8")
    try:
        font = ImageFont.truetype(r"C:/Windows/Fonts/consola.ttf", 15)
        title_font = ImageFont.truetype(r"C:/Windows/Fonts/consola.ttf", 16)
    except OSError:
        font = ImageFont.load_default()
        title_font = font
    lines = body.splitlines() or [""]
    pad, lh = 24, 20
    w = max(920, max(len(l) for l in lines) * 9 + pad * 2)
    h = pad * 2 + 36 + lh * (len(lines) + 1)
    img = Image.new("RGB", (w, h), (12, 12, 12))
    d = ImageDraw.Draw(img)
    d.text((pad, pad), "réentraînement fingerspell — terminé", fill=(120, 200, 120), font=title_font)
    y = pad + 32
    for line in lines:
        d.text((pad, y), line[:200], fill=(220, 220, 220), font=font)
        y += lh
    img.save(CAP / "12_train_done.png")
    print("wrote", CAP / "12_train_done.png")


def main() -> int:
    print("[watch] attente fin entraînement…")
    while True:
        if METRICS.exists():
            # Nouveau fichier ? On vérifie mtime récent (< 2h) et modèles TFLite.
            age = time.time() - METRICS.stat().st_mtime
            tflite = ML / "dataset" / "outputs" / "models" / "asl_lstm_mobile.tflite"
            if age < 7200 and tflite.exists() and (time.time() - tflite.stat().st_mtime) < 7200:
                break
        if _log_mentions_exit():
            break
        time.sleep(20)

    os.chdir(ML)
    from moomoo_ml.fingerspell.train_job import publish_from_dataset_outputs

    model = publish_from_dataset_outputs(activate=True)
    metrics = {}
    if METRICS.exists():
        metrics = json.loads(METRICS.read_text(encoding="utf-8"))
    body = "\n".join(
        [
            "=== Capture 12 — réentraînement terminé (01–11 conservées) ===",
            f"date: {datetime.now().isoformat(timespec='seconds')}",
            f"version: {model.get('id')}",
            f"accuracy: {model.get('accuracy')}",
            f"epochs_ran: {metrics.get('epochs_ran')}",
            f"best_val_accuracy: {metrics.get('best_val_accuracy')}",
            f"test: {metrics.get('test')}",
            f"tflite_kb: {metrics.get('tflite_size_kb')}",
            "active: oui (reload predictor)",
            "status: DONE",
        ]
    )
    _render_done(body)
    print(json.dumps(model, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
