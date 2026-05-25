import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sign.dart';
import '../models/sign_category.dart';
import '../models/sign_language.dart';

abstract class DictionaryRepository {
  Future<List<SignLanguage>> getLanguages();
  Future<List<SignCategory>> getCategories(int languageId);
  Future<List<Sign>> searchSigns({
    String? query,
    int? languageId,
    int? categoryId,
    int? difficultyLevel,
    int limit = 20,
    int offset = 0,
  });
  Future<Sign?> getSignById(String id);
  Future<void> incrementViewCount(String id);
}

class DictionaryRepositoryImpl implements DictionaryRepository {
  final SupabaseClient _supabase;

  DictionaryRepositoryImpl(this._supabase);

  @override
  Future<List<SignLanguage>> getLanguages() async {
    final response = await _supabase
        .from('sign_languages')
        .select()
        .eq('is_active', true)
        .order('name');
    
    return (response as List).map((json) => SignLanguage.fromJson(json)).toList();
  }

  @override
  Future<List<SignCategory>> getCategories(int languageId) async {
    final response = await _supabase
        .from('sign_categories')
        .select()
        .eq('sign_language_id', languageId)
        .order('order_index');
    
    return (response as List).map((json) => SignCategory.fromJson(json)).toList();
  }

  @override
  Future<List<Sign>> searchSigns({
    String? query,
    int? languageId,
    int? categoryId,
    int? difficultyLevel,
    int limit = 20,
    int offset = 0,
  }) async {
    var request = _supabase.from('signs').select().eq('is_validated', true);

    if (query != null && query.isNotEmpty) {
      request = request.ilike('word', '%$query%');
    }
    if (languageId != null) {
      request = request.eq('sign_language_id', languageId);
    }
    if (categoryId != null) {
      request = request.eq('category_id', categoryId);
    }
    if (difficultyLevel != null) {
      request = request.eq('difficulty_level', difficultyLevel);
    }

    final response = await request
        .order('word')
        .range(offset, offset + limit - 1);

    return (response as List).map((json) => Sign.fromJson(json)).toList();
  }

  @override
  Future<Sign?> getSignById(String id) async {
    final response = await _supabase
        .from('signs')
        .select()
        .eq('id', id)
        .single();
    
    return Sign.fromJson(response);
  }

  @override
  Future<void> incrementViewCount(String id) async {
    // Supabase RPC or direct update
    await _supabase.rpc('increment_sign_view_count', params: {'sign_id': id});
  }
}
