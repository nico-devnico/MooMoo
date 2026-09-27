import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/ml_training.dart';
import '../../../../domain/providers/ml_training_provider.dart';
import '../../../../l10n/app_localizations.dart';
import 'ml_common.dart';
import 'ml_experiment_detail.dart';
import 'ml_jobs_tab.dart';
import 'ml_skeletons.dart';

Future<void> showMlJobDetail(BuildContext context, TrainingJobDetail job) {
  final l10n = AppLocalizations.of(context)!;
  return showMlAdaptive<void>(
    context,
    title: '${mlJobKindLabel(l10n, job.kind)} · ${job.dataset}',
    builder: (_) => MlJobDetailView(initial: job),
  );
}

class MlJobDetailView extends ConsumerWidget {
  const MlJobDetailView({super.key, required this.initial});

  final TrainingJobDetail initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final job = ref
            .watch(mlJobsProvider)
            .value
            ?.where((j) => j.id == initial.id)
            .firstOrNull ??
        initial;
    final status = mlJobStatus(l10n, job.status);
    final elapsed = job.elapsed;
    final showExperiments = job.kind == 'train' || job.kind == 'search';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            MlStatusBadge(info: status),
            MlMetricChip(
              label: l10n.mlProgress,
              value: '${job.progress.clamp(0, 100).toStringAsFixed(0)} %',
            ),
            if (job.languageCode != null)
              MlMetricChip(label: l10n.mlFieldLanguage, value: job.languageCode!),
            if (job.totalEpochs != null)
              MlMetricChip(
                label: l10n.mlColEpochs,
                value: '${job.currentEpoch ?? 0} / ${job.totalEpochs}',
              ),
            if (elapsed != null)
              MlMetricChip(label: l10n.mlColDuration, value: mlFormatDuration(elapsed)),
            if (job.attempts > 1)
              MlMetricChip(
                label: l10n.mlAttempts,
                value: '${job.attempts}',
                color: AppColors.warningLedge,
              ),
          ],
        ),
        if (job.isActive) ...[
          const SizedBox(height: AppSpacing.m),
          LinearProgressIndicator(
            value: job.status == 'queued' ? null : job.progress.clamp(0, 100) / 100,
            minHeight: 6,
            borderRadius: AppRadius.radiusCircular,
            backgroundColor: AppColors.neutral(context),
            semanticsLabel: l10n.mlProgress,
          ),
        ],
        if (job.message?.isNotEmpty ?? false) ...[
          const SizedBox(height: AppSpacing.m),
          MlNoticeLine(
            icon: AppIcons.info,
            color: AppColors.textSecondary(context),
            text: job.message!,
          ),
        ],
        if (job.errorMessage?.isNotEmpty ?? false)
          MlNoticeLine(
            icon: AppIcons.error,
            color: AppColors.error,
            text: job.errorMessage!,
          ),
        if (job.isCancellable) ...[
          const SizedBox(height: AppSpacing.m),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                minimumSize: const Size(0, 48),
              ),
              onPressed: () => mlCancelJob(context, ref, job),
              icon: const Icon(AppIcons.stop, size: 18),
              label: Text(l10n.mlActionCancelJob),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.l),
        if (showExperiments)
          MlDetailSection(
            title: l10n.mlTabExperiments,
            child: _JobExperiments(jobId: job.id),
          ),
        MlDetailSection(
          title: l10n.mlLogs,
          child: _JobLogs(jobId: job.id),
        ),
      ],
    );
  }
}

class _JobExperiments extends ConsumerWidget {
  const _JobExperiments({required this.jobId});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ref.watch(mlJobExperimentsProvider(jobId)).when(
          loading: () => MlDetailSkeleton(label: l10n.loading, charts: 1),
          error: (e, _) => MlNoticeLine(
            icon: AppIcons.error,
            color: AppColors.error,
            text: mlErrorText(l10n, e),
          ),
          data: (experiments) {
            if (experiments.isEmpty) {
              return Text(
                l10n.mlExperimentsNone,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary(context),
                ),
              );
            }
            return MlExperimentsTable(
              experiments: experiments,
              onTap: (exp) => showMlExperimentDetail(context, exp),
            );
          },
        );
  }
}

