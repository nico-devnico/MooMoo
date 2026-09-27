import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/sign.dart';
import '../../data/models/sign_category.dart';
import '../../data/models/sign_language.dart';
import '../../data/repositories/dictionary_repository.dart';
import 'auth_provider.dart';
import 'provider_debounce.dart';

part 'sign_provider.g.dart';

@Riverpod(keepAlive: true)
DictionaryRepository dictionaryRepository(Ref ref) {
  return DictionaryRepositoryImpl(ref.watch(supabaseClientProvider));
}

/// Table de référence quasi immuable : gardée pour toute la session au lieu
/// d'être rechargée à chaque navigation vers l'accueil ou le dictionnaire.
@Riverpod(keepAlive: true)
Future<List<SignLanguage>> signLanguages(Ref ref) {
  return ref.watch(dictionaryRepositoryProvider).getLanguages();
}

/// Idem pour les catégories, mises en cache par langue.
@Riverpod(keepAlive: true)
Future<List<SignCategory>> signCategories(Ref ref, int languageId) {
  return ref.watch(dictionaryRepositoryProvider).getCategories(languageId);
}

@riverpod
class SignSearch extends _$SignSearch {
  static const pageSize = 20;

  bool _hasMore = true;

  /// `false` quand la dernière page reçue était incomplète.
  bool get hasMore => _hasMore;

  @override
  Future<List<Sign>> build({
    String? query,
    int? languageId,
    int? categoryId,
    int? difficultyLevel,
  }) async {
    final repository = ref.watch(dictionaryRepositoryProvider);

    if ((query ?? '').trim().isNotEmpty) {
      await debounce(ref);
      if (!ref.mounted) return const [];
    }

    final page = await _fetch(repository, 0);
    _hasMore = page.length == pageSize;
    return page;
  }

  /// Page suivante ajoutée à la liste courante (le dictionnaire ne charge
  /// jamais la table entière).
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !_hasMore) return;

    final next = await _fetch(ref.read(dictionaryRepositoryProvider), current.length);
    _hasMore = next.length == pageSize;
    state = AsyncData([...current, ...next]);
  }

  Future<List<Sign>> _fetch(DictionaryRepository repository, int offset) {
    return repository.searchSigns(
      query: query,
      languageId: languageId,
      categoryId: categoryId,
      difficultyLevel: difficultyLevel,
      limit: pageSize,
      offset: offset,
    );
  }
}

@riverpod
Future<Sign?> signDetail(Ref ref, String id) {
  return ref.watch(dictionaryRepositoryProvider).getSignById(id);
}
