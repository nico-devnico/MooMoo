import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/landmark_point.dart';

class SkeletonPainter extends CustomPainter {
  final List<LandmarkPoint> points;
  final bool showNumbers;
  final bool showLabels;

  SkeletonPainter({
    required this.points,
    this.showNumbers = false,
    this.showLabels = false,
  });

  // MediaPipe Hand Connections
  static const List<List<int>> handConnections = [
    [0, 1], [1, 2], [2, 3], [3, 4], // Thumb
    [0, 5], [5, 6], [6, 7], [7, 8], // Index
    [5, 9], [9, 10], [10, 11], [11, 12], // Middle
    [9, 13], [13, 14], [14, 15], [15, 16], // Ring
    [13, 17], [17, 18], [18, 19], [19, 20], // Pinky
    [0, 17], // Palm base
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paintJoint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final paintBone = Paint()
      ..shader = AppColors.primaryGradient.createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Draw bones
    for (final connection in handConnections) {
      if (connection[0] < points.length && connection[1] < points.length) {
        final p1 = points[connection[0]];
        final p2 = points[connection[1]];
        canvas.drawLine(
          Offset(p1.x * size.width, p1.y * size.height),
          Offset(p2.x * size.width, p2.y * size.height),
          paintBone,
        );
      }
    }

    // Draw joints
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final offset = Offset(p.x * size.width, p.y * size.height);
      
      canvas.drawCircle(offset, 6, glowPaint);
      canvas.drawCircle(offset, 4, paintJoint);

      if (showNumbers) {
        _drawText(canvas, i.toString(), offset + const Offset(8, -8), Colors.white70, 10);
      }
      if (showLabels && p.label != null) {
        _drawText(canvas, p.label!, offset + const Offset(8, 8), Colors.white, 10);
      }
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color, double fontSize) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant SkeletonPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.showNumbers != showNumbers ||
        oldDelegate.showLabels != showLabels;
  }
}
