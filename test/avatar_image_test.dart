import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:moomoo/core/utils/avatar_image.dart';
import 'package:moomoo/data/repositories/storage_repository.dart';

void main() {
  group('prepareAvatar', () {
    test('shrinks a large transparent PNG into a small white-backed JPEG', () async {
      final source = img.Image(width: 3000, height: 2000, numChannels: 4)
        ..clear(img.ColorRgba8(0, 0, 0, 0));
      final out = await prepareAvatar(Uint8List.fromList(img.encodePng(source)));

      expect(out, isNotNull);
      expect(StorageRepositoryImpl.detectImageType(out!)?.mime, 'image/jpeg');
      expect(out.length, lessThan(kMaxAvatarBytes));
      final decoded = img.decodeJpg(out)!;
      expect(decoded.width, kAvatarSize);
      expect(decoded.height, 341);
      expect(decoded.getPixel(10, 10).r, greaterThan(240));
    });

    test('converts formats the bucket refuses, such as GIF and BMP', () async {
      final source = img.Image(width: 40, height: 60)..clear(img.ColorRgb8(10, 120, 200));
      for (final encoded in [img.encodeGif(source), img.encodeBmp(source)]) {
        final out = await prepareAvatar(Uint8List.fromList(encoded));
        expect(StorageRepositoryImpl.detectImageType(out!)?.ext, 'jpg');
        expect(img.decodeJpg(out)!.width, 40);
      }
    });

    test('returns null for bytes that are not an image', () async {
      expect(await prepareAvatar(Uint8List.fromList(List.filled(64, 7))), isNull);
    });
  });
}
