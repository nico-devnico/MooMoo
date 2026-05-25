import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:moomoo/data/models/user_profile.dart';
import 'package:moomoo/data/repositories/profile_repository.dart';
import 'package:moomoo/domain/providers/auth_provider.dart';

part 'profile_provider.g.dart';

@riverpod
ProfileRepository profileRepository(Ref ref) {
  return ProfileRepositoryImpl(ref.watch(supabaseClientProvider));
}

@riverpod
Stream<UserProfile?> userProfile(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  
  return ref.watch(profileRepositoryProvider).watchProfile(user.id);
}
