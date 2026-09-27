import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/translation_entry.dart';

const translationEntryColumns =
    'id,session_id,user_id,direction,source_text,source_video_url,'
    'source_audio_url,translated_text,translated_audio_url,sign_ids,'
    'user_rating,note,created_at';

/// `translation_sessions` n'a pas de colonne `created_at` (elle s'appelle
/// `started_at`) : l'alias PostgREST garde le contrat attendu par l'écran
/// d'historique tout en triant sur la vraie colonne.
const translationSessionColumns =
    'id,session_type,title,status,total_entries,created_at:started_at';

abstract class SessionRepository {
  Future<String> createSession({
    required String userId,
    required String sessionType,
    int? signLanguageId,
    String? title,
  });
  Future<void> addEntry(TranslationEntry entry);
  Future<List<TranslationEntry>> getSessionEntries(
    String sessionId, {
    int limit = 200,
    int offset = 0,
  });
  Stream<List<TranslationEntry>> watchSessionEntries(String sessionId);
  Future<List<Map<String, dynamic>>> getUserHistory(
    String userId, {
    int limit = 30,
    int offset = 0,
  });
}

class SessionRepositoryImpl implements SessionRepository {
  final SupabaseClient _supabase;

  SessionRepositoryImpl(this._supabase);

  /// L'historique n'affiche qu'une ligne de résumé par session : on ne charge
  /// que la dernière entrée de chaque session au lieu de toutes ses entrées.
  @override
  Future<List<Map<String, dynamic>>> getUserHistory(
    String userId, {
    int limit = 30,
    int offset = 0,
  }) async {
    final response = await _supabase
        .from('translation_sessions')
        .select('$translationSessionColumns,'
            'translation_entries(translated_text,created_at)')
        .eq('user_id', userId)
        .order('created_at', referencedTable: 'translation_entries', ascending: false)
        .limit(1, referencedTable: 'translation_entries')
        .order('started_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<String> createSession({
    required String userId,
    required String sessionType,
    int? signLanguageId,
    String? title,
  }) async {
    final response = await _supabase.from('translation_sessions').insert({
      'user_id': userId,
      'session_type': sessionType,
      'sign_language_id': signLanguageId,
      'title': title,
    }).select('id').single();

    return response['id'] as String;
  }

  @override
  Future<void> addEntry(TranslationEntry entry) async {
    await _supabase.from('translation_entries').insert(entry.toJson());
  }

  @override
  Future<List<TranslationEntry>> getSessionEntries(
    String sessionId, {
    int limit = 200,
    int offset = 0,
  }) async {
    final response = await _supabase
        .from('translation_entries')
        .select(translationEntryColumns)
        .eq('session_id', sessionId)
        .order('created_at')
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => TranslationEntry.fromJson(json as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Stream<List<TranslationEntry>> watchSessionEntries(String sessionId) {
    return _supabase
        .from('translation_entries')
        .stream(primaryKey: ['id'])
        .eq('session_id', sessionId)
        .order('created_at')
        .limit(200)
        .map((data) => data
            .map((json) => TranslationEntry.fromJson(json))
            .toList(growable: false));
  }
}
