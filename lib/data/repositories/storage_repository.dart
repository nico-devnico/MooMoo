import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/supabase_constants.dart';

abstract class StorageRepository {
  Future<String> uploadAvatar({
    Uint8List? bytes,
    String? path,
    required String userId,
  });
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

  @override
  Future<String> uploadAvatar({
    Uint8List? bytes,
    String? path,
    required String userId,
  }) async {
    final storagePath = '$userId/avatar.png';
    final bucket = _supabase.storage.from(SupabaseConstants.bucketAvatars);
    
    if (kIsWeb && bytes != null) {
      await bucket.uploadBinary(
        storagePath,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );
    } else if (!kIsWeb && path != null) {
      await bucket.upload(
        storagePath,
        io.File(path),
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );
    }
    return getPublicUrl(SupabaseConstants.bucketAvatars, storagePath);
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
