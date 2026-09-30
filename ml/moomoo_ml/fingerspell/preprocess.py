"""Prétraitement main pour l'épellation ASL.

Le modèle a ~99,9 % sur des crops type dataset (main cadrée, fond simple).
Les frames caméra pleine résolution doivent être ramenées à ce format :
détection main centrée, crop carré serré, luminosité douce.
"""

from __future__ import annotations

from dataclasses import dataclass

import numpy as np

TARGET_MEAN = 130.0
BRIGHTNESS_TOLERANCE = 35.0
# Vrais crops dataset (~200px) ; au-delà on traite comme frame caméra.
CLOSEUP_MAX_SIDE = 220


@dataclass(frozen=True)
class HandCrop:
    rgb: np.ndarray  # uint8 H×W×3
    detected: bool
    bbox: tuple[int, int, int, int] | None


def decode_rgb(data: bytes) -> np.ndarray:
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
    mask_h = cv2.inRange(hsv, (0, 25, 50), (30, 255, 255)) | cv2.inRange(
        hsv, (155, 25, 50), (180, 255, 255)
    )
    mask = cv2.bitwise_or(mask_y, mask_h)
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
    mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel, iterations=1)
    mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel, iterations=2)
    return mask


def _score_contour(contour, frame_h: int, frame_w: int) -> float:
    """Préfère une grosse tache peau proche du centre (main), pas le visage en haut."""
    import cv2

    area = float(cv2.contourArea(contour))
    if area <= 0:
        return -1.0
    x, y, bw, bh = cv2.boundingRect(contour)
    cx = x + bw / 2.0
    cy = y + bh / 2.0
    dx = abs(cx - frame_w / 2.0) / max(frame_w / 2.0, 1.0)
    dy = abs(cy - frame_h * 0.55) / max(frame_h / 2.0, 1.0)
    center_penalty = dx * dx + dy * dy
    top_penalty = 0.35 if cy < frame_h * 0.28 else 0.0
    return area * (1.0 - 0.55 * center_penalty) - top_penalty * area


def detect_hand_bbox(rgb: np.ndarray) -> tuple[int, int, int, int] | None:
    import cv2

    if rgb.ndim != 3 or rgb.shape[2] != 3:
        return None
    h, w = rgb.shape[:2]
    bgr = cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR)
    mask = _skin_mask(bgr)
    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if not contours:
        return None
    best = max(contours, key=lambda c: _score_contour(c, h, w))
    if _score_contour(best, h, w) <= 0:
        return None
    area = float(cv2.contourArea(best))
    if area < (h * w) * 0.006:
        return None
    x, y, bw, bh = cv2.boundingRect(best)
    pad = int(0.22 * max(bw, bh))
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


def _center_square(rgb: np.ndarray, fraction: float = 1.0) -> np.ndarray:
    h, w = rgb.shape[:2]
    side = int(min(h, w) * max(0.35, min(fraction, 1.0)))
    x0 = (w - side) // 2
    y0 = (h - side) // 2
    return rgb[y0 : y0 + side, x0 : x0 + side]


def match_training_brightness(rgb: np.ndarray, target_mean: float = TARGET_MEAN) -> np.ndarray:
    """Correction douce près de la cible ; plus forte si très sombre/clair.

    Une retouche trop agressive sur des frames déjà correctes biaise vers
    N/M/P/Z, mais un crop caméra trop sombre doit quand même remonter.
    """
    arr = rgb.astype(np.float32)
    mean = float(arr.mean())
    if mean < 1e-3:
        return rgb
    if abs(mean - target_mean) <= BRIGHTNESS_TOLERANCE:
        return rgb
    delta = target_mean - mean
    strength = float(np.clip(abs(delta) / 90.0, 0.25, 1.0))
    scale = float(
        np.clip(1.0 + 0.45 * strength * (delta / max(target_mean, 1.0)), 0.72, 1.75)
    )
    out = arr * scale + delta * (0.15 + 0.55 * strength)
    m2 = float(out.mean())
    if m2 > 1e-3 and abs(m2 - target_mean) > 22:
        out *= target_mean / m2
    return np.clip(out, 0, 255).astype(np.uint8)


def prepare_hand_image(data: bytes) -> HandCrop:
    """Produit un crop proche du format d'entraînement."""
    rgb = decode_rgb(data)
    h, w = rgb.shape[:2]

    if max(h, w) <= CLOSEUP_MAX_SIDE:
        crop = _center_square(rgb) if h != w else rgb
        return HandCrop(rgb=match_training_brightness(crop), detected=True, bbox=None)

    center = _center_square(rgb, fraction=0.72)
    bbox = detect_hand_bbox(rgb)
    if bbox is not None:
        hand = _square_crop(rgb, bbox)
        if hand.shape[0] < 48 or hand.shape[1] < 48:
            hand = center
            detected = False
            bbox = None
        else:
            detected = True
    else:
        hand = center
        detected = False

    return HandCrop(rgb=match_training_brightness(hand), detected=detected, bbox=bbox)


def candidate_crops(data: bytes) -> list[HandCrop]:
    """Plusieurs candidats pour choisir la prédiction la plus fiable.

    Évite le biais N/M/P/Z quand un seul crop peau est mauvais.
    """
    rgb = decode_rgb(data)
    h, w = rgb.shape[:2]
    out: list[HandCrop] = []

    if max(h, w) <= CLOSEUP_MAX_SIDE:
        # Crop client déjà main-only : une seule passe (vitesse live).
        crop = _center_square(rgb) if h != w else rgb
        out.append(HandCrop(rgb=match_training_brightness(crop), detected=True, bbox=None))
        return out

    primary = prepare_hand_image(data)
    out.append(primary)

    # Live plein cadre : 2 candidats max (centre + peau) pour la latence.
    for frac in (0.65, 0.80):
        center = _center_square(rgb, fraction=frac)
        bbox = detect_hand_bbox(center)
        if bbox is not None:
            hand = _square_crop(center, bbox)
            if hand.shape[0] >= 40:
                out.append(
                    HandCrop(
                        rgb=match_training_brightness(hand),
                        detected=True,
                        bbox=bbox,
                    )
                )
                break
        out.append(HandCrop(rgb=match_training_brightness(center), detected=False, bbox=None))

    seen: set[tuple[int, int]] = set()
    unique: list[HandCrop] = []
    for crop in out:
        key = (crop.rgb.shape[0], crop.rgb.shape[1])
        if key in seen and not crop.detected:
            continue
        seen.add(key)
        unique.append(crop)
    return unique[:3]
