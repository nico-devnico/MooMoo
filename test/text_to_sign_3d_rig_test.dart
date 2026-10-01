import 'dart:async';
import 'dart:io';
import 'dart:ui' show Offset;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moomoo/core/constants/character_constants.dart';
import 'package:moomoo/data/models/landmark_compose.dart';
import 'package:moomoo/data/models/sign_landmarks.dart';
import 'package:moomoo/domain/providers/three_d_settings_provider.dart';
import 'package:moomoo/l10n/app_localizations.dart';
import 'package:moomoo/presentation/widgets/avatar/rigged_sign_avatar.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

/// Never resolves so [RiggedSignAvatar] stays on its loading skeleton (no WebView).
class _Hang3dSettings extends ThreeDSettings {
  @override
  Future<Map<String, dynamic>> build() => Completer<Map<String, dynamic>>().future;
}

void main() {
  test('toRigPayload preserves pose XYZ for Mixamo retarget', () {
    final result = LandmarkComposeResult(
      ok: true,
      landmarks: SignLandmarks.empty,
      fps: 15,
      rawFrames: [
        [
          for (var i = 0; i < 33; i++) ...[0.1 + i * 0.001, 0.2, 0.3, 0.9],
          for (var i = 0; i < 21; i++) ...[0.4, 0.5, 0.6],
          for (var i = 0; i < 21; i++) ...[0.7, 0.8, 0.9],
        ],
      ],
    );

    final payload = result.toRigPayload();
    expect(payload, isNotNull);
    expect(payload!['fps'], 15);
    final frames = payload['frames'] as List;
    expect(frames, hasLength(1));
    final pose = frames.first['pose'] as List;
    expect(pose, hasLength(33));
    expect(pose.first, [0.1, 0.2, 0.3]);
    expect((frames.first['leftHand'] as List), hasLength(21));
    expect((frames.first['rightHand'] as List), hasLength(21));
  });

  test('toRigPayload falls back to 2D landmark frames', () {
    final result = LandmarkComposeResult(
      ok: true,
      landmarks: SignLandmarks(
        fps: 12,
        frames: [
          LandmarkFrame(
            pose: [const Offset(0.2, 0.3)],
            leftHand: [const Offset(0.4, 0.5)],
            rightHand: [const Offset(0.6, 0.7)],
          ),
        ],
      ),
    );
    final payload = result.toRigPayload();
    expect(payload!['fps'], 12);
    final pose = (payload['frames'] as List).first['pose'] as List;
    expect(pose.first, [0.2, 0.3, 0.0]);
  });

  test('French avatar copy no longer says signs are unavailable', () {
    final fr = lookupAppLocalizations(const Locale('fr'));
    expect(fr.translAvatarNote, isNot(contains('ne reproduit')));
    expect(fr.translAvatarNote, contains('animer'));
    expect(fr.translAvatarPlaying, contains('Animation'));
  });

  test('compose path must not force landmarks mode (source guard)', () {
    final source = File(
      'lib/presentation/screens/translator/translator_screen.dart',
    ).readAsStringSync();
    expect(source.contains('setMode(SignViewModeEnum.landmarks)'), isFalse);
    expect(source.contains('RiggedSignAvatar'), isTrue);
    expect(CharacterConstants.defaultCharacterId, isNotEmpty);
  });

  testWidgets('model3d stage shows RiggedSignAvatar without legacy unavailable copy', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final l10n = lookupAppLocalizations(const Locale('fr'));
    final container = ProviderContainer(overrides: [
      threeDSettingsProvider.overrideWith(_Hang3dSettings.new),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Column(
              children: [
                const Expanded(child: RiggedSignAvatar()),
                Text(l10n.translAvatarNote),
                Icon(PhosphorIconsRegular.cube),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(RiggedSignAvatar), findsOneWidget);
    expect(find.text(l10n.translAvatarNote), findsOneWidget);
    expect(find.textContaining('ne reproduit pas encore les signes'), findsNothing);
    expect(find.byIcon(PhosphorIconsRegular.cube), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
