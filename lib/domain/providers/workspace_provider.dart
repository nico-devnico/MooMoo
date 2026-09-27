import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/sign_category.dart';
import '../../data/models/workspace_overview.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/repositories/workspace_repository.dart';
import 'admin_provider.dart';
import 'auth_provider.dart';

final workspaceRepositoryProvider = Provider<WorkspaceRepository>((ref) {
  return WorkspaceRepository(ref.watch(supabaseClientProvider));
});

/// Roles of the signed-in user (public.user_roles), reloaded on account change.
final currentUserRolesProvider = FutureProvider<List<String>>((ref) async {
  final userId = ref.watch(currentUserProvider.select((u) => u?.id));
  if (userId == null) return const [];
  return ref.watch(workspaceRepositoryProvider).currentRoles();
});

/// Admins can open every space; the database applies the same rule.
final isTeacherProvider = Provider<bool>((ref) {
  final roles = ref.watch(currentUserRolesProvider).value ?? const [];
  return roles.contains(AppRole.teacher) || ref.watch(isAdminProvider);
});

final isSignExpertProvider = Provider<bool>((ref) {
  final roles = ref.watch(currentUserRolesProvider).value ?? const [];
  return roles.contains(AppRole.signExpert) || ref.watch(isAdminProvider);
});

final teacherOverviewProvider = FutureProvider.autoDispose<TeacherOverview>((ref) {
  return ref.watch(workspaceRepositoryProvider).teacherOverview();
});

final expertOverviewProvider = FutureProvider.autoDispose<ExpertOverview>((ref) {
  return ref.watch(workspaceRepositoryProvider).expertOverview();
});

final manageableCategoriesProvider =
    FutureProvider.autoDispose.family<List<SignCategory>, int>((ref, languageId) {
  return ref.watch(workspaceRepositoryProvider).categories(languageId);
});
