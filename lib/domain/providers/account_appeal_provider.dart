import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moomoo/data/repositories/account_appeal_repository.dart';
import 'package:moomoo/domain/providers/auth_provider.dart';

final accountAppealRepositoryProvider = Provider<AccountAppealRepository>((ref) {
  return AccountAppealRepository(ref.watch(supabaseClientProvider));
});

final openAppealsProvider =
    FutureProvider.autoDispose<Map<String, List<AccountAppeal>>>((ref) {
  return ref.watch(accountAppealRepositoryProvider).openAppealsByUser();
});
