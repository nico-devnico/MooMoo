import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sign.dart';
import 'dictionary_repository.dart';

abstract class FavoriteRepository {
  Future<List<Sign>> getFavorites(
    String userId, {
    int limit = 100,
    int offset = 0,
  });
  Future<void> addFavorite(String userId, String signId, {String? note});
  Future<void> removeFavorite(String userId, String signId);
  Future<bool> isFavorite(String userId, String signId);
}

class FavoriteRepositoryImpl implements FavoriteRepository {
  final SupabaseClient _supabase;

  FavoriteRepositoryImpl(this._supabase);

  /// Jointure PostgREST en une requête, limitée aux colonnes de liste du signe
  /// (plus de `favorites.*` ni de `signs.*`, donc plus de `landmark_data`).
  @override
  Future<List<Sign>> getFavorites(
    String userId, {
    int limit = 100,
    int offset = 0,
  }) async {
    final response = await _supabase
        .from('favorites')
        .select('signs!inner($signListColumns)')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((row) => (row as Map<String, dynamic>)['signs'])
        .whereType<Map<String, dynamic>>()
        .map(Sign.fromJson)
        .toList(growable: false);
  }

  @override
  Future<void> addFavorite(String userId, String signId, {String? note}) async {
    await _supabase.from('favorites').insert({
      'user_id': userId,
      'sign_id': signId,
      'note': note,
    });
  }

  @override
  Future<void> removeFavorite(String userId, String signId) async {
    await _supabase.from('favorites').delete().match({
      'user_id': userId,
      'sign_id': signId,
    });
  }

  /// `count` en HEAD : aucune ligne transférée pour un simple booléen.
  @override
  Future<bool> isFavorite(String userId, String signId) async {
    final count = await _supabase
        .from('favorites')
        .count(CountOption.exact)
        .eq('user_id', userId)
        .eq('sign_id', signId);
    return count > 0;
  }
}
