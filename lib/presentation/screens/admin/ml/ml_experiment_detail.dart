import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/ml_training.dart';
import '../../../../domain/providers/ml_training_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/app_badge.dart';
import '../../../widgets/app_snackbar.dart';
import 'ml_charts.dart';
import 'ml_common.dart';
import 'ml_confusion_matrix.dart';
import 'ml_skeletons.dart';
import 'ml_training_dialog.dart';

Future<void> showMlExperimentDetail(BuildContext context, MlExperiment exp) {
  final l10n = AppLocalizations.of(context)!;
  return showMlAdaptive<void>(
    context,
    title: l10n.mlExperimentTitle(exp.code),
    maxWidth: 1000,
    builder: (_) => MlExperimentDetailView(initial: exp),
  );
}

/// "LSTM 128-256-128 Â· lr 0.001 Â· batch 32 Â· adam"
String mlHyperparamsText(MlExperiment e) {
  final m = e.modelConfig;
  return [
    if (m['learning_rate'] != null) 'lr ${m['learning_rate']}',
    if (m['batch_size'] != null) 'batch ${m['batch_size']}',
    if (m['optimizer'] != null) '${m['optimizer']}',
  ].join(' Â· ');
}

class MlExperimentDetailView extends ConsumerStatefulWidget {
  const MlExperimentDetailView({super.key, required this.initial});

  final MlExperiment initial;

  @override
  ConsumerState<MlExperimentDetailView> createState() =>
      _MlExperimentDetailViewState();
}

