import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/models/sign_landmarks.dart';
import 'mediapipe_connections.dart';

/// MediaPipe-like stick figure: thin sharp strokes for pose, face contours and
/// both hands — same connection sets as the Holistic / FaceMesh docs.
class SkeletonPainter extends CustomPainter {
  SkeletonPainter({
    required this.frame,
    required this.bounds,
    required this.bodyColor,
    required this.faceColor,
    required this.leftHandColor,
    required this.rightHandColor,
  });

  final LandmarkFrame frame;
  final Rect? bounds;
  final Color bodyColor;
  final Color faceColor;
  final Color leftHandColor;
  final Color rightHandColor;

  static const int _leftWrist = 15;
  static const int _rightWrist = 16;

  @override
  void paint(Canvas canvas, Size size) {
    if (frame.isEmpty || size.isEmpty) return;

    final map = _mapper(size);
    // Thin but crisp — scales gently with the viewport.
    final stroke = (size.shortestSide / 280).clamp(1.0, 1.75);
    final dot = (stroke * 0.85).clamp(0.9, 1.6);

    final face = frame.face;
    if (face != null) {
      _paintGraph(
        canvas,
        face,
        MediaPipeConnections.faceContours,
        map,
        stroke * 0.85,
        faceColor,
        drawDots: false,
      );
    }

    final pose = frame.pose;
    if (pose != null) {
      _paintGraph(
        canvas,
        pose,
        MediaPipeConnections.pose,
        map,
        stroke,
        bodyColor,
        dotRadius: dot,
      );
    }

    final left = frame.leftHand;
    if (left != null) {
      _paintGraph(
        canvas,
        left,
        MediaPipeConnections.hand,
        map,
        stroke,
        leftHandColor,
        dotRadius: dot * 1.05,
      );
      if (pose != null) {
        _linkWrist(canvas, pose, _leftWrist, left.first, map, stroke, leftHandColor);
      }
    }

    final right = frame.rightHand;
    if (right != null) {
      _paintGraph(
        canvas,
        right,
        MediaPipeConnections.hand,
        map,
        stroke,
        rightHandColor,
        dotRadius: dot * 1.05,
      );
      if (pose != null) {
        _linkWrist(canvas, pose, _rightWrist, right.first, map, stroke, rightHandColor);
      }
    }
  }

  Offset Function(Offset) _mapper(Size size) {
    var box = bounds ?? const Rect.fromLTWH(0, 0, 1, 1);
    final minSide = math.max(box.longestSide, 0.28);
    box = Rect.fromCenter(
      center: box.center,
      width: math.max(box.width, minSide * 0.7),
      height: math.max(box.height, minSide * 0.85),
    ).inflate(0.03);
    const fill = 0.92;
    final scale = math.min(
      size.width * fill / box.width,
      size.height * fill / box.height,
    );
    final origin = Offset(
      size.width / 2 - box.center.dx * scale,
      size.height / 2 - box.center.dy * scale,
    );
    return (p) => origin + p * scale;
  }

  bool _has(List<Offset> points, int i) =>
      i < points.length && points[i] != Offset.zero;

  void _paintGraph(
    Canvas canvas,
    List<Offset> points,
    List<List<int>> connections,
    Offset Function(Offset) map,
    double stroke,
    Color color, {
    double? dotRadius,
    bool drawDots = true,
  }) {
    final bone = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    for (final c in connections) {
      if (!_has(points, c[0]) || !_has(points, c[1])) continue;
      canvas.drawLine(map(points[c[0]]), map(points[c[1]]), bone);
    }

    if (!drawDots || dotRadius == null) return;
    final joint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    for (var i = 0; i < points.length; i++) {
      if (!_has(points, i)) continue;
      canvas.drawCircle(map(points[i]), dotRadius, joint);
    }
  }

  void _linkWrist(
    Canvas canvas,
    List<Offset> pose,
    int wrist,
    Offset handRoot,
    Offset Function(Offset) map,
    double stroke,
    Color handColor,
  ) {
    if (!_has(pose, wrist) || handRoot == Offset.zero) return;
    canvas.drawLine(
      map(pose[wrist]),
      map(handRoot),
      Paint()
        ..color = Color.lerp(bodyColor, handColor, 0.35)!
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant SkeletonPainter oldDelegate) {
    return oldDelegate.frame != frame ||
        oldDelegate.bounds != bounds ||
        oldDelegate.bodyColor != bodyColor ||
        oldDelegate.faceColor != faceColor ||
        oldDelegate.leftHandColor != leftHandColor ||
        oldDelegate.rightHandColor != rightHandColor;
  }
}
