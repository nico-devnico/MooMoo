import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../services/api_client.dart';

abstract class ProfileRepository {
  Future<UserProfile?> getProfile(String id);
  Future<void> updateProfile(UserProfile profile);
  Stream<UserProfile?> watchProfile(String id);
  Future<UserProfile?> ensureProfileViaApi({
    required String accessToken,
    String? displayName,
    bool? isDeaf,
    String? email,
  });
}

class ProfileRepositoryImpl implements ProfileRepository {
  final SupabaseClient _supabase;
  final ApiClient _api;

  ProfileRepositoryImpl(this._supabase, {ApiClient? api})
      : _api = api ?? ApiClient();

  static const _safeSelect =
      'id,email,display_name,avatar_url,bio,preferred_sign_language,'
      'preferred_output,preferred_view,is_deaf,theme,locale,created_at,updated_at,'
      'three_d_auto_rotate';

  @override
  Future<UserProfile?> getProfile(String id) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select(_safeSelect)
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return UserProfile.fromJson(_normalize(response));
    } catch (_) {
      // Fallback: select * if some columns missing from safe list
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return UserProfile.fromJson(_normalize(response));
    }
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> json) {
    // Live DB may not have is_admin yet — default false
    json.putIfAbsent('is_admin', () => false);
    return json;
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    final json = profile.toJson();
    json.remove('id');
    json.remove('is_admin'); // column may be absent; admin-only via API
    json['updated_at'] = DateTime.now().toIso8601String();

    await _supabase.from('profiles').update(json).eq('id', profile.id);
  }

  @override
  Stream<UserProfile?> watchProfile(String id) {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((data) {
      if (data.isEmpty) return null;
      return UserProfile.fromJson(_normalize(Map<String, dynamic>.from(data.first)));
    });
  }

  @override
  Future<UserProfile?> ensureProfileViaApi({
    required String accessToken,
    String? displayName,
    bool? isDeaf,
    String? email,
  }) async {
    try {
      final res = await _api.postJson(
        '/api/auth/ensure-profile',
        accessToken: accessToken,
        body: {
          'displayName': ?displayName,
          'isDeaf': ?isDeaf,
          'email': ?email,
        },
      );
      final profile = res['profile'];
      if (profile is Map<String, dynamic>) {
        return UserProfile.fromJson(_normalize(profile));
      }
      if (profile is Map) {
        return UserProfile.fromJson(_normalize(Map<String, dynamic>.from(profile)));
      }
    } catch (_) {
      // Fall through to direct upsert
    }

    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    await _supabase.from('profiles').upsert({
      'id': user.id,
      'email': email ?? user.email,
      'display_name': displayName ?? user.userMetadata?['display_name'],
      'is_deaf': ?isDeaf,
      'updated_at': DateTime.now().toIso8601String(),
    });
    return getProfile(user.id);
  }
}
