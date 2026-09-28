import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moomoo/data/models/sign.dart';
import 'package:moomoo/domain/learning/lesson_builder.dart';
import 'package:moomoo/domain/providers/profile_provider.dart';
import 'package:moomoo/l10n/app_localizations.dart';
import 'package:moomoo/presentation/screens/learning/widgets/practice_view.dart';

void main() {
  Future<List<bool>> pump(WidgetTester tester, {Size size = const Size(390, 844)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final results = <bool>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [userProfileProvider.overrideWith((ref) => Stream.value(null))],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: PracticeView(
                step: const PracticeStep(
                  Sign(id: 's', word: 'merci'),
                  number: 1,
                  total: 2,
                ),
                onResult: results.add,
                onReset: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return results;
  }

  testWidgets('learners without a camera can rate themselves', (tester) async {
    final results = await pump(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Exercice pratique · 1/2'), findsOneWidget);
    expect(find.text('Reproduisez ce signe'), findsOneWidget);
    expect(find.text('Activer la caméra'), findsOneWidget);

    await tester.ensureVisible(find.text('Je ne peux pas utiliser la caméra'));
    await tester.tap(find.text('Je ne peux pas utiliser la caméra'));
    await tester.pump();
    expect(find.text('Évaluez-vous'), findsOneWidget);

    await tester.ensureVisible(find.text("Je l'ai réussi"));
    await tester.tap(find.text("Je l'ai réussi"));
    await tester.pump();
    expect(results, [true]);
    expect(find.text('Bravo, signe reconnu !'), findsOneWidget);
  });

  testWidgets('a failed self-assessment can be retried', (tester) async {
    final results = await pump(tester, size: const Size(1200, 900));

    await tester.ensureVisible(find.text('Je ne peux pas utiliser la caméra'));
    await tester.tap(find.text('Je ne peux pas utiliser la caméra'));
    await tester.pump();
    await tester.ensureVisible(find.text('Pas encore'));
    await tester.tap(find.text('Pas encore'));
    await tester.pump();
    expect(results, [false]);

    await tester.ensureVisible(find.text('Réessayer'));
    await tester.tap(find.text('Réessayer'));
    await tester.pump();
    expect(find.text("Je l'ai réussi"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
