import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sign.dart';
import '../models/sign_category.dart';
import '../models/sign_language.dart';

/// Colonnes réellement lues par les listes (SignCard, grilles, favoris).
/// `landmark_data` est un jsonb volumineux : il n'est chargé que sur le détail.
const signListColumns =
    'id,sign_language_id,category_id,word,description,difficulty_level,'
    'video_url,thumbnail_url,is_validated,view_count';

/// Colonnes de l'écran de détail (landmarks 3D, tags, phrase d'exemple).
const signDetailColumns =
    '$signListColumns,model_3d_url,landmark_data,tags,example_sentence,'
    'contributor_id,created_at,updated_at';

const signLanguageColumns = 'id,code,name,country,flag_emoji,is_active';

const signCategoryColumns =
    'id,name,slug,icon_name,color_hex,order_index,sign_language_id';

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
        .select(signLanguageColumns)
        .eq('is_active', true)
        .order('name')
        .limit(100);

    return (response as List)
        .map((json) => SignLanguage.fromJson(json as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<List<SignCategory>> getCategories(int languageId) async {
    final response = await _supabase
        .from('sign_categories')
        .select(signCategoryColumns)
        .eq('sign_language_id', languageId)
        .order('order_index')
        .limit(200);

    return (response as List)
        .map((json) => SignCategory.fromJson(json as Map<String, dynamic>))
        .toList(growable: false);
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
    var request =
        _supabase.from('signs').select(signListColumns).eq('is_validated', true);

    final trimmed = query?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      request = request.ilike('word', '%$trimmed%');
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

    final response =
        await request.order('word').range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => Sign.fromJson(json as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<Sign?> getSignById(String id) async {
    final response = await _supabase
        .from('signs')
        .select(signDetailColumns)
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Sign.fromJson(response);
  }

  @override
  Future<void> incrementViewCount(String id) async {
    // Supabase RPC or direct update
    await _supabase.rpc('increment_sign_view_count', params: {'sign_id': id});
  }
}
