import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/ml_model.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/ml_model_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_panel.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/skeletons.dart';
import 'admin_shell.dart';

const double _contentMaxWidth = 820;

/// Jeux de données acceptés par l'endpoint `/api/models/retrain`.
const _datasets = ['WASL', 'LSFB', 'WASL+LSFB'];

class AdminModelsScreen extends ConsumerStatefulWidget {
  const AdminModelsScreen({super.key});

  @override
  ConsumerState<AdminModelsScreen> createState() => _AdminModelsScreenState();
}

class _AdminModelsScreenState extends ConsumerState<AdminModelsScreen> {
  String _retrainDataset = 'WASL+LSFB';
  bool _busy = false;

  void _refresh() {
    ref
      ..invalidate(mlModelsProvider)
      ..invalidate(trainingJobsProvider)
      ..invalidate(mlModelMetricsProvider);
  }

  Future<void> _setActive(MlModel model) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      await ref.read(mlModelRepositoryProvider).setActiveModel(model.id);
      ref
        ..invalidate(mlModelsProvider)
        ..invalidate(activeMlModelProvider);
      if (mounted) AppSnackbar.showSuccess(context, l10n.adminModelActivated);
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, '${l10n.adminRlsOrNetworkError}: $e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestRetrain({String? baseModelId}) async {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(mlModelRepositoryProvider)
          .requestRetrain(
            dataset: _retrainDataset,
            baseModelId: baseModelId,
            requestedBy: user.id,
          );
      ref.invalidate(trainingJobsProvider);
      if (mounted) AppSnackbar.showSuccess(context, l10n.adminRetrainQueued);
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, '${l10n.adminRlsOrNetworkError}: $e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final modelsAsync = ref.watch(mlModelsProvider);
    final jobsAsync = ref.watch(trainingJobsProvider);

