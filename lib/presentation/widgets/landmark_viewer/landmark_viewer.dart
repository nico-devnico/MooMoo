import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/sign_landmarks.dart';
import '../../../l10n/app_localizations.dart';
import 'skeleton_painter.dart';

/// Plays the recorded landmarks of a sign: a looping stick figure for a
/// sequence extracted from a video or a GIF, a still one for a single pose.
///
/// Hands use two colours that stay distinct for colour-blind people (blue and
/// orange) on top of a high-contrast background.
class LandmarkViewer extends StatefulWidget {
  const LandmarkViewer({super.key, required this.landmarks, this.showControls = true});

  final SignLandmarks landmarks;
  final bool showControls;

  @override
  State<LandmarkViewer> createState() => _LandmarkViewerState();
}

class _LandmarkViewerState extends State<LandmarkViewer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Rect? _bounds;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _configure();
  }

  @override
  void didUpdateWidget(LandmarkViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.landmarks != widget.landmarks) {
      _configure();
      _sync();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  void _configure() {
    final landmarks = widget.landmarks;
    _bounds = landmarks.bounds;
    if (landmarks.isAnimated) {
      final duration = landmarks.duration;
      _controller.duration =
          duration < const Duration(milliseconds: 400) ? const Duration(milliseconds: 400) : duration;
    }
    _controller.value = 0;
  }

  bool get _reducedMotion => MediaQuery.disableAnimationsOf(context);

  /// Loops on its own, except when the user paused it or asked for reduced
  /// motion; then a still pose from the middle of the sign is shown and the
  /// play button runs it once.
  void _sync() {
    final autoplay = widget.landmarks.isAnimated && !_paused && !_reducedMotion;
    if (autoplay && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!autoplay && _controller.isAnimating && !_reducedMotion) {
      _controller.stop();
    } else if (_reducedMotion && !_controller.isAnimating && widget.landmarks.isAnimated) {
      _controller.value = 0.5;
    }
  }

  void _togglePlay() {
    if (_controller.isAnimating) {
      _controller.stop();
      setState(() => _paused = true);
    } else if (_reducedMotion) {
      _controller.forward(from: 0).whenComplete(() {
        if (mounted) setState(() => _controller.value = 0.5);
      });
      setState(() {});
    } else {
      setState(() => _paused = false);
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  LandmarkFrame _frameAt(double t) {
    final frames = widget.landmarks.frames;
    final i = (t * frames.length).floor().clamp(0, frames.length - 1);
    return frames[i];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final landmarks = widget.landmarks;

    final background = ColoredBox(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: CustomPaint(painter: _GridPainter(isDark: isDark), child: const SizedBox.expand()),
    );

    if (landmarks.isEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          background,
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.signLanguage, size: 44, color: AppColors.textSecondary(context)),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    l10n.noLandmarkData,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final bodyColor = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : AppColors.primaryDeep.withValues(alpha: 0.45);

    return Semantics(
      image: true,
      label: l10n.landmarksLabel,
      child: Stack(
        fit: StackFit.expand,
        children: [
          background,
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                painter: SkeletonPainter(
                  frame: _frameAt(_controller.value),
                  bounds: _bounds,
                  bodyColor: bodyColor,
                  leftHandColor: AppColors.warning,
                  rightHandColor: isDark ? AppColors.secondary : AppColors.primary,
                ),
              ),
            ),
          ),
          if (widget.showControls && landmarks.isAnimated)
            Positioned(
              right: AppSpacing.s,
              bottom: AppSpacing.s,
              child: IconButton.filledTonal(
                tooltip: _controller.isAnimating ? l10n.landmarksPause : l10n.landmarksPlay,
                onPressed: _togglePlay,
                icon: Icon(_controller.isAnimating ? AppIcons.pause : AppIcons.play),
              ),
            ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04)
      ..strokeWidth = 1;
    const divisions = 12;
    for (var i = 0; i <= divisions; i++) {
      final x = size.width * i / divisions;
      final y = size.height * i / divisions;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => oldDelegate.isDark != isDark;
}
