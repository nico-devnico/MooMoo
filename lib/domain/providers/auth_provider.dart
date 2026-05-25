import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/auth_repository.dart';

part 'auth_provider.g.dart';

@riverpod
SupabaseClient supabaseClient(Ref ref) => Supabase.instance.client;

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl(ref.watch(supabaseClientProvider));
}

@riverpod
Stream<AuthState> authStateChanges(Ref ref) {
  return ref.watch(authRepositoryProvider).watchAuthState();
}

@riverpod
User? currentUser(Ref ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.value?.session?.user ?? ref.watch(authRepositoryProvider).currentUser;
}

@riverpod
Session? currentSession(Ref ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.value?.session ?? ref.watch(authRepositoryProvider).currentSession;
}