/// Compact experiment table; scrolls horizontally on narrow screens.
class MlExperimentsTable extends StatelessWidget {
  const MlExperimentsTable({
    super.key,
    required this.experiments,
    required this.onTap,
  });

  final List<MlExperiment> experiments;
  final ValueChanged<MlExperiment> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sorted = [...experiments]
      ..sort((a, b) => (b.bestValAccuracy ?? -1).compareTo(a.bestValAccuracy ?? -1));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        showCheckboxColumn: false,
        headingTextStyle: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w700,
        ),
        dataTextStyle: AppTextStyles.bodySmall,
        columnSpacing: AppSpacing.l,
        columns: [
          DataColumn(label: Text(l10n.mlColCode)),
          DataColumn(label: Text(l10n.mlColStatus)),
          DataColumn(label: Text(l10n.mlColRung), numeric: true),
          DataColumn(label: Text(l10n.mlColEpochs), numeric: true),
          DataColumn(label: Text(l10n.mlColBestValAcc), numeric: true),
          DataColumn(label: Text(l10n.mlColTestAcc), numeric: true),
          DataColumn(label: Text(l10n.mlColMacroF1), numeric: true),
          DataColumn(label: Text(l10n.mlColDuration), numeric: true),
        ],
        rows: [
          for (final e in sorted)
            DataRow(
              onSelectChanged: (_) => onTap(e),
              cells: [
                DataCell(Text(e.code, style: AppTextStyles.mono)),
                DataCell(MlStatusBadge(info: mlExperimentStatus(l10n, e.status))),
                DataCell(Text(e.rung?.toString() ?? '—')),
                DataCell(Text('${e.currentEpoch} / ${e.totalEpochs ?? e.budgetEpochs ?? '—'}')),
                DataCell(Text(mlPercent(e.bestValAccuracy))),
                DataCell(Text(mlPercent(e.accuracy))),
                DataCell(Text(mlPercent(e.macroF1))),
                DataCell(Text(mlFormatSeconds(e.durationS))),
              ],
            ),
        ],
      ),
    );
  }
}

class _JobLogs extends ConsumerWidget {
  const _JobLogs({required this.jobId});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ref.watch(mlJobLogsProvider(jobId)).when(
          loading: () => MlDetailSkeleton(label: l10n.loading, charts: 1),
          error: (e, _) => MlNoticeLine(
            icon: AppIcons.error,
            color: AppColors.error,
            text: mlErrorText(l10n, e),
          ),
          data: (lines) {
            if (lines.isEmpty) {
              return Text(
                l10n.mlLogsEmpty,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary(context),
                ),
              );
            }
            return Container(
              constraints: const BoxConstraints(maxHeight: 360),
              decoration: BoxDecoration(
                color: AppColors.neutral(context),
                borderRadius: AppRadius.radiusM,
              ),
              child: SelectionArea(
                child: SingleChildScrollView(
                  reverse: true,
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [for (final line in lines) _LogLine(line: line)],
                  ),
                ),
              ),
            );
          },
        );
  }
}

class _LogLine extends StatelessWidget {
  const _LogLine({required this.line});

  final TrainingLogLine line;

  @override
  Widget build(BuildContext context) {
    final color = switch (line.level) {
      'error' || 'critical' => AppColors.error,
      'warning' => AppColors.warningLedge,
      _ => null,
    };
    final time = line.createdAt?.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    final stamp = time == null
        ? ''
        : '${two(time.hour)}:${two(time.minute)}:${two(time.second)} ';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text(
        '$stamp${line.level.toUpperCase().padRight(7)} ${line.message}',
        style: AppTextStyles.mono.copyWith(color: color),
      ),
    );
  }
}
