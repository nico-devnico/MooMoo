import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/translation_entry.dart';
import '../../data/repositories/session_repository.dart';
import 'auth_provider.dart';

part 'session_provider.g.dart';

@riverpod
SessionRepository sessionRepository(Ref ref) {
  return SessionRepositoryImpl(ref.watch(supabaseClientProvider));
}

@riverpod
Stream<List<TranslationEntry>> sessionEntries(Ref ref, String sessionId) {
  return ref.watch(sessionRepositoryProvider).watchSessionEntries(sessionId);
}

@riverpod
Future<List<Map<String, dynamic>>> userHistory(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Future.value([]);
  return ref.watch(sessionRepositoryProvider).getUserHistory(user.id);
}
