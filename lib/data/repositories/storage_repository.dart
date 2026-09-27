import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/supabase_constants.dart';
import '../../core/errors/user_error.dart';

/// Largest profile photo accepted, matching the bucket limit.
const int kMaxAvatarBytes = 2 * 1024 * 1024;

abstract class StorageRepository {
  /// Stores [bytes] as the user's photo and returns its public URL, with a
  /// version parameter so caches pick up the new image.
  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String userId,
  });

  /// Removes every stored photo of the user.
  Future<void> deleteAvatar(String userId);
  Future<String> uploadContributionVideo({
    Uint8List? bytes,
    String? path,
    required String userId,
  });
  Future<void> deleteFile(String bucket, String path);
  String getPublicUrl(String bucket, String path);
}

class StorageRepositoryImpl implements StorageRepository {
  final SupabaseClient _supabase;

  StorageRepositoryImpl(this._supabase);

  /// Image type read from the file signature, not from its name.
  static ({String ext, String mime})? detectImageType(Uint8List bytes) {
    bool startsWith(List<int> sig, [int offset = 0]) =>
        bytes.length >= offset + sig.length &&
        List.generate(sig.length, (i) => bytes[offset + i] == sig[i]).every((b) => b);
    if (startsWith([0x89, 0x50, 0x4E, 0x47])) return (ext: 'png', mime: 'image/png');
    if (startsWith([0xFF, 0xD8, 0xFF])) return (ext: 'jpg', mime: 'image/jpeg');
    if (startsWith([0x52, 0x49, 0x46, 0x46]) && startsWith([0x57, 0x45, 0x42, 0x50], 8)) {
      return (ext: 'webp', mime: 'image/webp');
    }
    return null;
  }

  @override
  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String userId,
  }) async {
    if (bytes.isEmpty) throw const UserFacingException(UserErrorKind.invalidData);
    if (bytes.length > kMaxAvatarBytes) {
      throw UserFacingException(UserErrorKind.tooLarge, '${bytes.length} octets');
    }
    final type = detectImageType(bytes);
    if (type == null) throw const UserFacingException(UserErrorKind.unsupportedFormat);

    final bucket = _supabase.storage.from(SupabaseConstants.bucketAvatars);
    final storagePath = '$userId/avatar.${type.ext}';
    await bucket.uploadBinary(
      storagePath,
      bytes,
      fileOptions: FileOptions(cacheControl: '3600', upsert: true, contentType: type.mime),
    );
    // A previous photo in another format would otherwise stay in storage.
    await _removeAvatars(userId, keep: storagePath);
    final url = getPublicUrl(SupabaseConstants.bucketAvatars, storagePath);
    return '$url?v=${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<void> deleteAvatar(String userId) => _removeAvatars(userId);

  Future<void> _removeAvatars(String userId, {String? keep}) async {
    final bucket = _supabase.storage.from(SupabaseConstants.bucketAvatars);
    final files = await bucket.list(path: userId);
    final paths = files
        .map((f) => '$userId/${f.name}')
        .where((p) => p != keep)
        .toList();
    if (paths.isNotEmpty) await bucket.remove(paths);
  }

  @override
  Future<String> uploadContributionVideo({
    Uint8List? bytes,
    String? path,
    required String userId,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '$userId/contribution_$timestamp.mp4';
    final bucket = _supabase.storage.from(SupabaseConstants.bucketContributions);

    if (kIsWeb && bytes != null) {
      await bucket.uploadBinary(storagePath, bytes);
    } else if (!kIsWeb && path != null) {
      await bucket.upload(storagePath, io.File(path));
    }
    return getPublicUrl(SupabaseConstants.bucketContributions, storagePath);
  }

  @override
  Future<void> deleteFile(String bucket, String path) async {
    await _supabase.storage.from(bucket).remove([path]);
  }

  @override
  String getPublicUrl(String bucket, String path) {
    return _supabase.storage.from(bucket).getPublicUrl(path);
  }
}
