"""Rend des captures terminal fond noir (PNG) à partir de fichiers .txt de logs."""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
CAPTURES = ROOT / "assets" / "captures"


def render(txt_path: Path, png_path: Path, title: str) -> None:
    raw = txt_path.read_text(encoding="utf-8", errors="replace")
    lines = raw.splitlines() or [""]
    # Police monospace système (Windows Consolas / fallback).
    try:
        font = ImageFont.truetype("consola.ttf", 15)
        title_font = ImageFont.truetype("consola.ttf", 16)
    except OSError:
        try:
            font = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 15)
            title_font = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 16)
        except OSError:
            font = ImageFont.load_default()
            title_font = font

    pad = 24
    line_h = 20
    width = max(920, max((len(l) for l in lines), default=40) * 9 + pad * 2)
    height = pad * 2 + 36 + line_h * (len(lines) + 1)

    img = Image.new("RGB", (width, height), (12, 12, 12))
    draw = ImageDraw.Draw(img)
    draw.text((pad, pad), title, fill=(120, 200, 120), font=title_font)
    y = pad + 32
    for line in lines:
        color = (220, 220, 220)
        if line.startswith("OK") or "PASSED" in line or line.startswith("passed="):
            color = (80, 220, 120)
        elif line.startswith("FAIL") or "FAILED" in line or "failed=" in line and not line.startswith("passed="):
            color = (240, 90, 90)
        elif line.startswith("===") or line.startswith("---"):
            color = (140, 180, 255)
        draw.text((pad, y), line[:200], fill=color, font=font)
        y += line_h

    img.save(png_path)
    print(f"wrote {png_path}")


def main() -> None:
    CAPTURES.mkdir(parents=True, exist_ok=True)
    mapping = [
        ("06_tests_ml_pass.txt", "06_tests_ml_pass.png", "pytest ml — fond noir"),
        ("07_dart_analyze_pass.txt", "07_dart_analyze_pass.png", "dart analyze — fond noir"),
        ("08_e2e_auth_translate.txt", "08_e2e_auth_translate.png", "E2E auth→traduction — fond noir"),
        ("09_api_smoke.txt", "09_api_smoke.png", "API smoke — fond noir"),
        ("10_train_start.txt", "10_train_start.png", "réentraînement fingerspell — démarrage"),
        ("11_train_log.txt", "11_train_progress.png", "réentraînement fingerspell — progression"),
        ("12_train_done.txt", "12_train_done.png", "réentraînement fingerspell — terminé"),
        ("13_text_to_sign_3d_tests.txt", "13_text_to_sign_3d_tests.png", "tests mode 3D texte→signe"),
        ("14_dart_analyze_3d.txt", "14_dart_analyze_3d.png", "dart analyze — pipeline 3D"),
    ]
    for txt_name, png_name, title in mapping:
        txt = CAPTURES / txt_name
        if txt.exists():
            render(txt, CAPTURES / png_name, title)
        else:
            print(f"skip missing {txt}")


if __name__ == "__main__":
    main()
