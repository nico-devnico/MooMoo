import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Détection peau + recadrage main — même pipeline import et live.
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

/// Prépare une frame pour le modèle (import image OU caméra live).
///
/// - [mirrorHorizontal] : caméra frontale (selfie) pour coller au jeu d'entraînement
/// - [outSize] ≥ 256 : le serveur peut encore affiner le crop (CLOSEUP_MAX=220)
/// Si aucune main n'est détectée, [detected] vaut false (le client enverra « space »).
HandCropResult prepareHandSpellFrame(
  List<int> raw, {
  int outSize = 256,
  int jpegQuality = 90,
  bool mirrorHorizontal = false,
}) {
  var decoded = img.decodeImage(Uint8List.fromList(raw));
  if (decoded == null) {
    return HandCropResult(jpeg: Uint8List.fromList(raw), detected: false);
  }

  if (mirrorHorizontal) {
    decoded = img.flipHorizontal(decoded);
  }

  final maxSide = math.max(decoded.width, decoded.height);
  // Déjà un crop type dataset : ne pas re-cadrer agressivement.
  if (maxSide <= 220) {
    final square = decoded.width == decoded.height
        ? decoded
        : _centerSquare(decoded, 1.0);
    final sized = outSize > 0 && math.max(square.width, square.height) != outSize
        ? img.copyResize(square, width: outSize, height: outSize)
        : square;
    return HandCropResult(
      jpeg: Uint8List.fromList(img.encodeJpg(sized, quality: jpegQuality)),
      detected: true,
    );
  }

  final work = maxSide > 640
      ? img.copyResize(
          decoded,
          width: decoded.width >= decoded.height
              ? 640
              : (decoded.width * 640 / decoded.height).round(),
          height: decoded.height > decoded.width
              ? 640
              : (decoded.height * 640 / decoded.width).round(),
        )
      : decoded;

  final bbox = _detectHandBBox(work);
  if (bbox == null) {
    // Pas de main : JPEG centre uniquement pour debug ; detected=false.
    final center = _centerSquare(work, 0.72);
    final sized = img.copyResize(center, width: outSize, height: outSize);
    return HandCropResult(
      jpeg: Uint8List.fromList(img.encodeJpg(sized, quality: jpegQuality)),
      detected: false,
    );
  }

  final side = math.max(bbox.w, bbox.h);
  final pad = (side * 0.28).round();
  final cx = bbox.x + bbox.w ~/ 2;
  final cy = bbox.y + bbox.h ~/ 2;
  final s = math.min(work.width, math.min(work.height, side + 2 * pad));
  final x0 = (cx - s ~/ 2).clamp(0, work.width - s).toInt();
  final y0 = (cy - s ~/ 2).clamp(0, work.height - s).toInt();
  final crop = img.copyCrop(work, x: x0, y: y0, width: s, height: s);
  final sized = img.copyResize(crop, width: outSize, height: outSize);
  return HandCropResult(
    jpeg: Uint8List.fromList(img.encodeJpg(sized, quality: jpegQuality)),
    detected: s >= 48,
    bbox: bbox,
  );
}

Uint8List prepareSpellFrameBytes(List<int> raw, {String filename = 'frame.jpg'}) {
  return prepareHandSpellFrame(raw).jpeg;
}

img.Image _centerSquare(img.Image src, double fraction) {
  final maxSide = math.min(src.width, src.height);
  final side = (maxSide * fraction).round().clamp(1, maxSide).toInt();
  final x0 = (src.width - side) ~/ 2;
  final y0 = (src.height - side) ~/ 2;
  return img.copyCrop(src, x: x0, y: y0, width: side, height: side);
}

({int x, int y, int w, int h})? _detectHandBBox(img.Image src) {
  final w = src.width;
  final h = src.height;
  if (w < 16 || h < 16) return null;

  const step = 2;
  var minX = w, minY = h, maxX = 0, maxY = 0;
  var count = 0;
  double sumX = 0, sumY = 0;
  // Score centre : préfère la main au milieu / bas du cadre.
  final midX = w / 2.0;
  final midY = h * 0.55;

  for (var y = 0; y < h; y += step) {
    for (var x = 0; x < w; x += step) {
      final p = src.getPixel(x, y);
      final r = p.r.toInt();
      final g = p.g.toInt();
      final b = p.b.toInt();
      if (!_isSkin(r, g, b)) continue;
      if (y < h * 0.20) continue; // visage
      final dx = (x - midX) / midX;
      final dy = (y - midY) / (h / 2.0);
      final centerWeight = 1.0 - 0.45 * (dx * dx + dy * dy).clamp(0.0, 1.0);
      count += 1;
      sumX += x * centerWeight;
      sumY += y * centerWeight;
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    }
  }

  final area = (maxX - minX) * (maxY - minY);
  if (count < 50 || area < (w * h) * 0.01) return null;

  final cx = (sumX / count).round();
  final cy = (sumY / count).round();
  final bw = (maxX - minX).clamp(32, w).toInt();
  final bh = (maxY - minY).clamp(32, h).toInt();
  final x0 = (cx - bw ~/ 2).clamp(0, w - bw).toInt();
  final y0 = (cy - bh ~/ 2).clamp(0, h - bh).toInt();
  return (x: x0, y: y0, w: bw, h: bh);
}

bool _isSkin(int r, int g, int b) {
  final y = 0.299 * r + 0.587 * g + 0.114 * b;
  final cr = r - y;
  final cb = b - y;
  final yOk = y > 40 && y < 250;
  final crOk = cr > 8 && cr < 90;
  final cbOk = cb > -85 && cb < -2;
  final rgbOk = r > 55 && g > 28 && b > 12 && r > g && r > b && (r - g) > 6;
  return yOk && ((crOk && cbOk) || rgbOk);
}
