import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/translator/phrase_glosser.dart';
import '../local/lsfb_dictionary_asset.dart';
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

  Future<List<SignLanguage>> _fetchRemoteLanguages() async {
    try {
      final response = await _supabase
          .from('sign_languages')
          .select(signLanguageColumns)
          .eq('is_active', true)
          .order('name')
          .limit(100);

      return (response as List)
          .map((json) => SignLanguage.fromJson(json as Map<String, dynamic>))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<SignLanguage?> _remoteLsfb() async {
    final languages = await _fetchRemoteLanguages();
    for (final l in languages) {
      if (l.code.toUpperCase() == LsfbDictionaryAsset.languageCode) return l;
    }
    return null;
  }

  @override
  Future<List<SignLanguage>> getLanguages() async {
    final remote = await _fetchRemoteLanguages();
    final hasLsfb = remote.any(
      (l) => l.code.toUpperCase() == LsfbDictionaryAsset.languageCode,
    );
    if (hasLsfb) return remote;
    return [...remote, LsfbDictionaryAsset.fallbackLanguage];
  }

  @override
  Future<List<SignCategory>> getCategories(int languageId) async {
    try {
      final response = await _supabase
          .from('sign_categories')
          .select(signCategoryColumns)
          .eq('sign_language_id', languageId)
          .order('order_index')
          .limit(200);

      return (response as List)
          .map((json) => SignCategory.fromJson(json as Map<String, dynamic>))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<bool> _isLsfbLanguage(int? languageId) async {
    if (languageId == null) return false;
    if (languageId == LsfbDictionaryAsset.lsfbLanguageId) return true;
    final languages = await getLanguages();
    for (final l in languages) {
      if (l.id == languageId) {
        return l.code.toUpperCase() == LsfbDictionaryAsset.languageCode;
      }
    }
    return false;
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
    final lsfbLang = await _isLsfbLanguage(languageId);

    // Catalogue embarqué LSFB (GIFs corpus) : source principale pour LSFB.
    if (lsfbLang && categoryId == null && difficultyLevel == null) {
      final lsfb = await _remoteLsfb();
      return LsfbDictionaryAsset.search(
        query: query,
        languageId: lsfb?.id ?? LsfbDictionaryAsset.lsfbLanguageId,
        limit: limit,
        offset: offset,
      );
    }

    try {
      var request = _supabase
          .from('signs')
          .select(signListColumns)
          .eq('is_validated', true);

      final trimmed = query?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        // Exact (case-insensitive) or prefix — never `%q%` mid-word contains.
        if (trimmed.length < 3) {
          request = request.ilike('word', trimmed);
        } else {
          request = request.or(
            'word.ilike.${_orValue(trimmed)},word.ilike.${_orValue('$trimmed%')}',
          );
        }
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

      // Over-fetch then rank client-side (exact before prefix).
      final fetchLimit = (offset + limit).clamp(1, 100);
      final response =
          await request.order('word').limit(fetchLimit);

      final ranked = filterDictionaryMatches(
        (response as List)
            .map((json) => Sign.fromJson(json as Map<String, dynamic>))
            .toList(growable: false),
        trimmed ?? '',
        limit: offset + limit,
      );
      return ranked.skip(offset).take(limit).toList(growable: false);
    } catch (_) {
      // Repli : catalogue local si la base ne répond pas.
      if (languageId == null || await _isLsfbLanguage(languageId)) {
        final lsfb = await _remoteLsfb();
        return LsfbDictionaryAsset.search(
          query: query,
          languageId: lsfb?.id ?? LsfbDictionaryAsset.lsfbLanguageId,
          limit: limit,
          offset: offset,
        );
      }
      return const [];
    }
  }

  /// Quotes a PostgREST `or` filter value safely.
  static String _orValue(String value) {
    final escaped = value.replaceAll('"', r'\"');
    return '"$escaped"';
  }

  @override
  Future<Sign?> getSignById(String id) async {
    if (LsfbDictionaryAsset.isLocalId(id)) {
      final lsfb = await _remoteLsfb();
      return LsfbDictionaryAsset.byId(
        id,
        languageId: lsfb?.id ?? LsfbDictionaryAsset.lsfbLanguageId,
      );
    }
    try {
      final response = await _supabase
          .from('signs')
          .select(signDetailColumns)
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return Sign.fromJson(response);
    } catch (_) {
      return LsfbDictionaryAsset.byId(id);
    }
  }

  @override
  Future<void> incrementViewCount(String id) async {
    if (LsfbDictionaryAsset.isLocalId(id)) return;
    await _supabase.rpc('record_sign_view', params: {'p_sign_id': id});
  }
}
