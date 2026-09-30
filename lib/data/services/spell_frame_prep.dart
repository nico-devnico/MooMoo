import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Recadre le centre de la frame (main face à la caméra) avant envoi ML.
///
/// Le modèle ASL a été entraîné sur des mains cadrées : envoyer le plein
/// écran biaise vers N/M/P/Z. On envoie un crop centre assez grand pour
/// que le service ML puisse encore détecter la peau (pas un 64×64 pré-mâché).
Uint8List prepareSpellFrameBytes(List<int> raw, {String filename = 'frame.jpg'}) {
  final decoded = img.decodeImage(Uint8List.fromList(raw));
  if (decoded == null) return Uint8List.fromList(raw);

  final w = decoded.width;
  final h = decoded.height;
  // Déjà un crop compact (import dataset) : ne pas re-cadrer.
  if (w <= 220 && h <= 220) {
    return Uint8List.fromList(img.encodeJpg(decoded, quality: 92));
  }

  final side = ((w < h ? w : h) * 0.78).round().clamp(1, w < h ? w : h);
  final x0 = ((w - side) / 2).round().clamp(0, w - side);
  final y0 = ((h - side) / 2).round().clamp(0, h - side);
  final cropped = img.copyCrop(
    decoded,
    x: x0,
    y: y0,
    width: side,
    height: side,
  );

  // Max 512 px : assez pour la détection peau côté serveur, POST raisonnable.
  final out = side > 512
      ? img.copyResize(cropped, width: 512, height: 512)
      : cropped;
  return Uint8List.fromList(img.encodeJpg(out, quality: 90));
}
