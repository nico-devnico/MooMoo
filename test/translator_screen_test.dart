import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moomoo/core/theme/app_icons.dart';
import 'package:moomoo/data/repositories/session_repository.dart';
import 'package:moomoo/domain/providers/camera_provider.dart';
import 'package:moomoo/domain/providers/session_provider.dart';
import 'package:moomoo/domain/providers/sign_view_provider.dart';
import 'package:moomoo/domain/providers/translator_provider.dart';
import 'package:moomoo/l10n/app_localizations.dart';
import 'package:moomoo/presentation/screens/translator/translator_screen.dart';
import 'package:moomoo/presentation/widgets/app_panel.dart';
import 'package:moomoo/presentation/widgets/camera/camera_view.dart';

class _NoCamera extends CameraState {
  @override
  Future<Never> build() async => throw StateError('no camera in tests');
}

class _NoHistory implements SessionRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _VideoView extends SignViewMode {
  @override
  Future<SignViewModeEnum> build() async => SignViewModeEnum.video;
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required Size size,
  required TranslationMode mode,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(overrides: [
    cameraStateProvider.overrideWith(_NoCamera.new),
    signViewModeProvider.overrideWith(_VideoView.new),
    sessionRepositoryProvider.overrideWithValue(_NoHistory()),
  ]);
  addTearDown(container.dispose);
  container.read(translationModeStateProvider.notifier).setMode(mode);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TranslatorScreen(),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });
  return container;
}

void main() {
  for (final (name, size) in [
    ('mobile', const Size(390, 844)),
    ('desktop', const Size(1400, 900)),
  ]) {
    testWidgets('sign to text lays out without overflow on $name', (tester) async {
      await _pump(tester, size: size, mode: TranslationMode.signToText);

      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('Signes vers texte'), findsOneWidget);
      expect(find.text('Traduire'), findsWidgets);
      expect(find.text('Prêt'), findsOneWidget);
      expect(find.byTooltip('Importer une vidéo ou une image'), findsOneWidget);
      expect(find.byTooltip('Copier le texte'), findsOneWidget);

      // Phones start translating from the bottom bar's central button.
      final phone = name == 'mobile';
      expect(find.byIcon(AppIcons.play), phone ? findsNothing : findsOneWidget);
      if (phone) {
        final camera = tester.getRect(find.byType(CameraView));
        expect(camera.height, greaterThan(size.height * 0.55));
      }
    });

    testWidgets('text to sign lays out without overflow on $name', (tester) async {
      await _pump(tester, size: size, mode: TranslationMode.textToSign);

      expect(tester.takeException(), isNull);
      expect(find.text('Tapez un mot ou une phrase...'), findsOneWidget);
      expect(find.byTooltip('Dicter au micro'), findsOneWidget);
      expect(find.byTooltip('Vidéo'), findsOneWidget);
      expect(
        find.text('Écrivez un mot ou une phrase pour voir le signe correspondant.'),
        findsOneWidget,
      );
      if (name == 'mobile') {
        final stage = tester.getRect(find.byType(AppPanel).last);
        expect(stage.height, greaterThan(size.height * 0.6));
      }
    });
  }

  testWidgets('switching direction swaps the view', (tester) async {
    final container =
        await _pump(tester, size: const Size(390, 844), mode: TranslationMode.signToText);

    await tester.tap(find.text('Texte vers signes'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(container.read(translationModeStateProvider), TranslationMode.textToSign);
    expect(find.text('Tapez un mot ou une phrase...'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
