import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moomoo/data/models/admin_stats.dart';
import 'package:moomoo/data/models/contribution.dart';
import 'package:moomoo/data/models/sign.dart';
import 'package:moomoo/data/models/user_profile.dart';
import 'package:moomoo/data/repositories/admin_repository.dart';
import 'package:moomoo/domain/providers/auth_provider.dart';
import 'package:moomoo/domain/providers/profile_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepositoryImpl(ref.watch(supabaseClientProvider));
});

/// True if profile.isAdmin or Supabase app/user metadata role == admin.
bool resolveIsAdmin(UserProfile? profile, User? user) {
  if (profile?.isAdmin == true) return true;
  final appRole = user?.appMetadata['role'];
  final userRole = user?.userMetadata?['role'];
  return appRole == 'admin' || userRole == 'admin';
}

final isAdminProvider = Provider<bool>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  final user = ref.watch(currentUserProvider);
  return resolveIsAdmin(profile, user);
});

final adminStatsProvider = FutureProvider.autoDispose<AdminStats>((ref) {
  return ref.watch(adminRepositoryProvider).getStats();
});

final adminUsersProvider =
    FutureProvider.autoDispose.family<List<UserProfile>, String?>((ref, query) {
  return ref.watch(adminRepositoryProvider).getUsers(query: query);
});

final adminContributionsProvider =
    FutureProvider.autoDispose.family<List<Contribution>, String?>((ref, status) {
  return ref.watch(adminRepositoryProvider).getContributions(status: status);
});

class AdminSignsFilter {
  final String? query;
  final bool? isValidated;

  const AdminSignsFilter({this.query, this.isValidated});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminSignsFilter &&
          query == other.query &&
          isValidated == other.isValidated;

  @override
  int get hashCode => Object.hash(query, isValidated);
}

final adminSignsProvider =
    FutureProvider.autoDispose.family<List<Sign>, AdminSignsFilter>((ref, filter) {
  return ref.watch(adminRepositoryProvider).getSigns(
        query: filter.query,
        isValidated: filter.isValidated,
      );
});
