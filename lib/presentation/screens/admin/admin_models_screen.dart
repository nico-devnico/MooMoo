import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moomoo/core/layout/responsive.dart';
import 'package:moomoo/core/theme/app_colors.dart';
import 'package:moomoo/core/theme/app_spacing.dart';
import 'package:moomoo/core/theme/app_text_styles.dart';
import 'package:moomoo/data/models/ml_model.dart';
import 'package:moomoo/domain/providers/auth_provider.dart';
import 'package:moomoo/domain/providers/ml_model_provider.dart';
import 'package:moomoo/l10n/app_localizations.dart';
import 'package:moomoo/presentation/widgets/app_card.dart';
import 'package:moomoo/presentation/widgets/app_empty_state.dart';
import 'package:moomoo/presentation/widgets/app_loader.dart';
import 'package:moomoo/presentation/widgets/app_snackbar.dart';
import 'admin_shell.dart';

class AdminModelsScreen extends ConsumerStatefulWidget {
  const AdminModelsScreen({super.key});

  @override
  ConsumerState<AdminModelsScreen> createState() => _AdminModelsScreenState();
}

class _AdminModelsScreenState extends ConsumerState<AdminModelsScreen> {
  String _retrainDataset = 'WASL+LSFB';
  bool _busy = false;

  Future<void> _setActive(MlModel model) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      await ref.read(mlModelRepositoryProvider).setActiveModel(model.id);
      ref.invalidate(mlModelsProvider);
      ref.invalidate(activeMlModelProvider);
      if (mounted) {
        AppSnackbar.showSuccess(context, l10n.adminModelActivated);
      }
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
      await ref.read(mlModelRepositoryProvider).requestRetrain(
            dataset: _retrainDataset,
            baseModelId: baseModelId,
            requestedBy: user.id,
          );
      ref.invalidate(trainingJobsProvider);
      if (mounted) {
        AppSnackbar.showSuccess(context, l10n.adminRetrainQueued);
      }
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
      selectedIndex: 4,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(mlModelsProvider);
          ref.invalidate(trainingJobsProvider);
          await ref.read(mlModelsProvider.future);
        },
        child: PageContainer(
          width: ContentWidth.detail,
          verticalPadding: AppSpacing.l,
          child: ListView(
          children: [
            Text(l10n.adminModels, style: AppTextStyles.h2),
            const SizedBox(height: AppSpacing.s),
            Text(l10n.adminModelsSubtitle, style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSpacing.l),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.adminRequestRetrain,
                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(l10n.adminRetrainHint, style: AppTextStyles.bodySmall),
                  const SizedBox(height: AppSpacing.m),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_retrainDataset),
                    initialValue: _retrainDataset,
                    decoration: InputDecoration(labelText: l10n.adminDataset),
                    items: const [
                      DropdownMenuItem(value: 'WASL', child: Text('WASL')),
                      DropdownMenuItem(value: 'LSFB', child: Text('LSFB')),
                      DropdownMenuItem(value: 'WASL+LSFB', child: Text('WASL + LSFB')),
                    ],
                    onChanged: _busy
                        ? null
                        : (v) => setState(() => _retrainDataset = v ?? 'WASL+LSFB'),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _requestRetrain(),
                    icon: const Icon(Icons.science_outlined),
                    label: Text(l10n.adminStartRetrain),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(l10n.adminModelsList, style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.m),
            modelsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(child: AppLoader()),
              ),
              error: (e, _) => AppEmptyState(
                title: l10n.errorGeneric,
                message: '${l10n.adminRlsOrNetworkError}\n$e',
                icon: Icons.cloud_off_outlined,
                actionLabel: l10n.retry,
                onAction: () => ref.invalidate(mlModelsProvider),
              ),
              data: (models) {
                if (models.isEmpty) {
                  return AppEmptyState(
                    title: l10n.adminNoModels,
                    message: l10n.adminNoModelsMessage,
                    icon: Icons.memory_outlined,
                  );
                }
                return Column(
                  children: [
                    for (final model in models)
                      _ModelTile(
                        model: model,
                        busy: _busy,
                        onActivate: () => _setActive(model),
                        onRetrain: () => _requestRetrain(baseModelId: model.id),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(l10n.adminTrainingJobs, style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.m),
            jobsAsync.when(
              loading: () => const Center(child: AppLoader()),
              error: (e, _) => Text(
                '${l10n.adminRlsOrNetworkError}: $e',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
              ),
              data: (jobs) {
                if (jobs.isEmpty) {
                  return Text(l10n.adminNoJobs, style: AppTextStyles.bodyMedium);
                }
                return Column(
                  children: [
                    for (final job in jobs)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.s),
                        child: AppCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              _jobIcon(job.status),
                              color: _jobColor(job.status),
                            ),
                            title: Text(
                              '${job.dataset} · ${job.status}',
                              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              job.createdAt?.toLocal().toString() ?? job.id,
                              style: AppTextStyles.bodySmall,
                            ),
                            trailing: Text('${job.progress.toStringAsFixed(0)}%'),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
          ),
        ),
      ),
    );
  }

  IconData _jobIcon(String status) {
    switch (status) {
      case 'running':
        return Icons.hourglass_top;
      case 'done':
        return Icons.check_circle_outline;
      case 'failed':
        return Icons.error_outline;
      default:
        return Icons.queue;
    }
  }

  Color _jobColor(String status) {
    switch (status) {
      case 'running':
        return AppColors.info;
      case 'done':
        return AppColors.success;
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }
}

class _ModelTile extends ConsumerWidget {
  final MlModel model;
  final bool busy;
  final VoidCallback onActivate;
  final VoidCallback onRetrain;

  const _ModelTile({
    required this.model,
    required this.busy,
    required this.onActivate,
    required this.onRetrain,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final metricsAsync = ref.watch(mlModelMetricsProvider(model.id));

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  model.displayLabel,
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (model.isActive)
                Chip(
                  label: Text(l10n.adminModelActive),
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
                  labelStyle: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          if (model.description != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(model.description!, style: AppTextStyles.bodySmall),
          ],
          const SizedBox(height: AppSpacing.m),
          metricsAsync.when(
            loading: () => const AppLoader(width: 80, height: 12),
            error: (_, _) => Text(l10n.adminNoMetrics, style: AppTextStyles.bodySmall),
            data: (m) {
              if (m == null) {
                return Text(l10n.adminNoMetrics, style: AppTextStyles.bodySmall);
              }
              final acc = m.accuracy != null
                  ? '${(m.accuracy! * 100).toStringAsFixed(1)}%'
                  : '—';
              final lat = m.latencyMs != null
                  ? '${m.latencyMs!.toStringAsFixed(0)} ms'
                  : '—';
              return Wrap(
                spacing: AppSpacing.m,
                runSpacing: AppSpacing.s,
                children: [
                  _MetricChip(label: l10n.adminAccuracy, value: acc),
                  _MetricChip(label: l10n.adminLatency, value: lat),
                  _MetricChip(
                    label: l10n.adminInferences,
                    value: m.inferenceCount.toString(),
                  ),
                  _MetricChip(
                    label: l10n.adminDataset,
                    value: m.dataset ?? model.dataset,
                  ),
                  _MetricChip(label: l10n.version, value: model.version),
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
                FilledButton(
                  onPressed: busy ? null : onActivate,
                  child: Text(l10n.adminSetActiveModel),
                ),
              OutlinedButton(
                onPressed: busy ? null : onRetrain,
                child: Text(l10n.adminRetrainFromModel),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
