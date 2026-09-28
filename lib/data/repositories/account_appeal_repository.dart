import 'package:supabase_flutter/supabase_flutter.dart';

/// Message sent by a banned user to the administrators.
class AccountAppeal {
  const AccountAppeal({
    required this.id,
    required this.userId,
    required this.email,
    required this.message,
    this.createdAt,
  });

  factory AccountAppeal.fromJson(Map<String, dynamic> json) => AccountAppeal(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        email: json['email'] as String,
        message: json['message'] as String,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      );

  final String id;
  final String userId;
  final String email;
  final String message;
  final DateTime? createdAt;
}

class AccountAppealRepository {
  AccountAppealRepository(this._supabase);

  final SupabaseClient _supabase;

  /// Works without a session: a banned account has none. The server answers
  /// the same way whether or not the address matches a banned account.
  Future<void> submit({required String email, required String message}) async {
    await _supabase.rpc('submit_account_appeal', params: {
      'p_email': email.trim(),
      'p_message': message.trim(),
    });
  }

  /// Open appeals grouped by user, newest first (administrators only).
  Future<Map<String, List<AccountAppeal>>> openAppealsByUser() async {
    final rows = await _supabase
        .from('account_appeals')
        .select('id, user_id, email, message, created_at')
        .eq('status', 'open')
        .order('created_at', ascending: false);
    final byUser = <String, List<AccountAppeal>>{};
    for (final row in rows) {
      final appeal = AccountAppeal.fromJson(row);
      byUser.putIfAbsent(appeal.userId, () => []).add(appeal);
    }
    return byUser;
  }

  Future<void> resolveForUser(String userId) async {
    await _supabase
        .from('account_appeals')
        .update({
          'status': 'resolved',
          'resolved_at': DateTime.now().toUtc().toIso8601String(),
          'resolved_by': _supabase.auth.currentUser?.id,
        })
        .eq('user_id', userId)
        .eq('status', 'open');
  }
}
