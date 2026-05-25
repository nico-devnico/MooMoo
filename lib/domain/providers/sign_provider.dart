import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/sign.dart';
import '../../data/models/sign_category.dart';
import '../../data/models/sign_language.dart';
import '../../data/repositories/dictionary_repository.dart';
import 'auth_provider.dart';

part 'sign_provider.g.dart';

@riverpod
DictionaryRepository dictionaryRepository(Ref ref) {
  return DictionaryRepositoryImpl(ref.watch(supabaseClientProvider));
}

@riverpod
Future<List<SignLanguage>> signLanguages(Ref ref) {
  return ref.watch(dictionaryRepositoryProvider).getLanguages();
}

@riverpod
Future<List<SignCategory>> signCategories(Ref ref, int languageId) {
  return ref.watch(dictionaryRepositoryProvider).getCategories(languageId);
}

@riverpod
class SignSearch extends _$SignSearch {
  @override
  FutureOr<List<Sign>> build({
    String? query,
    int? languageId,
    int? categoryId,
    int? difficultyLevel,
  }) {
    return ref.watch(dictionaryRepositoryProvider).searchSigns(
      query: query,
      languageId: languageId,
      categoryId: categoryId,
      difficultyLevel: difficultyLevel,
    );
  }
}

@riverpod
Future<Sign?> signDetail(Ref ref, String id) {
  return ref.watch(dictionaryRepositoryProvider).getSignById(id);
}
