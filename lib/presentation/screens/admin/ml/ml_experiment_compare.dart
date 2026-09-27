import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/ml_training.dart';
import '../../../../domain/providers/ml_training_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/app_panel.dart';
import 'ml_charts.dart';
import 'ml_common.dart';

/// Overlaid validation curves and a side-by-side metrics table.
class MlExperimentCompare extends ConsumerWidget {
  const MlExperimentCompare({
    super.key,
    required this.experiments,
    required this.onClose,
  });

  final List<MlExperiment> experiments;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final series = <MlChartSeries>[];
    for (var i = 0; i < experiments.length; i++) {
      final epochs = ref.watch(mlEpochsProvider(experiments[i].id)).value ?? const [];
      series.add(
        MlChartSeries(
          label: experiments[i].code,
          color: kMlSeriesColors[i % kMlSeriesColors.length],
          spots: [
            for (final e in epochs)
              if (e.valAccuracy != null) FlSpot(e.epoch.toDouble(), e.valAccuracy!),
          ],
        ),
      );
    }

    return AppPanel(
      borderColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: MlSectionTitle(l10n.mlCompareTitle, small: true)),
              TextButton(
                onPressed: onClose,
                child: Text(l10n.mlClose),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            l10n.mlCompareValAccuracy,
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.s),
          MlLineChart(
            semanticLabel: l10n.mlCompareSemantics(experiments.length),
            series: series,
            minY: 0,
            maxY: 1,
            formatY: (v) => '${(v * 100).toStringAsFixed(0)}%',
          ),
          const SizedBox(height: AppSpacing.l),
          _MetricsTable(experiments: experiments),
          const SizedBox(height: AppSpacing.s),
          Text(
            l10n.mlCompareBestHint,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsTable extends StatelessWidget {
  const _MetricsTable({required this.experiments});

  final List<MlExperiment> experiments;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // (label, value getter, display, higher is better)
    final rows = <(String, double? Function(MlExperiment), String Function(MlExperiment), bool)>[
      (l10n.mlMetricAccuracy, (e) => e.accuracy, (e) => mlPercent(e.accuracy), true),
      (l10n.mlMetricPrecision, (e) => e.precision, (e) => mlPercent(e.precision), true),
      (l10n.mlMetricRecall, (e) => e.recall, (e) => mlPercent(e.recall), true),
      (l10n.mlMetricF1, (e) => e.f1, (e) => mlPercent(e.f1), true),
      (l10n.mlColMacroF1, (e) => e.macroF1, (e) => mlPercent(e.macroF1), true),
      (l10n.mlColBestValLoss, (e) => e.bestValLoss, (e) => mlNumber(e.bestValLoss), false),
      (
        l10n.mlMetricParams,
        (e) => e.paramsCount?.toDouble(),
        (e) => e.paramsCount?.toString() ?? '—',
        false,
      ),
      (
        l10n.mlMetricSize,
        (e) => e.modelSizeBytes?.toDouble(),
        (e) => mlFormatBytes(l10n, e.modelSizeBytes),
        false,
      ),
      (l10n.mlColDuration, (e) => e.durationS, (e) => mlFormatSeconds(e.durationS), false),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w700,
        ),
        dataTextStyle: AppTextStyles.bodySmall,
        columnSpacing: AppSpacing.l,
        columns: [
          DataColumn(label: Text(l10n.mlCompareMetric)),
          for (var i = 0; i < experiments.length; i++)
            DataColumn(
              numeric: true,
              label: MlLegendItem(
                label: experiments[i].code,
                color: kMlSeriesColors[i % kMlSeriesColors.length],
              ),
            ),
        ],
        rows: [
          for (final (label, value, display, higherBetter) in rows)
            () {
              final values = experiments.map(value).whereType<double>().toList();
              final best = values.isEmpty
                  ? null
                  : values.reduce(
                      (a, b) => higherBetter ? (a > b ? a : b) : (a < b ? a : b),
                    );
              return DataRow(
                cells: [
                  DataCell(Text(label)),
                  for (final e in experiments)
                    DataCell(
                      Text(
                        value(e) != null && value(e) == best && values.length > 1
                            ? '${display(e)} ★'
                            : display(e),
                        style: TextStyle(
                          fontWeight: value(e) != null && value(e) == best
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                ],
              );
            }(),
        ],
      ),
    );
  }
}