class _MlExperimentDetailViewState
    extends ConsumerState<MlExperimentDetailView> {
  bool _registering = false;

  Future<void> _register(MlExperiment exp) async {
    final l10n = AppLocalizations.of(context)!;
    final quantization = await showMlQuantizationDialog(
      context,
      title: l10n.mlRegisterTitle,
    );
    if (quantization == null || !mounted) return;
    setState(() => _registering = true);
    try {
      await ref
          .read(mlTrainingRepositoryProvider)
          .registerExperiment(exp, quantization: quantization);
      refreshMlTraining(ref);
      if (mounted) AppSnackbar.showSuccess(context, l10n.mlRegisterQueued);
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, mlErrorText(l10n, e));
    } finally {
      if (mounted) setState(() => _registering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final jobId = widget.initial.jobId;
    final exp = (jobId == null
            ? null
            : ref
                .watch(mlJobExperimentsProvider(jobId))
                .value
                ?.where((e) => e.id == widget.initial.id)
                .firstOrNull) ??
        widget.initial;
    final secondary = AppColors.textSecondary(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            MlStatusBadge(info: mlExperimentStatus(l10n, exp.status)),
            AppBadge(label: exp.languageCode, color: AppColors.primary),
            if (exp.modelId != null)
              MlStatusBadge(
                info: (
                  label: l10n.mlRegistered,
                  color: AppColors.success,
                  icon: PhosphorIconsRegular.package,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s),
        Text(
          [exp.architectureText, mlHyperparamsText(exp)]
              .where((s) => s.isNotEmpty)
              .join(' Â· '),
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.m),
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            MlMetricChip(
              label: l10n.mlColEpochs,
              value: '${exp.currentEpoch} / ${exp.totalEpochs ?? exp.budgetEpochs ?? '—'}',
            ),
            MlMetricChip(label: l10n.mlColBestValAcc, value: mlPercent(exp.bestValAccuracy)),
            MlMetricChip(label: l10n.mlColBestValLoss, value: mlNumber(exp.bestValLoss)),
            MlMetricChip(
              label: exp.evaluatedOn == 'validation'
                  ? l10n.mlMetricAccuracyVal
                  : l10n.mlMetricAccuracy,
              value: mlPercent(exp.accuracy),
            ),
            MlMetricChip(label: l10n.mlMetricPrecision, value: mlPercent(exp.precision)),
            MlMetricChip(label: l10n.mlMetricRecall, value: mlPercent(exp.recall)),
            MlMetricChip(label: l10n.mlMetricF1, value: mlPercent(exp.f1)),
            MlMetricChip(label: l10n.mlColMacroF1, value: mlPercent(exp.macroF1)),
            if (exp.paramsCount != null)
              MlMetricChip(label: l10n.mlMetricParams, value: '${exp.paramsCount}'),
            MlMetricChip(
              label: l10n.mlMetricSize,
              value: mlFormatBytes(l10n, exp.modelSizeBytes),
            ),
            MlMetricChip(label: l10n.mlColDuration, value: mlFormatSeconds(exp.durationS)),
            if (exp.rung != null)
              MlMetricChip(label: l10n.mlColRung, value: '${exp.rung}'),
          ],
        ),
        if (exp.errorMessage?.isNotEmpty ?? false) ...[
          const SizedBox(height: AppSpacing.s),
          MlNoticeLine(
            icon: AppIcons.error,
            color: AppColors.error,
            text: exp.errorMessage!,
          ),
        ],
        if (exp.status == 'completed' && exp.modelId == null) ...[
          const SizedBox(height: AppSpacing.m),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, kMinTouchTarget),
              ),
              onPressed: _registering ? null : () => _register(exp),
              icon: _registering
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(PhosphorIconsRegular.package, size: 18),
              label: Text(l10n.mlActionRegister),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.l),
        _EpochCharts(experimentId: exp.id),
        if (exp.labels.isNotEmpty && exp.confusionMatrix.isNotEmpty)
          MlDetailSection(
            title: l10n.mlConfusionTitle,
            child: MlConfusionMatrix(
              labels: exp.labels,
              matrix: exp.confusionMatrix,
            ),
          ),
        if (exp.perClass.isNotEmpty)
          MlDetailSection(
            title: l10n.mlPerClassTitle,
            child: _PerClassTable(rows: exp.perClass),
          ),
        if (exp.dataWarnings.isNotEmpty)
          MlDetailSection(
            title: l10n.mlDataWarnings,
            child: Column(
              children: [
                for (final w in exp.dataWarnings)
                  MlNoticeLine(
                    icon: AppIcons.warning,
                    color: AppColors.warningLedge,
                    text: w,
                  ),
              ],
            ),
          ),
        if (exp.artifactFiles.isNotEmpty)
          MlDetailSection(
            title: l10n.mlArtifacts,
            child: Column(
              children: [
                for (final f in exp.artifactFiles.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        ExcludeSemantics(
                          child: Icon(PhosphorIconsRegular.file, size: 16, color: secondary),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        Expanded(
                          child: SelectableText(f.key, style: AppTextStyles.mono),
                        ),
                        Text(
                          mlFormatBytes(l10n, f.value),
                          style: AppTextStyles.bodySmall.copyWith(color: secondary),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        MlDetailSection(
          title: l10n.mlConfigJson,
          child: MlJsonBlock(data: exp.config),
        ),
      ],
    );
  }
}

class MlJsonBlock extends StatelessWidget {
  const MlJsonBlock({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 360),
      decoration: BoxDecoration(
        color: AppColors.neutral(context),
        borderRadius: AppRadius.radiusM,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: SelectableText(
          const JsonEncoder.withIndent('  ').convert(data),
          style: AppTextStyles.mono,
        ),
      ),
    );
  }
}

class _EpochCharts extends ConsumerWidget {
  const _EpochCharts({required this.experimentId});

  final String experimentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ref.watch(mlEpochsProvider(experimentId)).when(
          loading: () => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.l),
            child: MlDetailSkeleton(label: l10n.loading),
          ),
          error: (e, _) => MlNoticeLine(
            icon: AppIcons.error,
            color: AppColors.error,
            text: mlErrorText(l10n, e),
          ),
          data: (epochs) {
            List<FlSpot> spots(double? Function(EpochMetric) pick) => [
                  for (final e in epochs)
                    if (pick(e) != null) FlSpot(e.epoch.toDouble(), pick(e)!),
                ];

            final accuracy = MlDetailSection(
              title: l10n.mlChartAccuracy,
              child: MlLineChart(
                semanticLabel: l10n.mlChartAccuracySemantics(epochs.length),
                minY: 0,
                maxY: 1,
                formatY: (v) => '${(v * 100).toStringAsFixed(0)}%',
                series: [
                  MlChartSeries(
                    label: l10n.mlChartTrain,
                    color: AppColors.primary,
                    spots: spots((e) => e.accuracy),
                  ),
                  MlChartSeries(
                    label: l10n.mlChartVal,
                    color: AppColors.warning,
                    dashed: true,
                    spots: spots((e) => e.valAccuracy),
                  ),
                ],
              ),
            );
            final loss = MlDetailSection(
              title: l10n.mlChartLoss,
              child: MlLineChart(
                semanticLabel: l10n.mlChartLossSemantics(epochs.length),
                minY: 0,
                series: [
                  MlChartSeries(
                    label: l10n.mlChartTrain,
                    color: AppColors.primary,
                    spots: spots((e) => e.loss),
                  ),
                  MlChartSeries(
                    label: l10n.mlChartVal,
                    color: AppColors.warning,
                    dashed: true,
                    spots: spots((e) => e.valLoss),
                  ),
                ],
              ),
            );
            final lr = MlDetailSection(
              title: l10n.mlChartLearningRate,
              child: MlLineChart(
                semanticLabel: l10n.mlChartLearningRateSemantics(epochs.length),
                height: 160,
                formatY: (v) => v.toStringAsExponential(1),
                series: [
                  MlChartSeries(
                    label: l10n.mlFieldLearningRate,
                    color: AppColors.success,
                    spots: spots((e) => e.learningRate),
                  ),
                ],
              ),
            );

            return LayoutBuilder(
              builder: (context, c) {
                if (c.maxWidth < 720) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [accuracy, loss, lr],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: accuracy),
                        const SizedBox(width: AppSpacing.l),
                        Expanded(child: loss),
                      ],
                    ),
                    lr,
                  ],
                );
              },
            );
          },
        );
  }
}

class _PerClassTable extends StatelessWidget {
  const _PerClassTable({required this.rows});

  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    double? n(Object? v) => (v as num?)?.toDouble();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 420),
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingTextStyle: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
            dataTextStyle: AppTextStyles.bodySmall,
            columnSpacing: AppSpacing.l,
            dataRowMinHeight: 36,
            dataRowMaxHeight: 40,
            columns: [
              DataColumn(label: Text(l10n.mlColLabel)),
              DataColumn(label: Text(l10n.mlMetricPrecision), numeric: true),
              DataColumn(label: Text(l10n.mlMetricRecall), numeric: true),
              DataColumn(label: Text(l10n.mlMetricF1), numeric: true),
              DataColumn(label: Text(l10n.mlColSupport), numeric: true),
            ],
            rows: [
              for (final r in rows)
                DataRow(
                  cells: [
                    DataCell(Text('${r['label'] ?? ''}')),
                    DataCell(Text(mlPercent(n(r['precision'])))),
                    DataCell(Text(mlPercent(n(r['recall'])))),
                    DataCell(
                      Text(
                        mlPercent(n(r['f1'])),
                        style: TextStyle(
                          color: (n(r['f1']) ?? 1) < 0.5 ? AppColors.error : null,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DataCell(Text('${r['support'] ?? '—'}')),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
