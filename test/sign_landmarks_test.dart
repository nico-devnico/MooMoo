import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moomoo/data/models/sign_landmarks.dart';
import 'package:moomoo/l10n/app_localizations.dart';
import 'package:moomoo/presentation/widgets/landmark_viewer/landmark_viewer.dart';

List<Map<String, num>> _hand(double dx) => [
      for (var i = 0; i < kHandPoints; i++) {'x': dx + i * 0.01, 'y': 0.5},
    ];

List<double> _holistic({bool left = true, bool right = true}) => [
      for (var i = 0; i < kPosePoints; i++) ...[0.3 + i * 0.01, 0.2 + i * 0.01, 0, 1],
      for (var i = 0; i < kHandPoints; i++) ...(left ? [0.2, 0.6, 0.0] : [0.0, 0.0, 0.0]),
      for (var i = 0; i < kHandPoints; i++) ...(right ? [0.7, 0.6, 0.0] : [0.0, 0.0, 0.0]),
    ];

void main() {
  group('SignLandmarks.parse', () {
    test('reads a single hand with integer coordinates', () {
      final data = {
        'points': [
          {'x': 0, 'y': 1},
          ..._hand(0.2).skip(1),
        ],
      };
      final landmarks = SignLandmarks.parse(data);
      expect(landmarks.frames.length, 1);
      expect(landmarks.frames.single.rightHand, hasLength(kHandPoints));
      expect(landmarks.isAnimated, isFalse);
    });

    test('reads two hands from a plain list of 42 points', () {
      final landmarks = SignLandmarks.parse({
        'points': [..._hand(0.1), ..._hand(0.6)],
      });
      final frame = landmarks.frames.single;
      expect(frame.leftHand, isNotNull);
      expect(frame.rightHand, isNotNull);
      expect(frame.pose, isNull);
    });

    test('plays a sequence of MediaPipe Holistic vectors', () {
      final landmarks = SignLandmarks.parse({
        'fps': 10,
        'frames': [_holistic(), _holistic(left: false), _holistic()],
      });
      expect(landmarks.frames.length, 3);
      expect(landmarks.isAnimated, isTrue);
      expect(landmarks.fps, 10);
      expect(landmarks.duration, const Duration(milliseconds: 300));
      expect(landmarks.frames[1].leftHand, isNull, reason: 'zeros mean undetected');
      expect(landmarks.frames[1].rightHand, hasLength(kHandPoints));
      expect(landmarks.frames[0].pose, hasLength(kPosePoints));
    });

    test('reads frames made of body part maps and [x, y, z] lists', () {
      final landmarks = SignLandmarks.parse({
        'frames': [
          {
            'left_hand': [for (var i = 0; i < kHandPoints; i++) [0.2, 0.4, 0]],
            'right_hand': null,
          },
          {
            'right_hand': [for (var i = 0; i < kHandPoints; i++) [0.8, 0.4, 0]],
          },
        ],
      });
      expect(landmarks.frames.length, 2);
      expect(landmarks.frames[0].leftHand, isNotNull);
      expect(landmarks.frames[1].rightHand, isNotNull);
    });

    test('bounds ignore the legs MediaPipe guesses off-screen', () {
      final vector = _holistic();
      // Put an ankle (index 27) far below the frame.
      vector[27 * 4 + 1] = 3.0;
      final bounds = SignLandmarks.parse({'frames': [vector]}).bounds!;
      expect(bounds.bottom, lessThan(1.0));
    });

    test('garbage gives an empty result instead of throwing', () {
      expect(SignLandmarks.parse(null).isEmpty, isTrue);
      expect(SignLandmarks.parse({'points': 'nope'}).isEmpty, isTrue);
      expect(SignLandmarks.parse({'frames': [1, 'x', null]}).isEmpty, isTrue);
    });
  });

  testWidgets('the viewer animates a sequence and can be paused', (tester) async {
    final landmarks = SignLandmarks.parse({
      'frames': [_holistic(), _holistic(left: false)],
    });
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(width: 320, height: 320, child: LandmarkViewer(landmarks: landmarks)),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.byTooltip("Mettre l'animation en pause"), findsOneWidget);

    await tester.tap(find.byTooltip("Mettre l'animation en pause"));
    await tester.pump();
    expect(find.byTooltip("Lire l'animation"), findsOneWidget);
  });

  testWidgets('the viewer explains when there is nothing to show', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: LandmarkViewer(landmarks: SignLandmarks.empty)),
    ));
    expect(tester.takeException(), isNull);
    expect(find.byType(Text), findsOneWidget);
  });
}
