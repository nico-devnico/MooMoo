import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/sign.dart';
import '../../data/repositories/favorite_repository.dart';
import 'auth_provider.dart';

part 'favorite_provider.g.dart';

@riverpod
FavoriteRepository favoriteRepository(Ref ref) {
  return FavoriteRepositoryImpl(ref.watch(supabaseClientProvider));
}

@riverpod
Future<List<Sign>> userFavorites(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Future.value([]);
  
  return ref.watch(favoriteRepositoryProvider).getFavorites(user.id);
}

@riverpod
Future<bool> isSignFavorite(Ref ref, String signId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Future.value(false);
  
  return ref.watch(favoriteRepositoryProvider).isFavorite(user.id, signId);
}
