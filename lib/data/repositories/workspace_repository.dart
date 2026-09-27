import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/sign_category.dart';
import '../models/workspace_overview.dart';
import '../services/api_client.dart';

/// Role spaces (teacher, sign expert) and dictionary tooling. Every call runs
/// under the user's JWT: row level security and the SQL guards decide.
class WorkspaceRepository {
  WorkspaceRepository(this._supabase, {ApiClient? api})
      : _api = api ?? ApiClient(timeout: const Duration(minutes: 5));

  final SupabaseClient _supabase;
  final ApiClient _api;

  String get _accessToken {
    final token = _supabase.auth.currentSession?.accessToken;
    if (token == null || token.isEmpty) {
      throw ApiException(401, 'Session expirée', code: 'unauthenticated');
    }
    return token;
  }

  Future<List<String>> currentRoles() async {
    if (_supabase.auth.currentUser == null) return const [];
    final result = await _supabase.rpc('current_user_roles');
    return [for (final r in (result as List? ?? const [])) '$r'];
  }

  Future<TeacherOverview> teacherOverview() async {
    final result = await _supabase.rpc('teacher_overview');
    return TeacherOverview.fromJson(Map<String, dynamic>.from(result as Map));
  }

  Future<ExpertOverview> expertOverview() async {
    final result = await _supabase.rpc('expert_overview');
    return ExpertOverview.fromJson(Map<String, dynamic>.from(result as Map));
  }

  // -------------------------------------------------------------------------
  // Categories
  // -------------------------------------------------------------------------
  Future<List<SignCategory>> categories(int languageId) async {
    final rows = await _supabase
        .from('sign_categories')
        .select()
        .eq('sign_language_id', languageId)
        .order('order_index')
        .order('name');
    return [for (final r in rows) SignCategory.fromJson(r)];
  }

  Future<SignCategory> saveCategory({
    int? id,
    required String name,
    required int languageId,
    required String languageCode,
  }) async {
    final trimmed = name.trim();
    if (id != null) {
      final rows = await _supabase
          .from('sign_categories')
          .update({'name': trimmed})
          .eq('id', id)
          .select();
      if (rows.isEmpty) throw const PostgrestException(message: 'Modification refusée', code: '42501');
      return SignCategory.fromJson(rows.first);
    }
    final base = '${_slug(trimmed)}-${_slug(languageCode)}';
    for (var n = 1; n < 20; n++) {
      final slug = n == 1 ? base : '$base-$n';
      try {
        final row = await _supabase
            .from('sign_categories')
            .insert({'name': trimmed, 'slug': slug, 'sign_language_id': languageId})
            .select()
            .single();
        return SignCategory.fromJson(row);
      } on PostgrestException catch (e) {
        if (e.code != '23505') rethrow;
      }
    }
    throw const PostgrestException(message: 'Identifiant de catégorie indisponible');
  }

  /// Signs of a deleted category are kept, uncategorised (admins only).
  Future<void> deleteCategory(int id) async {
    await _supabase.from('signs').update({'category_id': null}).eq('category_id', id);
    final rows = await _supabase.from('sign_categories').delete().eq('id', id).select('id');
    if (rows.isEmpty) throw const PostgrestException(message: 'Suppression refusée', code: '42501');
  }

  Future<int> countSignsInCategory(int id) {
    return _supabase.from('signs').count(CountOption.exact).eq('category_id', id);
  }

  /// Uploads a sign video or thumbnail and returns its public URL.
  Future<String> uploadSignMedia(Uint8List bytes, String filename, {required bool video}) async {
    final ext = filename.contains('.') ? filename.split('.').last.toLowerCase() : '';
    final contentType = switch (ext) {
      'mp4' => 'video/mp4',
      'webm' => 'video/webm',
      'mov' => 'video/quicktime',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => throw ArgumentError('Format non pris en charge : .$ext'),
    };
    if (video != contentType.startsWith('video/')) {
      throw ArgumentError('Format non pris en charge : .$ext');
    }
    final bucket = video ? 'sign-videos' : 'sign-thumbnails';
    final path = 'manual/${const Uuid().v4()}.$ext';
    await _supabase.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );
    return _supabase.storage.from(bucket).getPublicUrl(path);
  }

  // -------------------------------------------------------------------------
  // Import (Node API: parsing, validation and media download are server-side)
  // -------------------------------------------------------------------------
  Future<Map<String, dynamic>> previewImport({
    required String filename,
    required String content,
    Map<String, String>? mapping,
    required Map<String, dynamic> options,
  }) {
    return _api.postJson(
      '/api/dictionary/import/preview',
      accessToken: _accessToken,
      body: {'filename': filename, 'content': content, 'mapping': ?mapping, 'options': options},
    );
  }

  Future<Map<String, dynamic>> commitImport({
    required String filename,
    required String content,
    required Map<String, String> mapping,
    required Map<String, dynamic> options,
  }) {
    return _api.postJson(
      '/api/dictionary/import/commit',
      accessToken: _accessToken,
      body: {'filename': filename, 'content': content, 'mapping': mapping, 'options': options},
    );
  }

  static String _slug(String value) {
    const accents = {
      'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ç': 'c', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'î': 'i', 'ï': 'i', 'í': 'i', 'ô': 'o', 'ö': 'o', 'ó': 'o', 'ù': 'u', 'û': 'u', 'ü': 'u',
      'ú': 'u', 'ÿ': 'y', 'ñ': 'n', 'œ': 'oe', 'æ': 'ae',
    };
    final lower = value.toLowerCase().split('').map((c) => accents[c] ?? c).join();
    return lower.replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
  }
}
