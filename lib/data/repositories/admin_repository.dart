import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/admin_stats.dart';
import '../models/contribution.dart';
import '../models/sign.dart';
import '../models/user_profile.dart';

abstract class AdminRepository {
  Future<AdminStats> getStats();
  Future<List<UserProfile>> getUsers({String? query, int limit = 50});
  Future<void> setUserAdmin(String userId, bool isAdmin);
  Future<List<Contribution>> getContributions({String? status});
  Future<void> reviewContribution({
    required String contributionId,
    required String status,
    required String reviewerId,
    String? note,
    bool createSignOnApprove = true,
  });
  Future<List<Sign>> getSigns({
    String? query,
    bool? isValidated,
    int limit = 50,
  });
  Future<void> setSignValidated(String signId, bool isValidated);
  Future<void> deleteSign(String signId);
  Future<Sign> upsertSign(Sign sign);
}

class AdminRepositoryImpl implements AdminRepository {
  final SupabaseClient _supabase;

  AdminRepositoryImpl(this._supabase);

  @override
  Future<AdminStats> getStats() async {
    final users = await _supabase.from('profiles').select('id');
    final signs = await _supabase.from('signs').select('id, is_validated');
    final contributions = await _supabase.from('contributions').select('id, status');

    final signsList = signs as List;
    final contribList = contributions as List;

    return AdminStats(
      usersCount: (users as List).length,
      signsCount: signsList.length,
      validatedSignsCount: signsList.where((s) => s['is_validated'] == true).length,
      pendingContributionsCount:
          contribList.where((c) => (c['status'] as String?) == 'pending').length,
      approvedContributionsCount:
          contribList.where((c) => (c['status'] as String?) == 'approved').length,
      rejectedContributionsCount:
          contribList.where((c) => (c['status'] as String?) == 'rejected').length,
    );
  }

  @override
  Future<List<UserProfile>> getUsers({String? query, int limit = 50}) async {
    var request = _supabase.from('profiles').select().order('created_at', ascending: false);

    final response = await request.limit(limit);
    var users = (response as List).map((json) => UserProfile.fromJson(json)).toList();

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      users = users.where((u) {
        final name = u.displayName?.toLowerCase() ?? '';
        final email = u.email?.toLowerCase() ?? '';
        return name.contains(q) || email.contains(q);
      }).toList();
    }

    return users;
  }

  @override
  Future<void> setUserAdmin(String userId, bool isAdmin) async {
    await _supabase.from('profiles').update({
      'is_admin': isAdmin,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  @override
  Future<List<Contribution>> getContributions({String? status}) async {
    var request = _supabase.from('contributions').select();

    if (status != null && status.isNotEmpty) {
      request = request.eq('status', status);
    }

    final response = await request.order('submitted_at', ascending: false);
    return (response as List).map((json) => Contribution.fromJson(json)).toList();
  }

  @override
  Future<void> reviewContribution({
    required String contributionId,
    required String status,
    required String reviewerId,
    String? note,
    bool createSignOnApprove = true,
  }) async {
    final now = DateTime.now().toIso8601String();

    await _supabase.from('contributions').update({
      'status': status,
      'reviewer_id': reviewerId,
      'reviewer_note': note,
      'reviewed_at': now,
    }).eq('id', contributionId);

    if (status == 'approved' && createSignOnApprove) {
      final row = await _supabase
          .from('contributions')
          .select()
          .eq('id', contributionId)
          .single();

      final contribution = Contribution.fromJson(row);
      final sign = Sign(
        id: const Uuid().v4(),
        signLanguageId: contribution.signLanguageId,
        word: contribution.word,
        description: contribution.description,
        videoUrl: contribution.videoUrl,
        thumbnailUrl: contribution.thumbnailUrl,
        landmarkData: contribution.landmarkData,
        isValidated: true,
        contributorId: contribution.contributorId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _supabase.from('signs').insert(sign.toJson());
    }
  }

  @override
  Future<List<Sign>> getSigns({
    String? query,
    bool? isValidated,
    int limit = 50,
  }) async {
    var request = _supabase.from('signs').select();

    if (isValidated != null) {
      request = request.eq('is_validated', isValidated);
    }
    if (query != null && query.isNotEmpty) {
      request = request.ilike('word', '%$query%');
    }

    final response = await request.order('created_at', ascending: false).limit(limit);
    return (response as List).map((json) => Sign.fromJson(json)).toList();
  }

  @override
  Future<void> setSignValidated(String signId, bool isValidated) async {
    await _supabase.from('signs').update({
      'is_validated': isValidated,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', signId);
  }

  @override
  Future<void> deleteSign(String signId) async {
    await _supabase.from('signs').delete().eq('id', signId);
  }

  @override
  Future<Sign> upsertSign(Sign sign) async {
    final json = sign.toJson();
    json['updated_at'] = DateTime.now().toIso8601String();
    final response = await _supabase.from('signs').upsert(json).select().single();
    return Sign.fromJson(response);
  }
}
