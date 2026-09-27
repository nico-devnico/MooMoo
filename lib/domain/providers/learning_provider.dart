import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/learning.dart';
import '../../data/models/sign.dart';
import '../../data/models/sign_language.dart';
import '../../data/repositories/learning_repository.dart';
import 'auth_provider.dart';
import 'profile_provider.dart';
import 'sign_provider.dart';

final learningRepositoryProvider = Provider<LearningRepository>((ref) {
  return LearningRepository(ref.watch(supabaseClientProvider));
});

/// The course being followed: the profile's preferred sign language, or the
/// first active one when the preference matches nothing.
final learningLanguageProvider = FutureProvider<SignLanguage?>((ref) async {
  final languages = await ref.watch(signLanguagesProvider.future);
  if (languages.isEmpty) return null;
  final code = ref.watch(
    userProfileProvider.select((p) => p.value?.preferredSignLanguage),
  );
  return languages.firstWhere(
    (l) => l.code == code,
    orElse: () => languages.first,
  );
});

final learningPathProvider =
    FutureProvider.autoDispose.family<List<LearningUnit>, int>((ref, languageId) {
  return ref.watch(learningRepositoryProvider).getPath(languageId);
});

final learningProgressProvider =
    FutureProvider.autoDispose<Map<String, LessonProgress>>((ref) {
  ref.watch(currentUserProvider.select((u) => u?.id));
  return ref.watch(learningRepositoryProvider).getProgress();
});

final learnerSummaryProvider = FutureProvider.autoDispose<LearnerSummary>((ref) {
  ref.watch(currentUserProvider.select((u) => u?.id));
  return ref.watch(learningRepositoryProvider).getSummary();
});

final lessonContentProvider =
    FutureProvider.autoDispose.family<LessonContent, String>((ref, lessonId) {
  return ref.watch(learningRepositoryProvider).getLessonContent(lessonId);
});

final canEditLearningProvider = FutureProvider<bool>((ref) async {
  final userId = ref.watch(currentUserProvider.select((u) => u?.id));
  if (userId == null) return false;
  return ref.watch(learningRepositoryProvider).canEdit();
});

/// Editor view of a course: drafts included.
final learningEditorPathProvider =
    FutureProvider.autoDispose.family<List<LearningUnit>, int>((ref, languageId) {
  return ref
      .watch(learningRepositoryProvider)
      .getPath(languageId, includeDrafts: true);
});

final lessonSignsProvider =
    FutureProvider.autoDispose.family<List<Sign>, String>((ref, lessonId) {
  return ref.watch(learningRepositoryProvider).getLessonSigns(lessonId);
});

enum LessonState {
  /// Finished at least once; can be replayed.
  completed,

  /// The next lesson to take.
  current,

  /// Comes after the current lesson.
  locked,

  /// Has no sign yet, so there is nothing to practise.
  empty,
}

/// Walks the path in order and gives each lesson its state. Lessons without
/// signs are skipped when looking for the current one, so an unfinished draft
/// lesson never blocks the rest of the course.
Map<String, LessonState> resolveLessonStates(
  List<LearningUnit> units,
  Map<String, LessonProgress> progress,
) {
  final states = <String, LessonState>{};
  var currentAssigned = false;

  for (final unit in units) {
    for (final lesson in unit.lessons) {
      if (lesson.signCount == 0) {
        states[lesson.id] = LessonState.empty;
      } else if (progress.containsKey(lesson.id)) {
        states[lesson.id] = LessonState.completed;
      } else if (!currentAssigned) {
        states[lesson.id] = LessonState.current;
        currentAssigned = true;
      } else {
        states[lesson.id] = LessonState.locked;
      }
    }
  }
  return states;
}
