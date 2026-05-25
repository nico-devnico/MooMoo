import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/favorite.dart';
import '../models/sign.dart';

abstract class FavoriteRepository {
  Future<List<Sign>> getFavorites(String userId);
  Future<void> addFavorite(String userId, String signId, {String? note});
  Future<void> removeFavorite(String userId, String signId);
  Future<bool> isFavorite(String userId, String signId);
}

class FavoriteRepositoryImpl implements FavoriteRepository {
  final SupabaseClient _supabase;

  FavoriteRepositoryImpl(this._supabase);

  @override
  Future<List<Sign>> getFavorites(String userId) async {
    final response = await _supabase
        .from('favorites')
        .select('*, signs(*)')
        .eq('user_id', userId);
    
    return (response as List).map((json) => Sign.fromJson(json['signs'])).toList();
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

  @override
  Future<bool> isFavorite(String userId, String signId) async {
    final response = await _supabase
        .from('favorites')
        .select()
        .match({
          'user_id': userId,
          'sign_id': signId,
        })
        .maybeSingle();
    return response != null;
  }
}
