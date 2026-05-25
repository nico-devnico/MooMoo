import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/translation_entry.dart';

abstract class SessionRepository {
  Future<String> createSession({
    required String userId,
    required String sessionType,
    int? signLanguageId,
    String? title,
  });
  Future<void> addEntry(TranslationEntry entry);
  Future<List<TranslationEntry>> getSessionEntries(String sessionId);
  Stream<List<TranslationEntry>> watchSessionEntries(String sessionId);
  Future<List<Map<String, dynamic>>> getUserHistory(String userId);
}

class SessionRepositoryImpl implements SessionRepository {
  final SupabaseClient _supabase;

  SessionRepositoryImpl(this._supabase);

  @override
  Future<List<Map<String, dynamic>>> getUserHistory(String userId) async {
    final response = await _supabase
        .from('translation_sessions')
        .select('*, translation_entries(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
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
  Future<List<TranslationEntry>> getSessionEntries(String sessionId) async {
    final response = await _supabase
        .from('translation_entries')
        .select()
        .eq('session_id', sessionId)
        .order('created_at');
    
    return (response as List).map((json) => TranslationEntry.fromJson(json)).toList();
  }

  @override
  Stream<List<TranslationEntry>> watchSessionEntries(String sessionId) {
    return _supabase
        .from('translation_entries')
        .stream(primaryKey: ['id'])
        .eq('session_id', sessionId)
        .order('created_at')
        .map((data) => data.map((json) => TranslationEntry.fromJson(json)).toList());
  }
}
