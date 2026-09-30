"""Détection de main + normalisation luminosité (alignée sur le dataset ASL).

Le preview caméra de l'app n'est jamais modifié : seul le tenseur envoyé
au modèle est recadré / recalibré.
"""

from __future__ import annotations

from dataclasses import dataclass

import numpy as np

# Moyenne mesurée sur un échantillon du jeu d'entraînement (≈130 / 255).
TARGET_MEAN = 130.0

# Au-delà : on considère une frame caméra (pas un crop alphabet déjà cadrée).
CLOSEUP_MAX_SIDE = 400


@dataclass(frozen=True)
class HandCrop:
    rgb: np.ndarray  # uint8 H×W×3
    detected: bool
    bbox: tuple[int, int, int, int] | None  # x, y, w, h


def decode_rgb(data: bytes) -> np.ndarray:
    """JPEG/PNG → RGB uint8."""
    import cv2

    arr = np.frombuffer(data, dtype=np.uint8)
    bgr = cv2.imdecode(arr, cv2.IMREAD_COLOR)
    if bgr is None:
        raise ValueError("Image illisible")
    return cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)


def _skin_mask(bgr: np.ndarray) -> np.ndarray:
    import cv2

    ycrcb = cv2.cvtColor(bgr, cv2.COLOR_BGR2YCrCb)
    mask_y = cv2.inRange(ycrcb, (0, 133, 77), (255, 173, 127))
    hsv = cv2.cvtColor(bgr, cv2.COLOR_BGR2HSV)
    mask_h = cv2.inRange(hsv, (0, 30, 40), (25, 255, 255)) | cv2.inRange(
        hsv, (160, 30, 40), (180, 255, 255)
    )
    mask = cv2.bitwise_or(mask_y, mask_h)
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (7, 7))
    mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel, iterations=1)
    mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel, iterations=2)
    return mask


def detect_hand_bbox(rgb: np.ndarray) -> tuple[int, int, int, int] | None:
    """Retourne (x, y, w, h) de la plus grande région peau, ou None."""
    import cv2

    if rgb.ndim != 3 or rgb.shape[2] != 3:
        return None
    h, w = rgb.shape[:2]
    bgr = cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR)
    mask = _skin_mask(bgr)
    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if not contours:
        return None
    best = max(contours, key=cv2.contourArea)
    area = float(cv2.contourArea(best))
    if area < (h * w) * 0.008:
        return None
    x, y, bw, bh = cv2.boundingRect(best)
    pad = int(0.18 * max(bw, bh))
    x0 = max(0, x - pad)
    y0 = max(0, y - pad)
    x1 = min(w, x + bw + pad)
    y1 = min(h, y + bh + pad)
    return x0, y0, x1 - x0, y1 - y0


def _square_crop(rgb: np.ndarray, bbox: tuple[int, int, int, int]) -> np.ndarray:
    h, w = rgb.shape[:2]
    x, y, bw, bh = bbox
    side = max(bw, bh, 1)
    cx = x + bw // 2
    cy = y + bh // 2
    side = min(side, w, h)
    x0 = max(0, min(w - side, cx - side // 2))
    y0 = max(0, min(h - side, cy - side // 2))
    return rgb[y0 : y0 + side, x0 : x0 + side]


def _center_square(rgb: np.ndarray) -> np.ndarray:
    h, w = rgb.shape[:2]
    side = min(h, w)
    x0 = (w - side) // 2
    y0 = (h - side) // 2
    return rgb[y0 : y0 + side, x0 : x0 + side]


def match_training_brightness(rgb: np.ndarray, target_mean: float = TARGET_MEAN) -> np.ndarray:
    """Recale la luminosité moyenne vers celle des images d'entraînement.

    Opération invisible pour l'utilisateur (preview inchangé).
    """
    arr = rgb.astype(np.float32)
    mean = float(arr.mean())
    if mean < 1e-3:
        return rgb
    # Décalage + échelle douce : gère scènes très sombres sans saturer.
    delta = target_mean - mean
    scale = 1.0 + 0.35 * (delta / max(target_mean, 1.0))
    scale = float(np.clip(scale, 0.65, 1.75))
    out = arr * scale + delta * 0.55
    # Seconde passe légère pour coller la moyenne cible.
    m2 = float(out.mean())
    if m2 > 1e-3:
        out *= target_mean / m2
    return np.clip(out, 0, 255).astype(np.uint8)


def prepare_hand_image(data: bytes) -> HandCrop:
    """Décode, détecte la main si besoin, crop carré, normalise la luminosité."""
    rgb = decode_rgb(data)
    h, w = rgb.shape[:2]
    # Images déjà type dataset (petite, quasi carrée) : pas de re-crop agressif.
    if max(h, w) <= CLOSEUP_MAX_SIDE:
        crop = _center_square(rgb) if h != w else rgb
        return HandCrop(
            rgb=match_training_brightness(crop),
            detected=True,
            bbox=None,
        )

    bbox = detect_hand_bbox(rgb)
    if bbox is None:
        crop = _center_square(rgb)
        return HandCrop(rgb=match_training_brightness(crop), detected=False, bbox=None)
    crop = _square_crop(rgb, bbox)
    return HandCrop(rgb=match_training_brightness(crop), detected=True, bbox=bbox)
