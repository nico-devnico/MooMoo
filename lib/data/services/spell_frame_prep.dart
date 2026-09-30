import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Détection peau + recadrage main pour l'épellation live.
///
/// Le preview caméra reste plein cadre ; seul ce JPEG compact part au ML.
class HandCropResult {
  const HandCropResult({
    required this.jpeg,
    required this.detected,
    this.bbox,
  });

  final Uint8List jpeg;
  final bool detected;
  final ({int x, int y, int w, int h})? bbox;
}

/// Prépare une frame pour le modèle : détecte la main, croppe uniquement
/// cette zone (sinon centre), redimensionne à [outSize] pour la vitesse.
HandCropResult prepareHandSpellFrame(
  List<int> raw, {
  int outSize = 160,
  int jpegQuality = 82,
}) {
  final decoded = img.decodeImage(Uint8List.fromList(raw));
  if (decoded == null) {
    return HandCropResult(jpeg: Uint8List.fromList(raw), detected: false);
  }

  // Downscale rapide avant détection (latence).
  final maxSide = math.max(decoded.width, decoded.height);
  final work = maxSide > 480
      ? img.copyResize(
          decoded,
          width: decoded.width > decoded.height
              ? 480
              : (decoded.width * 480 / decoded.height).round(),
          height: decoded.height >= decoded.width
              ? 480
              : (decoded.height * 480 / decoded.width).round(),
        )
      : decoded;

  final bbox = _detectHandBBox(work);
  img.Image crop;
  var detected = false;
  if (bbox != null) {
    final side = math.max(bbox.w, bbox.h);
    final pad = (side * 0.22).round();
    final cx = bbox.x + bbox.w ~/ 2;
    final cy = bbox.y + bbox.h ~/ 2;
    final s = math.min(work.width, math.min(work.height, side + 2 * pad));
    final x0 = (cx - s ~/ 2).clamp(0, work.width - s);
    final y0 = (cy - s ~/ 2).clamp(0, work.height - s);
    crop = img.copyCrop(work, x: x0, y: y0, width: s, height: s);
    detected = s >= 40;
  } else {
    // Repli : centre (main face à la caméra).
    final s = (math.min(work.width, work.height) * 0.72).round();
    final x0 = (work.width - s) ~/ 2;
    final y0 = (work.height - s) ~/ 2;
    crop = img.copyCrop(work, x: x0, y: y0, width: s, height: s);
  }

  final sized = img.copyResize(crop, width: outSize, height: outSize);
  final jpeg = Uint8List.fromList(img.encodeJpg(sized, quality: jpegQuality));
  return HandCropResult(jpeg: jpeg, detected: detected, bbox: bbox);
}

/// API historique : bytes JPEG prêts pour `/infer/spell`.
Uint8List prepareSpellFrameBytes(List<int> raw, {String filename = 'frame.jpg'}) {
  return prepareHandSpellFrame(raw).jpeg;
}

({int x, int y, int w, int h})? _detectHandBBox(img.Image src) {
  final w = src.width;
  final h = src.height;
  if (w < 16 || h < 16) return null;

  // Grille pour vitesse (pas pixel-par-pixel plein).
  const step = 2;
  var minX = w, minY = h, maxX = 0, maxY = 0;
  var count = 0;
  double sumX = 0, sumY = 0;

  for (var y = 0; y < h; y += step) {
    for (var x = 0; x < w; x += step) {
      final p = src.getPixel(x, y);
      final r = p.r.toInt();
      final g = p.g.toInt();
      final b = p.b.toInt();
      if (!_isSkin(r, g, b)) continue;
      // Pénalise le haut du cadre (visage).
      if (y < h * 0.22) continue;
      count++;
      sumX += x;
      sumY += y;
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    }
  }

  final area = (maxX - minX) * (maxY - minY);
  if (count < 40 || area < (w * h) * 0.008) return null;

  // Centre de masse : affine le bbox vers la tache dominante.
  final cx = (sumX / count).round();
  final cy = (sumY / count).round();
  final bw = (maxX - minX).clamp(24, w);
  final bh = (maxY - minY).clamp(24, h);
  // Préfère une zone centrée (main) vs coin.
  final preferCx = (cx * 0.65 + (minX + maxX) / 2 * 0.35).round();
  final preferCy = (cy * 0.65 + (minY + maxY) / 2 * 0.35).round();
  final x0 = (preferCx - bw ~/ 2).clamp(0, w - bw);
  final y0 = (preferCy - bh ~/ 2).clamp(0, h - bh);
  return (x: x0, y: y0, w: bw, h: bh);
}

bool _isSkin(int r, int g, int b) {
  // Heuristique YCrCb / RGB classique (peau).
  final y = 0.299 * r + 0.587 * g + 0.114 * b;
  final cr = r - y;
  final cb = b - y;
  final yOk = y > 40 && y < 250;
  final crOk = cr > 10 && cr < 85;
  final cbOk = cb > -80 && cb < -5;
  final rgbOk = r > 60 && g > 30 && b > 15 && r > g && r > b && (r - g) > 8;
  return yOk && ((crOk && cbOk) || rgbOk);
}
