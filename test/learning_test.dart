import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:moomoo/data/models/learning.dart';
import 'package:moomoo/data/models/ml_model.dart';
import 'package:moomoo/data/models/sign.dart';
import 'package:moomoo/domain/learning/lesson_builder.dart';
import 'package:moomoo/domain/learning/mastery.dart';
import 'package:moomoo/domain/learning/practice.dart';
import 'package:moomoo/domain/providers/learning_provider.dart';

Sign _sign(String id, String word, {bool visual = true}) => Sign(
      id: id,
      word: word,
      thumbnailUrl: visual ? 'https://example.com/$id.png' : null,
    );

LessonContent _content(List<Sign> signs, {List<Sign> distractors = const []}) =>
    LessonContent(
      id: 'lesson',
      title: 'Test',
      xpReward: 10,
      signLanguageId: 1,
      signs: signs,
      distractors: distractors,
    );

void main() {
  group('buildLessonSteps', () {
    test('introduces, recognises then finds every sign', () {
      final signs = [_sign('a', 'bonjour'), _sign('b', 'merci'), _sign('c', 'oui')];
      final steps = buildLessonSteps(_content(signs), random: Random(1));

      expect(steps.whereType<IntroStep>().length, 3);
      expect(steps.whereType<RecognizeStep>().length, 3);
      expect(steps.whereType<FindStep>().length, 3);
      expect(steps.first, isA<IntroStep>());
      expect(steps[1], isA<RecognizeStep>());
      expect(steps[1].sign.id, steps.first.sign.id);
    });

    test('ends with a practice session before the next lesson', () {
      final signs = [
        for (var i = 0; i < 5; i++) _sign('$i', 'mot$i'),
      ];
      final steps = buildLessonSteps(_content(signs), random: Random(5));
      final practice = steps.whereType<PracticeStep>().toList();

      expect(practice.length, maxPracticeSigns);
      expect(steps.skip(steps.length - practice.length), everyElement(isA<PracticeStep>()));
      expect(practice.map((p) => p.number), [1, 2, 3]);
      expect(practice.every((p) => p.total == maxPracticeSigns), isTrue);
      expect(practice.first.isQuestion, isTrue);
    });

    test('options contain the answer once, distinct words, at most four', () {
      final signs = [_sign('a', 'bonjour'), _sign('b', 'merci')];
      final distractors = [
        _sign('c', 'oui'),
        _sign('d', 'non'),
        _sign('e', 'Merci'),
        _sign('f', 'salut'),
      ];
      final steps = buildLessonSteps(
        _content(signs, distractors: distractors),
        random: Random(2),
      );

      for (final step in steps.whereType<RecognizeStep>()) {
        final words = step.options.map((s) => s.word.toLowerCase()).toList();
        expect(step.options.length, lessThanOrEqualTo(maxOptions));
        expect(step.options.where((s) => s.id == step.sign.id).length, 1);
        expect(words.toSet().length, words.length);
      }
    });

    test('falls back to introductions when there is nothing to choose from', () {
      final steps = buildLessonSteps(_content([_sign('a', 'bonjour')]), random: Random(3));
      expect(steps.whereType<IntroStep>().length, 1);
      expect(steps.whereType<RecognizeStep>(), isEmpty);
      expect(steps.whereType<FindStep>(), isEmpty);
      expect(steps.last, isA<PracticeStep>());
    });

    test('signs without any visual are introduced but never asked', () {
      final signs = [_sign('a', 'bonjour', visual: false), _sign('b', 'merci')];
      final steps = buildLessonSteps(_content(signs), random: Random(4));

      expect(steps.where((s) => s.isQuestion && s.sign.id == 'a'), isEmpty);
      expect(steps.whereType<IntroStep>().length, 2);
    });

    test('a retry keeps the question but does not count', () {
      final step = RecognizeStep(_sign('a', 'bonjour'), options: const []);
      final retry = step.asRetry();
      expect(retry, isA<RecognizeStep>());
      expect(retry.isRetry, isTrue);
      expect(retry.sign.id, 'a');
    });
  });

  group('resolveLessonStates', () {
    LearningLesson lesson(String id, {int signs = 3}) =>
        LearningLesson(id: id, unitId: 'u', title: id, signCount: signs);

    LessonProgress done(String id) =>
        LessonProgress(lessonId: id, bestCorrect: 4, questionCount: 4, completions: 1);

    test('first unfinished lesson is current, the rest locked', () {
      final units = [
        LearningUnit(
          id: 'u',
          signLanguageId: 1,
          title: 'U',
          lessons: [lesson('l1'), lesson('l2'), lesson('l3')],
        ),
      ];
      final states = resolveLessonStates(units, {'l1': done('l1')});

      expect(states['l1'], LessonState.completed);
      expect(states['l2'], LessonState.current);
      expect(states['l3'], LessonState.locked);
    });

    test('lessons without signs never block the path', () {
      final units = [
        LearningUnit(
          id: 'u',
          signLanguageId: 1,
          title: 'U',
          lessons: [lesson('l1', signs: 0), lesson('l2')],
        ),
      ];
      final states = resolveLessonStates(units, const {});

      expect(states['l1'], LessonState.empty);
      expect(states['l2'], LessonState.current);
    });

    test('current continues into the next unit', () {
      final units = [
        LearningUnit(id: 'u1', signLanguageId: 1, title: 'U1', lessons: [lesson('l1')]),
        LearningUnit(id: 'u2', signLanguageId: 1, title: 'U2', lessons: [lesson('l2')]),
      ];
      final states = resolveLessonStates(units, {'l1': done('l1')});

      expect(states['l2'], LessonState.current);
    });
  });

  group('mastery', () {
    LessonProgress p(int correct, int total) =>
        LessonProgress(lessonId: 'l', bestCorrect: correct, questionCount: total, completions: 1);

    test('levels follow the best score', () {
      expect(masteryLevelOf(null), MasteryLevel.none);
      expect(masteryLevelOf(p(1, 4)), MasteryLevel.fragile);
      expect(masteryLevelOf(p(2, 4)), MasteryLevel.learning);
      expect(masteryLevelOf(p(4, 5)), MasteryLevel.acquired);
      expect(masteryLevelOf(p(5, 5)), MasteryLevel.mastered);
      expect(masteryRatio(p(3, 4)), 0.75);
    });

    test('stars reward accuracy', () {
      expect(starsFor(10, 10), 3);
      expect(starsFor(9, 10), 3);
      expect(starsFor(6, 10), 2);
      expect(starsFor(2, 10), 1);
    });
  });

  group('practice', () {
    test('accepts the expected word among the best guesses', () {
      const result = InferenceResult(
        ok: true,
        label: 'merci',
        topLabels: ['merci', 'Ça va', 'bonjour'],
      );
      expect(practiceMatches('merci', result), isTrue);
      expect(practiceMatches('ça va', result), isTrue);
      expect(practiceMatches('Bonjour !', result), isTrue);
      expect(practiceMatches('au revoir', result), isFalse);
    });

    test('never passes when recognition failed', () {
      expect(practiceMatches('merci', InferenceResult.unavailable('down')), isFalse);
    });

    test('normalises accents, case and punctuation', () {
      expect(normalizeSignWord('  Ça va ? '), 'cava');
      expect(normalizeSignWord('Été'), 'ete');
      expect(normalizeSignWord('cœur'), 'coeur');
    });
  });

  group('JSON parsing', () {
    test('lesson reads the PostgREST count aggregate', () {
      final lesson = LearningLesson.fromJson({
        'id': 'l',
        'unit_id': 'u',
        'title': 'T',
        'order_index': 0,
        'xp_reward': 15,
        'lesson_signs': [
          {'count': 4},
        ],
      });
      expect(lesson.signCount, 4);
      expect(lesson.xpReward, 15);
    });

    test('unit sorts its lessons by order_index', () {
      final unit = LearningUnit.fromJson({
        'id': 'u',
        'sign_language_id': 1,
        'title': 'U',
        'learning_lessons': [
          {'id': 'b', 'unit_id': 'u', 'title': 'B', 'order_index': 1},
          {'id': 'a', 'unit_id': 'u', 'title': 'A', 'order_index': 0},
        ],
      });
      expect(unit.lessons.map((l) => l.id), ['a', 'b']);
    });

    test('summary computes the daily goal ratio', () {
      final summary = LearnerSummary.fromJson({'today_xp': 30, 'daily_goal_xp': 20});
      expect(summary.dailyGoalProgress, 1.0);
      expect(summary.dailyGoalReached, isTrue);
    });
  });
}
