import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';

/// Distinct, flat colours for overlaid series (compared experiments).
const List<Color> kMlSeriesColors = [
  AppColors.primary,
  AppColors.warning,
  AppColors.success,
  Color(0xFF7C3AED),
  AppColors.error,
  Color(0xFF0891B2),
];

class MlChartSeries {
  const MlChartSeries({
    required this.label,
    required this.color,
    required this.spots,
    this.dashed = false,
  });

  final String label;
  final Color color;
  final List<FlSpot> spots;

  /// Validation curves are dashed so train/val differ by more than colour.
  final bool dashed;
}

class MlLineChart extends StatelessWidget {
  const MlLineChart({
    super.key,
    required this.series,
    required this.semanticLabel,
    this.minY,
    this.maxY,
    this.formatY,
    this.height = 220,
  });

  final List<MlChartSeries> series;
  final String semanticLabel;
  final double? minY;
  final double? maxY;
  final String Function(double value)? formatY;
  final double height;

  String _format(double v) => formatY?.call(v) ?? v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final secondary = AppColors.textSecondary(context);
    final visible = series.where((s) => s.spots.isNotEmpty).toList();
    if (visible.isEmpty) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.neutral(context),
          borderRadius: AppRadius.radiusM,
        ),
        child: Text(
          l10n.mlChartNoData,
          style: AppTextStyles.bodySmall.copyWith(color: secondary),
        ),
      );
    }

    final maxX = visible
        .expand((s) => s.spots)
        .map((s) => s.x)
        .fold<double>(1, math.max);
    final xInterval = math.max(1, (maxX / 6).ceil()).toDouble();
    final labelStyle = AppTextStyles.bodySmall.copyWith(
      color: secondary,
      fontSize: 11,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: semanticLabel,
          image: true,
          child: ExcludeSemantics(
            child: SizedBox(
              height: height,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  minX: visible.expand((s) => s.spots).map((s) => s.x).reduce(math.min),
                  maxX: maxX,
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: AppColors.border(context),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 52,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(_format(value), style: labelStyle),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: xInterval,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(
                            value.toStringAsFixed(0),
                            style: labelStyle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => AppColors.primaryDeep,
                      getTooltipItems: (spots) => [
                        for (final s in spots)
                          LineTooltipItem(
                            '${visible[s.barIndex].label} · ${s.x.toStringAsFixed(0)} : ${_format(s.y)}',
                            const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  lineBarsData: [
                    for (final s in visible)
                      LineChartBarData(
                        spots: s.spots,
                        color: s.color,
                        barWidth: 2,
                        isCurved: false,
                        dashArray: s.dashed ? const [6, 4] : null,
                        dotData: FlDotData(show: s.spots.length == 1),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Wrap(
          spacing: AppSpacing.m,
          runSpacing: AppSpacing.xs,
          children: [
            for (final s in visible) MlLegendItem(label: s.label, color: s.color, dashed: s.dashed),
          ],
        ),
      ],
    );
  }
}

class MlLegendItem extends StatelessWidget {
  const MlLegendItem({
    super.key,
    required this.label,
    required this.color,
    this.dashed = false,
  });

  final String label;
  final Color color;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < (dashed ? 2 : 1); i++) ...[
                if (i > 0) const SizedBox(width: 3),
                Container(
                  width: dashed ? 8 : 18,
                  height: 3,
                  color: color,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}
