import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile?> getProfile(String id);
  Future<void> updateProfile(UserProfile profile);
  Stream<UserProfile?> watchProfile(String id);
}

class ProfileRepositoryImpl implements ProfileRepository {
  final SupabaseClient _supabase;

  ProfileRepositoryImpl(this._supabase);

  @override
  Future<UserProfile?> getProfile(String id) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', id)
        .maybeSingle();
    
    if (response == null) return null;
    return UserProfile.fromJson(response);
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    final json = profile.toJson();
    // Remove ID from update payload as it's the primary key used in .eq()
    json.remove('id');
    // Ensure updated_at is set to current time
    json['updated_at'] = DateTime.now().toIso8601String();

    await _supabase
        .from('profiles')
        .update(json)
        .eq('id', profile.id);
  }

  @override
  Stream<UserProfile?> watchProfile(String id) {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((data) => data.isEmpty ? null : UserProfile.fromJson(data.first));
  }
}
