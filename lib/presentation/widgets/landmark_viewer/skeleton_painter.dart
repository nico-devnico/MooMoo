import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/models/sign_landmarks.dart';

/// Draws one frame of a sign: upper body, head and both hands, zoomed on
/// [bounds] so the hands stay large whatever the framing of the source video.
class SkeletonPainter extends CustomPainter {
  SkeletonPainter({
    required this.frame,
    required this.bounds,
    required this.bodyColor,
    required this.leftHandColor,
    required this.rightHandColor,
  });

  final LandmarkFrame frame;
  final Rect? bounds;
  final Color bodyColor;
  final Color leftHandColor;
  final Color rightHandColor;

  static const List<List<int>> handConnections = [
    [0, 1], [1, 2], [2, 3], [3, 4], // Thumb
    [0, 5], [5, 6], [6, 7], [7, 8], // Index
    [5, 9], [9, 10], [10, 11], [11, 12], // Middle
    [9, 13], [13, 14], [14, 15], [15, 16], // Ring
    [13, 17], [17, 18], [18, 19], [19, 20], // Pinky
    [0, 17], // Palm base
  ];

  static const List<List<int>> bodyConnections = [
    [11, 12], // Shoulders
    [11, 13], [13, 15], // Left arm
    [12, 14], [14, 16], // Right arm
    [11, 23], [12, 24], [23, 24], // Torso
  ];

  static const int _nose = 0;
  static const int _leftShoulder = 11;
  static const int _rightShoulder = 12;
  static const int _leftWrist = 15;
  static const int _rightWrist = 16;

  @override
  void paint(Canvas canvas, Size size) {
    if (frame.isEmpty || size.isEmpty) return;

    final map = _mapper(size);
    final stroke = (size.shortestSide / 60).clamp(2.5, 7.0);

    final pose = frame.pose;
    if (pose != null) _paintBody(canvas, pose, map, stroke);

    final left = frame.leftHand;
    if (left != null) {
      _paintHand(canvas, left, map, stroke, leftHandColor);
      if (pose != null) _link(canvas, pose, _leftWrist, left.first, map, stroke);
    }
    final right = frame.rightHand;
    if (right != null) {
      _paintHand(canvas, right, map, stroke, rightHandColor);
      if (pose != null) _link(canvas, pose, _rightWrist, right.first, map, stroke);
    }
  }

  Offset Function(Offset) _mapper(Size size) {
    var box = bounds ?? const Rect.fromLTWH(0, 0, 1, 1);
    // A single still hand can be tiny: never zoom in more than 4x.
    final minSide = math.max(box.longestSide, 0.25);
    box = Rect.fromCenter(
      center: box.center,
      width: math.max(box.width, minSide * 0.6),
      height: math.max(box.height, minSide * 0.6),
    );
    const fill = 0.84;
    final scale = math.min(size.width * fill / box.width, size.height * fill / box.height);
    final origin = Offset(
      size.width / 2 - box.center.dx * scale,
      size.height / 2 - box.center.dy * scale,
    );
    return (p) => origin + p * scale;
  }

  bool _has(List<Offset> points, int i) => i < points.length && points[i] != Offset.zero;

  void _paintBody(Canvas canvas, List<Offset> pose, Offset Function(Offset) map, double stroke) {
    final bone = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 1.6
      ..strokeCap = StrokeCap.round;

    for (final c in bodyConnections) {
      if (_has(pose, c[0]) && _has(pose, c[1])) {
        canvas.drawLine(map(pose[c[0]]), map(pose[c[1]]), bone);
      }
    }

    // The head gives the hands a reference point (near the face, the chest…).
    if (_has(pose, _nose)) {
      final shoulders = _has(pose, _leftShoulder) && _has(pose, _rightShoulder)
          ? (map(pose[_leftShoulder]) - map(pose[_rightShoulder])).distance
          : stroke * 20;
      canvas.drawCircle(
        map(pose[_nose]),
        (shoulders * 0.32).clamp(stroke * 4, stroke * 30),
        bone,
      );
    }
  }

  void _link(
    Canvas canvas,
    List<Offset> pose,
    int wrist,
    Offset handRoot,
    Offset Function(Offset) map,
    double stroke,
  ) {
    if (!_has(pose, wrist) || handRoot == Offset.zero) return;
    canvas.drawLine(
      map(pose[wrist]),
      map(handRoot),
      Paint()
        ..color = bodyColor
        ..strokeWidth = stroke * 1.6
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintHand(
    Canvas canvas,
    List<Offset> hand,
    Offset Function(Offset) map,
    double stroke,
    Color color,
  ) {
    final bone = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final joint = Paint()..color = color;
    final halo = Paint()..color = color.withValues(alpha: 0.22);

    for (final c in handConnections) {
      if (_has(hand, c[0]) && _has(hand, c[1])) {
        canvas.drawLine(map(hand[c[0]]), map(hand[c[1]]), bone);
      }
    }
    for (var i = 0; i < hand.length; i++) {
      if (!_has(hand, i)) continue;
      final o = map(hand[i]);
      // Fingertips are what tells signs apart: make them stand out.
      final tip = i == 4 || i == 8 || i == 12 || i == 16 || i == 20;
      canvas.drawCircle(o, stroke * (tip ? 2.2 : 1.6), halo);
      canvas.drawCircle(o, stroke * (tip ? 1.25 : 0.9), joint);
    }
  }

  @override
  bool shouldRepaint(covariant SkeletonPainter oldDelegate) {
    return oldDelegate.frame != frame ||
        oldDelegate.bounds != bounds ||
        oldDelegate.bodyColor != bodyColor ||
        oldDelegate.leftHandColor != leftHandColor ||
        oldDelegate.rightHandColor != rightHandColor;
  }
}
