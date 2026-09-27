import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Longest side of a stored profile photo.
const int kAvatarSize = 512;

/// Turns any common image (JPEG, PNG, WebP, GIF, BMP, TIFF...) into a small
/// square-bounded JPEG, so a large camera photo or an unusual format still
/// fits the storage rules (2 MB, JPEG/PNG/WebP). Returns null when the bytes
/// are not a readable image.
///
/// The image picker only resizes on mobile; on the web and desktop the
/// original file comes through untouched, hence this step.
Future<Uint8List?> prepareAvatar(Uint8List bytes) => compute(_prepare, bytes);

Uint8List? _prepare(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;

  var image = img.bakeOrientation(decoded);
  if (image.width > kAvatarSize || image.height > kAvatarSize) {
    image = image.width >= image.height
        ? img.copyResize(image, width: kAvatarSize, interpolation: img.Interpolation.average)
        : img.copyResize(image, height: kAvatarSize, interpolation: img.Interpolation.average);
  }
  if (image.hasAlpha) {
    // JPEG has no transparency: flatten on white rather than black.
    final background = img.Image(width: image.width, height: image.height)
      ..clear(img.ColorRgb8(255, 255, 255));
    image = img.compositeImage(background, image);
  }
  return img.encodeJpg(image, quality: 85);
}
