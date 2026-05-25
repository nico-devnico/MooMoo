import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class CameraOverlayPainter extends CustomPainter {
  final bool isRecording;
  final Animation<double> animation;

  CameraOverlayPainter({
    required this.isRecording,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Main body frame - Adapts to screen size (Maximize coverage)
    final rectWidth = size.width * 0.98;
    final rectHeight = size.height * 0.95;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: rectWidth,
      height: rectHeight,
    );
    final RRect rrect = RRect.fromRectAndRadius(rect, const Radius.circular(24));

    // Draw semi-transparent overlay around the targeting area
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(overlayPath, paint);

    // Camera corners (Viewfinder style)
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const cornerLength = 40.0;
    
    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.top + cornerLength)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.left + cornerLength, rect.top),
      cornerPaint,
    );
    // Top Right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - cornerLength, rect.top)
        ..lineTo(rect.right, rect.top)
        ..lineTo(rect.right, rect.top + cornerLength),
      cornerPaint,
    );
    // Bottom Left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.bottom - cornerLength)
        ..lineTo(rect.left, rect.bottom)
        ..lineTo(rect.left + cornerLength, rect.bottom),
      cornerPaint,
    );
    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - cornerLength, rect.bottom)
        ..lineTo(rect.right, rect.bottom)
        ..lineTo(rect.right, rect.bottom - cornerLength),
      cornerPaint,
    );

    // Scanning line
    final scanPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    final scanY = rect.top + (rectHeight * animation.value);
    canvas.drawLine(
      Offset(rect.left + 10, scanY),
      Offset(rect.right - 10, scanY),
      scanPaint,
    );

    // Status indicator
    _drawStatusIndicator(canvas, size, rect);
  }

  void _drawAnimatedDashes(Canvas canvas, RRect rrect, Paint paint) {
    // This is a simplified version of animated dashes
    // In a real app, we'd use a more sophisticated dash path effect
    final double phase = animation.value * 2 * math.pi;
    
    // Pulse effect
    final double pulse = 1.0 + (math.sin(phase) * 0.05);
    
    canvas.save();
    canvas.translate(rrect.center.dx, rrect.center.dy);
    canvas.scale(pulse);
    canvas.translate(-rrect.center.dx, -rrect.center.dy);
    canvas.drawRRect(rrect, paint);
    canvas.restore();
  }

  void _drawStatusIndicator(Canvas canvas, Size size, Rect targetRect) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: isRecording ? '⏺ ENREGISTREMENT' : '🔴 CAMÉRA ACTIVE',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final bgRect = Rect.fromCenter(
      center: Offset(size.width / 2, targetRect.top - 30),
      width: textPainter.width + 24,
      height: 32,
    );

    final bgPaint = Paint()
      ..color = isRecording ? AppColors.error : Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(RRect.fromRectAndRadius(bgRect, const Radius.circular(16)), bgPaint);
    textPainter.paint(
      canvas,
      Offset(size.width / 2 - textPainter.width / 2, targetRect.top - 30 - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CameraOverlayPainter oldDelegate) {
    return oldDelegate.isRecording != isRecording || oldDelegate.animation != animation;
  }
}
