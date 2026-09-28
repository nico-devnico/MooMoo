import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moomoo/data/repositories/account_appeal_repository.dart';
import 'package:moomoo/domain/providers/account_appeal_provider.dart';
import 'package:moomoo/domain/providers/profile_provider.dart';
import 'package:moomoo/l10n/app_localizations.dart';
import 'package:moomoo/presentation/screens/auth/account_status_gate.dart';

class _FakeAppeals implements AccountAppealRepository {
  final sent = <(String, String)>[];

  @override
  Future<void> submit({required String email, required String message}) async {
    sent.add((email, message));
  }

  @override
  Future<Map<String, List<AccountAppeal>>> openAppealsByUser() async => {};

  @override
  Future<void> resolveForUser(String userId) async {}
}

void main() {
  testWidgets('banned window lets the user write to the administrators',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final appeals = _FakeAppeals();
    final container = ProviderContainer(overrides: [
      userProfileProvider.overrideWith((ref) => Stream.value(null)),
      accountAppealRepositoryProvider.overrideWithValue(appeals),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => AccountStatusGate(child: child!),
          home: const Scaffold(body: Text('login')),
        ),
      ),
    );

    container
        .read(suspensionNoticeProvider.notifier)
        .show(reason: 'Spam répété', email: 'awa@example.com');
    await tester.pumpAndSettle();

    expect(find.text('Votre compte a été banni'), findsOneWidget);
    expect(find.text('Motif : Spam répété'), findsOneWidget);

    await tester.tap(find.text("Contacter l'administrateur"));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Envoyer'));
    await tester.pumpAndSettle();
    expect(find.text('Écrivez au moins 10 caractères.'), findsOneWidget);
    expect(appeals.sent, isEmpty);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Votre message'),
      'Pourquoi mon compte est-il banni ?',
    );
    await tester.tap(find.text('Envoyer'));
    await tester.pumpAndSettle();

    expect(appeals.sent, [('awa@example.com', 'Pourquoi mon compte est-il banni ?')]);
    expect(find.text('Message envoyé'), findsOneWidget);

    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();
    expect(container.read(suspensionNoticeProvider), isNull);
    expect(find.text('Votre compte a été banni'), findsNothing);
  });
}
