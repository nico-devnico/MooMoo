import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Convertit une [CameraImage] (BGRA / YUV / NV21) en JPEG RGB.
Future<Uint8List?> cameraImageToJpeg(CameraImage image, {int quality = 80}) async {
  try {
    return await compute(
      _convertIsolate,
      _ConvertArgs(
        width: image.width,
        height: image.height,
        format: image.format.group.index,
        planes: [
          for (final p in image.planes)
            _PlaneData(
              bytes: Uint8List.fromList(p.bytes),
              bytesPerRow: p.bytesPerRow,
              bytesPerPixel: p.bytesPerPixel ?? 1,
            ),
        ],
        quality: quality,
      ),
    );
  } catch (e) {
    debugPrint('[camera] convert failed: $e');
    return null;
  }
}

class _ConvertArgs {
  const _ConvertArgs({
    required this.width,
    required this.height,
    required this.format,
    required this.planes,
    required this.quality,
  });

  final int width;
  final int height;
  final int format;
  final List<_PlaneData> planes;
  final int quality;
}

class _PlaneData {
  const _PlaneData({
    required this.bytes,
    required this.bytesPerRow,
    required this.bytesPerPixel,
  });

  final Uint8List bytes;
  final int bytesPerRow;
  final int bytesPerPixel;
}

Uint8List? _convertIsolate(_ConvertArgs args) {
  final group = ImageFormatGroup.values[args.format];
  // Déjà un JPEG natif (Android ImageFormat.JPEG).
  if (group == ImageFormatGroup.jpeg && args.planes.isNotEmpty) {
    return args.planes.first.bytes;
  }
  img.Image? rgb;
  if (group == ImageFormatGroup.bgra8888 && args.planes.isNotEmpty) {
    rgb = img.Image.fromBytes(
      width: args.width,
      height: args.height,
      bytes: args.planes.first.bytes.buffer,
      order: img.ChannelOrder.bgra,
      rowStride: args.planes.first.bytesPerRow,
    );
  } else if (group == ImageFormatGroup.yuv420 && args.planes.length >= 3) {
    rgb = _yuv420ToImage(args);
  } else if (group == ImageFormatGroup.nv21 && args.planes.isNotEmpty) {
    rgb = _nv21ToImage(args);
  }
  if (rgb == null) return null;
  final maxSide = rgb.width > rgb.height ? rgb.width : rgb.height;
  final small = maxSide > 480
      ? img.copyResize(
          rgb,
          width: rgb.width >= rgb.height ? 480 : null,
          height: rgb.height > rgb.width ? 480 : null,
        )
      : rgb;
  return Uint8List.fromList(img.encodeJpg(small, quality: args.quality));
}

img.Image _yuv420ToImage(_ConvertArgs args) {
  final w = args.width;
  final h = args.height;
  final yPlane = args.planes[0];
  final uPlane = args.planes[1];
  final vPlane = args.planes[2];
  final out = img.Image(width: w, height: h);
  final uvRowStride = uPlane.bytesPerRow;
  final uvPixelStride = uPlane.bytesPerPixel;

  for (var y = 0; y < h; y++) {
    final yRow = y * yPlane.bytesPerRow;
    for (var x = 0; x < w; x++) {
      final yp = yPlane.bytes[yRow + x];
      final uvIndex = uvPixelStride * (x ~/ 2) + uvRowStride * (y ~/ 2);
      final up = uPlane.bytes[uvIndex.clamp(0, uPlane.bytes.length - 1)];
      final vp = vPlane.bytes[uvIndex.clamp(0, vPlane.bytes.length - 1)];
      final r = (yp + 1.370705 * (vp - 128)).round().clamp(0, 255);
      final g = (yp - 0.337633 * (up - 128) - 0.698001 * (vp - 128))
          .round()
          .clamp(0, 255);
      final b = (yp + 1.732446 * (up - 128)).round().clamp(0, 255);
      out.setPixelRgb(x, y, r, g, b);
    }
  }
  return out;
}

img.Image _nv21ToImage(_ConvertArgs args) {
  final w = args.width;
  final h = args.height;
  final bytes = args.planes.first.bytes;
  final out = img.Image(width: w, height: h);
  final ySize = w * h;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final yi = y * w + x;
      final yp = bytes[yi];
      final uvIndex = ySize + (y >> 1) * w + (x & ~1);
      if (uvIndex + 1 >= bytes.length) {
        out.setPixelRgb(x, y, yp, yp, yp);
        continue;
      }
      final v = bytes[uvIndex];
      final u = bytes[uvIndex + 1];
      final r = (yp + 1.370705 * (v - 128)).round().clamp(0, 255);
      final g = (yp - 0.337633 * (u - 128) - 0.698001 * (v - 128))
          .round()
          .clamp(0, 255);
      final b = (yp + 1.732446 * (u - 128)).round().clamp(0, 255);
      out.setPixelRgb(x, y, r, g, b);
    }
  }
  return out;
}
