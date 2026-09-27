import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';

/// Per-cell tooltips stop being useful (and get costly) past this size.
const _tooltipMaxClasses = 40;

/// Heatmap of true (rows) vs predicted (columns) classes. Intensity is the
/// share of the true class, so a dark diagonal means a good classifier; the
/// count is always written in the cell, colour is never the only signal.
class MlConfusionMatrix extends StatelessWidget {
  const MlConfusionMatrix({
    super.key,
    required this.labels,
    required this.matrix,
  });

  final List<String> labels;
  final List<List<int>> matrix;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final n = math.min(labels.length, matrix.length);
    if (n == 0) {
      return Text(
        l10n.mlChartNoData,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary(context),
        ),
      );
    }

    var total = 0;
    var correct = 0;
    for (var i = 0; i < n; i++) {
      for (var j = 0; j < math.min(n, matrix[i].length); j++) {
        total += matrix[i][j];
        if (i == j) correct += matrix[i][j];
      }
    }
    final cell = n > 30 ? 30.0 : 40.0;
    final labelWidth = 120.0;
    final headerHeight = 96.0;
    final secondary = AppColors.textSecondary(context);
    final smallStyle = AppTextStyles.bodySmall.copyWith(fontSize: 10);
    final withTooltips = n <= _tooltipMaxClasses;

    Widget cellAt(int i, int j) {
      final row = matrix[i];
      final value = j < row.length ? row[j] : 0;
      final rowSum = row.fold<int>(0, (a, b) => a + b);
      final ratio = rowSum == 0 ? 0.0 : value / rowSum;
      final color = value == 0
          ? AppColors.neutral(context)
          : AppColors.primary.withValues(alpha: 0.12 + 0.88 * ratio);
      final box = Container(
        width: cell,
        height: cell,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: i == j ? AppColors.primaryDeep : AppColors.border(context),
            width: i == j ? 1.5 : 0.5,
          ),
        ),
        child: Text(
          '$value',
          style: smallStyle.copyWith(
            color: ratio > 0.5 ? Colors.white : null,
            fontWeight: i == j ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      );
      if (!withTooltips) return box;
      return Tooltip(
        message: l10n.mlConfusionCell(labels[i], labels[j], value),
        child: box,
      );
    }

    final grid = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: labelWidth + AppSpacing.s),
          child: Text(
            l10n.mlConfusionPredicted,
            style: AppTextStyles.bodySmall.copyWith(
              color: secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              width: labelWidth + AppSpacing.s,
              child: Text(
                l10n.mlConfusionActual,
                style: AppTextStyles.bodySmall.copyWith(
                  color: secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (var j = 0; j < n; j++)
              SizedBox(
                width: cell,
                height: headerHeight,
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      labels[j],
                      overflow: TextOverflow.ellipsis,
                      style: smallStyle,
                    ),
                  ),
                ),
              ),
          ],
        ),
        for (var i = 0; i < n; i++)
          Row(
            children: [
              SizedBox(
                width: labelWidth,
                child: Text(
                  labels[i],
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: smallStyle,
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              for (var j = 0; j < n; j++) cellAt(i, j),
            ],
          ),
      ],
    );

    return Semantics(
      label: l10n.mlConfusionSemantics(
        n,
        correct,
        total,
        total == 0 ? '—' : (correct / total * 100).toStringAsFixed(1),
      ),
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 560),
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: grid,
            ),
          ),
        ),
      ),
    );
  }
}
