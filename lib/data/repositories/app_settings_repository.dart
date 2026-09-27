import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/app_settings.dart';

class AppSettingsRepository {
  AppSettingsRepository(this._supabase);

  final SupabaseClient _supabase;

  static const _brandingBucket = 'branding';

  Future<AppSettings> fetch() async {
    final row = await _supabase.from('app_settings').select().eq('id', true).maybeSingle();
    return row == null ? const AppSettings() : AppSettings.fromJson(row);
  }

  /// Live updates, so maintenance and branding changes reach open sessions.
  Stream<AppSettings> watch() {
    return _supabase
        .from('app_settings')
        .stream(primaryKey: ['id'])
        .eq('id', true)
        .map((rows) => rows.isEmpty ? const AppSettings() : AppSettings.fromJson(rows.first));
  }

  /// RLS only lets administrators update; a refused update returns no row.
  Future<AppSettings> save(AppSettings settings) async {
    final rows = await _supabase
        .from('app_settings')
        .update(settings.toUpdateJson())
        .eq('id', true)
        .select();
    if (rows.isEmpty) {
      throw const PostgrestException(
        message: 'Mise à jour refusée : droits administrateur requis',
        code: '42501',
      );
    }
    return AppSettings.fromJson(rows.first);
  }

  Future<String> uploadLogo(Uint8List bytes, String extension) async {
    final ext = extension.toLowerCase().replaceAll('jpeg', 'jpg');
    final contentType = switch (ext) {
      'png' => 'image/png',
      'jpg' => 'image/jpeg',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => throw ArgumentError('Format de logo non pris en charge : $extension'),
    };
    final path = 'logo/${const Uuid().v4()}.$ext';
    await _supabase.storage.from(_brandingBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );
    return _supabase.storage.from(_brandingBucket).getPublicUrl(path);
  }
}
