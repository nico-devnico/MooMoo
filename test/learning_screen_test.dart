import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moomoo/data/models/learning.dart';
import 'package:moomoo/data/models/sign_language.dart';
import 'package:moomoo/domain/providers/learning_provider.dart';
import 'package:moomoo/domain/providers/profile_provider.dart';
import 'package:moomoo/domain/providers/sign_provider.dart';
import 'package:moomoo/l10n/app_localizations.dart';
import 'package:moomoo/presentation/screens/learning/learning_screen.dart';

void main() {
  const language = SignLanguage(id: 1, code: 'LSF', name: 'Langue des signes française');

  LearningLesson lesson(int i) => LearningLesson(
        id: 'l$i',
        unitId: 'u1',
        title: 'Leçon $i',
        orderIndex: i,
        signCount: 3,
      );

  final units = [
    LearningUnit(
      id: 'u1',
      signLanguageId: 1,
      title: 'Les bases',
      isPublished: true,
      lessons: [for (var i = 1; i <= 5; i++) lesson(i)],
    ),
  ];

  Future<void> pump(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) => Stream.value(null)),
          signLanguagesProvider.overrideWith((ref) async => const [language]),
          learningLanguageProvider.overrideWith((ref) async => language),
          learningPathProvider(1).overrideWith((ref) async => units),
          learningProgressProvider.overrideWith(
            (ref) async => const {
              'l1': LessonProgress(lessonId: 'l1', bestCorrect: 9, questionCount: 10, completions: 1),
            },
          ),
          learnerSummaryProvider.overrideWith((ref) async => const LearnerSummary(totalXp: 40)),
          canEditLearningProvider.overrideWith((ref) async => false),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LearningScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
  }

  for (final size in const [Size(360, 740), Size(1280, 800)]) {
    testWidgets('road with lessons, practice stops and trophy at ${size.width}', (tester) async {
      await pump(tester, size);

      expect(tester.takeException(), isNull);
      expect(find.text('Leçon 1'), findsOneWidget);
      expect(find.text('Exercice'), findsWidgets);
      expect(find.text("C'est parti !".toUpperCase()), findsOneWidget);

      // Lessons alternate between the two edges of the road.
      final first = tester.getCenter(find.text('Leçon 1'));
      final second = tester.getCenter(find.text('Leçon 2'));
      expect((first.dx - second.dx).abs(), greaterThan(150));
    });
  }

  testWidgets('only the path scrolls, the header stays put', (tester) async {
    await pump(tester, const Size(360, 740));

    final title = find.text('Parcours LSF');
    final before = tester.getTopLeft(title);
    final lessonBefore = tester.getTopLeft(find.text('Leçon 1'));

    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -300));
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    expect(tester.getTopLeft(title), before);
    expect(tester.getTopLeft(find.text('Leçon 1')).dy, lessonBefore.dy - 300);
  });
}
