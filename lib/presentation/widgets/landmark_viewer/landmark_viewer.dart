import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/landmark_point.dart';
import '../../../l10n/app_localizations.dart';
import 'skeleton_painter.dart';

class LandmarkViewer extends StatefulWidget {
  final List<LandmarkPoint> points;

  const LandmarkViewer({
    super.key,
    required this.points,
  });

  @override
  State<LandmarkViewer> createState() => _LandmarkViewerState();
}

class _LandmarkViewerState extends State<LandmarkViewer> {
  bool _showLabels = false;
  bool _showNumbers = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      children: [
        // Background with subtle grid and gradient
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: AppRadius.radiusL,
          ),
          child: ClipRRect(
            borderRadius: AppRadius.radiusL,
            child: Stack(
              children: [
                const _GridViewerBackground(),
                // Radial gradient for depth
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.0,
                        colors: [
                          AppColors.primary.withOpacity(isDark ? 0.05 : 0.02),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Skeleton Painter
                Positioned.fill(
                  child: CustomPaint(
                    painter: SkeletonPainter(
                      points: widget.points,
                      showNumbers: _showNumbers,
                      showLabels: _showLabels,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Modern Overlay Controls
        Positioned(
          bottom: AppSpacing.m,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlChip(
                label: l10n.numbers,
                isSelected: _showNumbers,
                onSelected: (val) => setState(() => _showNumbers = val),
              ),
              const SizedBox(width: AppSpacing.s),
              _buildControlChip(
                label: l10n.labels,
                isSelected: _showLabels,
                onSelected: (val) => setState(() => _showLabels = val),
              ),
            ],
          ),
        ),

        // Empty State Hint
        if (widget.points.isEmpty)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.gesture_outlined,
                  size: 48,
                  color: AppColors.primary.withOpacity(0.3),
                ),
                const SizedBox(height: AppSpacing.m),
                Text(
                  l10n.noLandmarkData,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildControlChip({
    required String label,
    required bool isSelected,
    required Function(bool) onSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(
        color: isSelected ? AppColors.primary : Colors.transparent,
        width: 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _GridViewerBackground extends StatelessWidget {
  const _GridViewerBackground();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      painter: _GridPainter(isDark: isDark),
      child: Container(),
    );
  }
}

class _GridPainter extends CustomPainter {
  final bool isDark;
  _GridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const int divisions = 12;
    for (int i = 0; i <= divisions; i++) {
      final x = size.width * (i / divisions);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      
      final y = size.height * (i / divisions);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
