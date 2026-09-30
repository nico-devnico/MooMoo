import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/local/local_favorites_store.dart';
import '../../data/local/lsfb_dictionary_asset.dart';
import '../../data/models/sign.dart';
import '../../data/repositories/favorite_repository.dart';
import 'auth_provider.dart';

part 'favorite_provider.g.dart';

@riverpod
FavoriteRepository favoriteRepository(Ref ref) {
  return FavoriteRepositoryImpl(ref.watch(supabaseClientProvider));
}

@riverpod
Future<List<Sign>> userFavorites(Ref ref) async {
  final user = ref.watch(currentUserProvider);
  final remote = user == null
      ? <Sign>[]
      : await ref.watch(favoriteRepositoryProvider).getFavorites(user.id);
  final local = await LocalFavoritesStore.loadSigns();
  // Locaux d'abord (récents côté prefs), puis distants sans doublon.
  final seen = <String>{};
  return [
    for (final sign in [...local, ...remote])
      if (seen.add(sign.id)) sign,
  ];
}

@riverpod
Future<bool> isSignFavorite(Ref ref, String signId) async {
  if (LsfbDictionaryAsset.isLocalId(signId)) {
    return LocalFavoritesStore.isFavorite(signId);
  }
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return ref.watch(favoriteRepositoryProvider).isFavorite(user.id, signId);
}
