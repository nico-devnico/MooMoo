import 'dart:math';

import '../../data/models/learning.dart';
import '../../data/models/sign.dart';

/// One screen of a lesson.
sealed class LessonStep {
  const LessonStep(this.sign, {this.isRetry = false});

  /// The sign being taught or asked about.
  final Sign sign;

  /// A question asked again after a mistake. It must be answered to finish
  /// the lesson but does not count towards the score.
  final bool isRetry;

  bool get isQuestion => this is! IntroStep;

  LessonStep asRetry();
}

/// Shows a new sign with its meaning. Nothing to answer.
class IntroStep extends LessonStep {
  const IntroStep(super.sign);

  @override
  LessonStep asRetry() => this;
}

/// Shows a sign; the learner picks the matching word.
class RecognizeStep extends LessonStep {
  const RecognizeStep(super.sign, {required this.options, super.isRetry});

  final List<Sign> options;

  @override
  LessonStep asRetry() => RecognizeStep(sign, options: options, isRetry: true);
}

/// Shows a word; the learner picks the matching sign.
class FindStep extends LessonStep {
  const FindStep(super.sign, {required this.options, super.isRetry});

  final List<Sign> options;

  @override
  LessonStep asRetry() => FindStep(sign, options: options, isRetry: true);
}

const int maxOptions = 4;

bool signHasVisual(Sign sign) {
  if (sign.videoUrl != null || sign.thumbnailUrl != null) return true;
  final points = sign.landmarkData?['points'];
  return points is List && points.isNotEmpty;
}

/// Builds the lesson: each sign is introduced then recognised right away,
/// and a final round asks to find each sign from its word, in shuffled order.
///
/// Questions need at least two distinct words to choose from; with fewer, the
/// lesson falls back to introductions only rather than asking a question with
/// a single possible answer.
List<LessonStep> buildLessonSteps(LessonContent content, {Random? random}) {
  final rng = random ?? Random();
  final pool = _uniqueByWord([...content.signs, ...content.distractors]);
  final visualPool = pool.where(signHasVisual).toList(growable: false);

  final steps = <LessonStep>[];
  for (final sign in content.signs) {
    steps.add(IntroStep(sign));
    if (signHasVisual(sign) && pool.length >= 2) {
      steps.add(RecognizeStep(sign, options: _pickOptions(sign, pool, rng)));
    }
  }

  final finalRound = [...content.signs]..shuffle(rng);
  for (final sign in finalRound) {
    if (signHasVisual(sign) && visualPool.length >= 2) {
      steps.add(FindStep(sign, options: _pickOptions(sign, visualPool, rng)));
    }
  }
  return steps;
}

List<Sign> _pickOptions(Sign answer, List<Sign> pool, Random rng) {
  final key = _wordKey(answer.word);
  final others = pool.where((s) => _wordKey(s.word) != key).toList()..shuffle(rng);
  return [answer, ...others.take(maxOptions - 1)]..shuffle(rng);
}

List<Sign> _uniqueByWord(List<Sign> signs) {
  final seen = <String>{};
  return [
    for (final sign in signs)
      if (seen.add(_wordKey(sign.word))) sign,
  ];
}

String _wordKey(String word) => word.trim().toLowerCase();
