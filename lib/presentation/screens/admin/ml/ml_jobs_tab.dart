import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/ml_training.dart';
import '../../../../domain/providers/ml_training_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/app_panel.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/confirm_dialog.dart';
import 'ml_common.dart';
import 'ml_job_detail.dart';
import 'ml_skeletons.dart';
import 'ml_training_dialog.dart';

/// Past this delay without a heartbeat, no worker is considered alive.
const _workerTimeout = Duration(minutes: 2);

Future<void> mlCancelJob(
  BuildContext context,
  WidgetRef ref,
  TrainingJobDetail job,
) async {
  final l10n = AppLocalizations.of(context)!;
  final ok = await showConfirmDialog(
    context,
    title: l10n.mlJobCancelTitle,
    message: job.status == 'running'
        ? l10n.mlJobCancelRunningMessage
        : l10n.mlJobCancelQueuedMessage,
    confirmLabel: l10n.mlActionCancelJob,
    cancelLabel: l10n.cancel,
    destructive: true,
  );
  if (!ok || !context.mounted) return;
  try {
    await ref.read(mlTrainingRepositoryProvider).cancelJob(job);
    refreshMlTraining(ref);
    if (context.mounted) AppSnackbar.showSuccess(context, l10n.mlJobCancelRequested);
  } catch (e) {
    if (context.mounted) AppSnackbar.showError(context, mlErrorText(l10n, e));
  }
}

class MlJobsTab extends ConsumerWidget {
  const MlJobsTab({super.key, required this.onJobQueued});

  final VoidCallback onJobQueued;

  Future<void> _newTraining(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    List<MlDataset> datasets;
    try {
      datasets = await ref.read(mlDatasetsProvider.future);
    } catch (e) {
      if (context.mounted) AppSnackbar.showError(context, mlErrorText(l10n, e));
      return;
    }
    if (!context.mounted) return;
    if (await showMlTrainingDialog(context, datasets: datasets)) onJobQueued();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final jobsAsync = ref.watch(mlJobsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(mlJobsProvider)
          ..invalidate(mlWorkerHeartbeatProvider);
        await ref.read(mlJobsProvider.future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          AppSpacing.l,
          AppSpacing.l,
          AppSpacing.xxl,
        ),
        children: [
          MlConstrained(
            child: MlTabHeader(
              title: l10n.mlTabJobs,
              subtitle: l10n.mlJobsSubtitle,
              actions: [
                AppButton(
                  label: l10n.mlTrainNew,
                  icon: PhosphorIconsRegular.brain,
                  fullWidth: false,
                  onPressed: () => _newTraining(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          MlConstrained(
            child: _WorkerBanner(jobs: jobsAsync.value ?? const []),
          ),
          MlConstrained(
            child: jobsAsync.when(
              loading: () => MlRowListSkeleton(label: l10n.loading),
              error: (e, _) => MlErrorPanel(
                error: e,
                onRetry: () => ref.invalidate(mlJobsProvider),
              ),
              data: (jobs) {
                if (jobs.isEmpty) {
                  return AppPanel(
                    child: AppEmptyState(
                      icon: AppIcons.history,
                      title: l10n.mlJobsEmpty,
                      message: l10n.mlJobsEmptyMessage,
                    ),
                  );
                }
                return AppPanel(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < jobs.length; i++) ...[
                        if (i > 0)
                          Divider(height: 1, color: AppColors.border(context)),
                        MlJobTile(job: jobs[i]),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkerBanner extends ConsumerWidget {
  const _WorkerBanner({required this.jobs});

  final List<TrainingJobDetail> jobs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final heartbeat = ref.watch(mlWorkerHeartbeatProvider).value;
    final alive = heartbeat != null &&
        DateTime.now().toUtc().difference(heartbeat.toUtc()) < _workerTimeout;
    final hasQueued = jobs.any((j) => j.status == 'queued');

    if (alive) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.m),
        child: MlNoticeLine(
          icon: PhosphorIconsRegular.pulse,
          color: AppColors.successLedge,
          text: l10n.mlWorkerActive(mlFormatDate(heartbeat)),
        ),
      );
    }
    if (!hasQueued) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: AppPanel(
        borderColor: AppColors.warning,
        color: AppColors.warning.withValues(alpha: 0.08),
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ExcludeSemantics(
              child: Icon(AppIcons.warning, color: AppColors.warningLedge),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.mlWorkerMissingTitle,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.warningLedge,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(l10n.mlWorkerMissingMessage, style: AppTextStyles.bodySmall),
                  const SizedBox(height: AppSpacing.xs),
                  SelectableText(
                    'cd ml && python -m moomoo_ml.worker',
                    style: AppTextStyles.mono,
                  ),
                  if (heartbeat != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.mlWorkerLastSeen(mlFormatDate(heartbeat)),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MlJobTile extends ConsumerWidget {
  const MlJobTile({super.key, required this.job});

  final TrainingJobDetail job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final secondary = AppColors.textSecondary(context);
    final status = mlJobStatus(l10n, job.status);
    final kind = mlJobKindLabel(l10n, job.kind);
    final progress = job.progress.clamp(0, 100).toDouble();
    final elapsed = job.elapsed;

    return Semantics(
      button: true,
      label: '$kind, ${status.label}',
      child: InkWell(
        onTap: () => showMlJobDetail(context, job),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: ExcludeSemantics(child: Icon(status.icon, color: status.color)),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.s,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          kind,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        MlStatusBadge(info: status),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      [
                        job.dataset,
                        if (job.languageCode != null) job.languageCode!,
                        if (job.createdAt != null)
                          l10n.admxCreatedOn(mlFormatDate(job.createdAt!)),
                      ].join(' · '),
                      style: AppTextStyles.bodySmall.copyWith(color: secondary),
                    ),
                    if (job.isActive || job.status == 'done') ...[
                      const SizedBox(height: AppSpacing.s),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: job.status == 'queued' ? 0 : progress / 100,
                              minHeight: 6,
                              borderRadius: AppRadius.radiusCircular,
                              backgroundColor: AppColors.neutral(context),
                              color: status.color,
                              semanticsLabel: kind,
                              semanticsValue: '${progress.toStringAsFixed(0)} %',
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s),
                          Text(
                            '${progress.toStringAsFixed(0)} %',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.m,
                      runSpacing: AppSpacing.xs,
                      children: [
                        if (job.totalEpochs != null)
                          Text(
                            l10n.mlJobEpoch(job.currentEpoch ?? 0, job.totalEpochs!),
                            style: AppTextStyles.bodySmall,
                          ),
                        if (elapsed != null)
                          Text(
                            l10n.mlJobElapsed(mlFormatDuration(elapsed)),
                            style: AppTextStyles.bodySmall,
                          ),
                        if (job.attempts > 1)
                          Text(
                            l10n.mlJobAttempts(job.attempts),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.warningLedge,
                            ),
                          ),
                      ],
                    ),
                    if (job.message?.isNotEmpty ?? false)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          job.message!,
                          style: AppTextStyles.bodySmall.copyWith(color: secondary),
                        ),
                      ),
                    if (job.status == 'failed' &&
                        (job.errorMessage?.isNotEmpty ?? false))
                      MlNoticeLine(
                        icon: AppIcons.error,
                        color: AppColors.error,
                        text: job.errorMessage!,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              if (job.isCancellable)
                MlIconButton(
                  icon: AppIcons.stop,
                  tooltip: l10n.mlActionCancelJob,
                  color: AppColors.error,
                  onPressed: () => mlCancelJob(context, ref, job),
                )
              else
                ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s),
                    child: Icon(AppIcons.chevron, color: secondary, size: 20),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
