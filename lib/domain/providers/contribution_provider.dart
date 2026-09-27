import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moomoo/data/models/contribution.dart';
import 'package:moomoo/data/repositories/contribution_repository.dart';
import 'package:moomoo/domain/providers/auth_provider.dart';

final contributionRepositoryProvider = Provider<ContributionRepository>((ref) {
  return ContributionRepositoryImpl(ref.watch(supabaseClientProvider));
});

final myContributionsProvider =
    FutureProvider.autoDispose<List<Contribution>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Future.value(const []);
  return ref.watch(contributionRepositoryProvider).getMyContributions(user.id);
});