    return AdminShell(
      selectedIndex: 5,
      child: RefreshIndicator(
        onRefresh: () async {
          _refresh();
          await ref.read(mlModelsProvider.future);
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
            _Constrained(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            l10n.adminModels,
                            style: AppTextStyles.h2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s),
                        Text(
                          l10n.adminModelsSubtitle,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  IconButton(
                    tooltip: l10n.admxRefresh,
                    constraints: const BoxConstraints(
                      minWidth: kMinTouchTarget,
                      minHeight: kMinTouchTarget,
                    ),
                    onPressed: _refresh,
                    icon: const Icon(AppIcons.refresh),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _Constrained(
              child: AppPanel(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(l10n.adminRequestRetrain, small: true),
                        const SizedBox(height: AppSpacing.s),
                        Text(
                          l10n.adminRetrainHint,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.m),
                        DropdownButtonFormField<String>(
                          key: ValueKey(_retrainDataset),
                          initialValue: _retrainDataset,
                          decoration: InputDecoration(
                            labelText: l10n.adminDataset,
                          ),
                          items: [
                            for (final d in _datasets)
                              DropdownMenuItem(
                                value: d,
                                child: Text(d.replaceAll('+', ' + ')),
                              ),
                          ],
                          onChanged: _busy
                              ? null
                              : (v) => setState(
                                  () => _retrainDataset = v ?? _retrainDataset,
                                ),
                        ),
                        const SizedBox(height: AppSpacing.m),
                        AppButton(
                          label: l10n.adminStartRetrain,
                          icon: PhosphorIconsRegular.flask,
                          fullWidth: false,
                          isLoading: _busy,
                          onPressed: () => _requestRetrain(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _Constrained(child: _SectionTitle(l10n.adminModelsList)),
            const SizedBox(height: AppSpacing.m),
            _Constrained(
              child: modelsAsync.when(
                loading: () => _ModelsSkeleton(label: l10n.loading),
                error: (e, _) => AppPanel(
                  child: AppEmptyState(
                    icon: PhosphorIconsRegular.cloudSlash,
                    title: l10n.errorGeneric,
                    message: '${l10n.adminRlsOrNetworkError}\n$e',
                    actionLabel: l10n.retry,
                    onAction: () => ref.invalidate(mlModelsProvider),
                  ),
                ),
                data: (models) {
                  if (models.isEmpty) {
                    return AppPanel(
                      child: AppEmptyState(
                        icon: AppIcons.model,
                        title: l10n.adminNoModels,
                        message: l10n.admxNoModelsMessage,
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < models.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.m),
                        _ModelCard(
                          model: models[i],
                          busy: _busy,
                          onActivate: () => _setActive(models[i]),
                          onRetrain: () =>
                              _requestRetrain(baseModelId: models[i].id),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _Constrained(child: _SectionTitle(l10n.adminTrainingJobs)),
            const SizedBox(height: AppSpacing.m),
            _Constrained(
              child: jobsAsync.when(
                loading: () => _JobsSkeleton(label: l10n.loading),
                error: (e, _) => AppPanel(
                  child: Row(
                    children: [
                      const Icon(AppIcons.error, color: AppColors.error),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: Text(
                          '${l10n.adminRlsOrNetworkError}: $e',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                data: (jobs) {
                  if (jobs.isEmpty) {
                    return AppPanel(
                      child: AppEmptyState(
                        icon: AppIcons.history,
                        title: l10n.adminNoJobs,
                        message: l10n.admxNoJobsMessage,
                      ),
                    );
                  }
                  return AppPanel(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < jobs.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              color: AppColors.border(context),
                            ),
                          _JobRow(job: jobs[i]),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final d = date.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}

class _Constrained extends StatelessWidget {
  const _Constrained({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
        child: child,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.small = false});

  final String text;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        text,
        style: small
            ? AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)
            : AppTextStyles.h3,
      ),
    );
  }
}

class _ModelCard extends ConsumerWidget {
  const _ModelCard({
    required this.model,
    required this.busy,
    required this.onActivate,
    required this.onRetrain,
  });

  final MlModel model;
  final bool busy;
  final VoidCallback onActivate;
  final VoidCallback onRetrain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final metricsAsync = ref.watch(mlModelMetricsProvider(model.id));
    final secondary = AppColors.textSecondary(context);

    return AppPanel(
      borderColor: model.isActive ? AppColors.primary : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: AppRadius.radiusM,
                ),
                child: const Icon(
                  AppIcons.model,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model.name,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${l10n.version} ${model.version} · ${model.dataset}',
                      style: AppTextStyles.bodySmall.copyWith(color: secondary),
                    ),
                    if (model.createdAt != null)
                      Text(
                        l10n.admxCreatedOn(_formatDate(model.createdAt!)),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: secondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (model.isActive)
                AppBadge(
                  label: l10n.adminModelActive,
                  color: AppColors.success,
                ),
            ],
          ),
          if (model.description?.isNotEmpty ?? false) ...[
            const SizedBox(height: AppSpacing.m),
            Text(model.description!, style: AppTextStyles.bodyMedium),
          ],
          const SizedBox(height: AppSpacing.m),
          metricsAsync.when(
            loading: () => const Skeleton(
              child: Wrap(
                spacing: AppSpacing.s,
                runSpacing: AppSpacing.s,
                children: [
                  SkeletonBlock(width: 120, height: 30, radius: AppRadius.s),
                  SkeletonBlock(width: 110, height: 30, radius: AppRadius.s),
                  SkeletonBlock(width: 120, height: 30, radius: AppRadius.s),
                ],
              ),
            ),
            error: (_, _) => Text(
              l10n.adminNoMetrics,
              style: AppTextStyles.bodySmall.copyWith(color: secondary),
            ),
            data: (m) {
              if (m == null) {
                return Text(
                  l10n.adminNoMetrics,
                  style: AppTextStyles.bodySmall.copyWith(color: secondary),
                );
              }
              return Wrap(
                spacing: AppSpacing.s,
                runSpacing: AppSpacing.s,
                children: [
                  if (m.accuracy != null)
                    _MetricChip(
                      label: l10n.adminAccuracy,
                      value: '${(m.accuracy! * 100).toStringAsFixed(1)} %',
                    ),
                  if (m.latencyMs != null)
                    _MetricChip(
                      label: l10n.adminLatency,
                      value: '${m.latencyMs!.toStringAsFixed(0)} ms',
                    ),
                  _MetricChip(
                    label: l10n.adminInferences,
                    value: '${m.inferenceCount}',
                  ),
                  if (m.dataset != null)
                    _MetricChip(label: l10n.adminDataset, value: m.dataset!),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.m),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: [
              if (!model.isActive)
                FilledButton.icon(
                  onPressed: busy ? null : onActivate,
                  icon: const Icon(AppIcons.success, size: 18),
                  label: Text(l10n.adminSetActiveModel),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, kMinTouchTarget),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: busy ? null : onRetrain,
                icon: const Icon(AppIcons.refresh, size: 18),
                label: Text(l10n.adminRetrainFromModel),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, kMinTouchTarget),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.neutral(context),
        borderRadius: AppRadius.radiusS,
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label  ',
              style: TextStyle(color: AppColors.textSecondary(context)),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        style: AppTextStyles.bodySmall,
      ),
    );
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({required this.job});

  final TrainingJob job;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final secondary = AppColors.textSecondary(context);
    final (IconData icon, Color color, String label) = switch (job.status) {
      'running' => (
        PhosphorIconsRegular.hourglassMedium,
        AppColors.info,
        l10n.admxJobRunning,
      ),
      'done' => (AppIcons.success, AppColors.success, l10n.admxJobDone),
      'failed' => (AppIcons.error, AppColors.error, l10n.admxJobFailed),
      _ => (PhosphorIconsRegular.queue, AppColors.warning, l10n.admxJobQueued),
    };
    final progress = (job.progress.clamp(0, 100)) / 100;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.m,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
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
                      job.dataset.replaceAll('+', ' + '),
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    AppBadge(label: label, color: color),
                  ],
                ),
                if (job.createdAt != null)
                  Text(
                    l10n.admxCreatedOn(_formatDate(job.createdAt!)),
                    style: AppTextStyles.bodySmall.copyWith(color: secondary),
                  ),
                if (job.status == 'running') ...[
                  const SizedBox(height: AppSpacing.s),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    borderRadius: AppRadius.radiusCircular,
                    backgroundColor: AppColors.neutral(context),
                  ),
                ],
                if (job.status == 'failed' &&
                    (job.errorMessage?.isNotEmpty ?? false)) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    job.errorMessage!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Text(
            '${job.progress.clamp(0, 100).toStringAsFixed(0)} %',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Reprend la forme de [_ModelCard] : en-tête avec icône, métriques, actions.
class _ModelsSkeleton extends StatelessWidget {
  const _ModelsSkeleton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      label: label,
      child: Column(
        children: [
          for (var i = 0; i < 2; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.m),
            Container(
              padding: const EdgeInsets.all(AppSpacing.l),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white),
                borderRadius: AppRadius.radiusL,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SkeletonBlock(width: 44, height: 44, radius: AppRadius.m),
                      SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonBlock(width: 160, height: 16),
                            SizedBox(height: AppSpacing.s),
                            SkeletonBlock(width: 200, height: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.m),
                  Wrap(
                    spacing: AppSpacing.s,
                    runSpacing: AppSpacing.s,
                    children: [
                      SkeletonBlock(
                        width: 120,
                        height: 30,
                        radius: AppRadius.s,
                      ),
                      SkeletonBlock(
                        width: 110,
                        height: 30,
                        radius: AppRadius.s,
                      ),
                      SkeletonBlock(
                        width: 120,
                        height: 30,
                        radius: AppRadius.s,
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.m),
                  Wrap(
                    spacing: AppSpacing.s,
                    runSpacing: AppSpacing.s,
                    children: [
                      SkeletonBlock(
                        width: 170,
                        height: 48,
                        radius: AppRadius.circular,
                      ),
                      SkeletonBlock(
                        width: 220,
                        height: 48,
                        radius: AppRadius.circular,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _JobsSkeleton extends StatelessWidget {
  const _JobsSkeleton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          borderRadius: AppRadius.radiusL,
        ),
        child: Column(
          children: [
            for (var i = 0; i < 3; i++)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.m),
                child: Row(
                  children: [
                    SkeletonBlock.circle(size: 24),
                    SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBlock(width: 150, height: 16),
                          SizedBox(height: AppSpacing.s),
                          SkeletonBlock(width: 120, height: 12),
                        ],
                      ),
                    ),
                    SkeletonBlock(width: 40, height: 14),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
