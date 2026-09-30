import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/providers/fingerspell_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/app_snackbar.dart';
import 'ml_charts.dart';
import 'ml_common.dart';

/// Onglet admin : modèles d'épellation ASL, activation, dataset et perfs.
class MlFingerspellTab extends ConsumerStatefulWidget {
  const MlFingerspellTab({super.key});

  @override
  ConsumerState<MlFingerspellTab> createState() => _MlFingerspellTabState();
}

class _MlFingerspellTabState extends ConsumerState<MlFingerspellTab> {
  Timer? _poll;
  bool _starting = false;

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  void _ensurePolling(bool running) {
    if (running && _poll == null) {
      _poll = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        ref.invalidate(fingerspellTrainStatusProvider);
      });
    } else if (!running && _poll != null) {
      _poll?.cancel();
      _poll = null;
      ref.invalidate(fingerspellModelsProvider);
    }
  }

  Future<void> _startTrain() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _starting = true);
    try {
      await startFingerspellTraining(ref);
      if (!mounted) return;
      AppSnackbar.show(
        context,
        message: l10n.mlFingerspellTrainRunning,
        type: AppSnackbarType.success,
      );
      ref.invalidate(fingerspellTrainStatusProvider);
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(fingerspellModelsProvider);
    final trainAsync = ref.watch(fingerspellTrainStatusProvider);

    trainAsync.whenData((s) => _ensurePolling(s.isRunning));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppEmptyState(
        icon: AppIcons.error,
        title: l10n.errorGeneric,
        message: e.toString(),
        actionLabel: l10n.retry,
        onAction: () => ref.invalidate(fingerspellModelsProvider),
      ),
      data: (models) {
        if (models.isEmpty) {
          return AppEmptyState(
            icon: PhosphorIconsRegular.hand,
            title: l10n.mlFingerspellEmptyTitle,
            message: l10n.mlFingerspellEmptyMessage,
          );
        }
        final active = models.where((m) => m.active).firstOrNull ?? models.first;
        final train = trainAsync.value;
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.l),
          children: [
            MlConstrained(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.mlFingerspellTitle, style: AppTextStyles.h3),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    l10n.mlFingerspellSubtitle,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),
                  _TrainPanel(
                    status: train,
                    starting: _starting,
                    onStart: (train?.isRunning ?? false) || _starting ? null : _startTrain,
                    onRefresh: () {
                      ref.invalidate(fingerspellTrainStatusProvider);
                      ref.invalidate(fingerspellModelsProvider);
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  for (final model in models) ...[
                    _ModelCard(
                      model: model,
                      selected: model.id == active.id,
                      onActivate: model.active
                          ? null
                          : () async {
                              try {
                                await activateFingerspellModel(ref, model.id);
                                if (context.mounted) {
                                  AppSnackbar.show(
                                    context,
                                    message: l10n.mlFingerspellActivated(model.name),
                                    type: AppSnackbarType.success,
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  AppSnackbar.showError(context, e.toString());
                                }
                              }
                            },
                      onSelect: () {},
                    ),
                    const SizedBox(height: AppSpacing.m),
                  ],
                  const SizedBox(height: AppSpacing.l),
                  Text(l10n.mlFingerspellDetailsTitle, style: AppTextStyles.h3),
                  const SizedBox(height: AppSpacing.m),
                  _ModelDetails(model: active),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    l10n.mlFingerspellAccuracyNote,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(l10n.mlFingerspellPerfTitle, style: AppTextStyles.h3),
                  const SizedBox(height: AppSpacing.m),
                  _PerfCharts(model: active),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TrainPanel extends StatelessWidget {
  const _TrainPanel({
    required this.status,
    required this.starting,
    required this.onStart,
    required this.onRefresh,
  });

  final FingerspellTrainStatus? status;
  final bool starting;
  final VoidCallback? onStart;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = status;
    final running = s?.isRunning == true || starting;
    final label = switch (s?.status) {
      'running' => l10n.mlFingerspellTrainRunning,
      'succeeded' => l10n.mlFingerspellTrainSucceeded(s?.versionId ?? '—'),
      'failed' => l10n.mlFingerspellTrainFailed,
      _ => l10n.mlFingerspellTrainIdle,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: AppRadius.radiusL,
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.mlFingerspellTrainTitle, style: AppTextStyles.h3),
          const SizedBox(height: AppSpacing.s),
          Text(
            l10n.mlFingerspellTrainSubtitle,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          if (running) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: AppSpacing.m),
          ],
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          if (s?.message != null && s!.message!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              s.message!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
          ],
          if (s?.error != null) ...[
            const SizedBox(height: AppSpacing.s),
            Text(
              s!.error!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: AppSpacing.m),
          Wrap(
            spacing: AppSpacing.m,
            runSpacing: AppSpacing.m,
            children: [
              AppButton(
                label: l10n.mlFingerspellTrainStart,
                icon: AppIcons.refresh,
                fullWidth: false,
                onPressed: onStart,
              ),
              AppButton(
                label: l10n.mlFingerspellTrainRefresh,
                icon: AppIcons.refresh,
                variant: AppButtonVariant.outline,
                fullWidth: false,
                onPressed: onRefresh,
              ),
            ],
          ),
          if (s != null && s.logTail.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.l),
            Text(l10n.mlFingerspellTrainLog, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.s),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: AppColors.neutral(context),
                borderRadius: AppRadius.radiusM,
              ),
              child: SingleChildScrollView(
                reverse: true,
                child: SelectableText(
                  s.logTail.join('\n'),
                  style: AppTextStyles.bodySmall.copyWith(fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ModelCard extends StatelessWidget {
  const _ModelCard({
    required this.model,
    required this.selected,
    required this.onActivate,
    required this.onSelect,
  });

  final FingerspellModel model;
  final bool selected;
  final VoidCallback? onActivate;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final secondary = AppColors.textSecondary(context);
    return Material(
      color: AppColors.surface(context),
      borderRadius: AppRadius.radiusL,
      child: InkWell(
        onTap: onSelect,
        borderRadius: AppRadius.radiusL,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.l),
          decoration: BoxDecoration(
            borderRadius: AppRadius.radiusL,
            border: Border.all(
              color: model.active || selected
                  ? AppColors.primary
                  : AppColors.border(context),
              width: model.active || selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      model.name,
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (model.active)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.m,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: AppRadius.radiusCircular,
                      ),
                      child: Text(
                        l10n.mlFingerspellActive,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${model.id} · v${model.version}'
                '${model.dataset != null ? ' · ${model.dataset}' : ''}',
                style: AppTextStyles.bodySmall.copyWith(color: secondary),
              ),
              if (model.accuracy != null) ...[
                const SizedBox(height: AppSpacing.s),
                Text(
                  l10n.mlFingerspellAccuracy((model.accuracy! * 100).toStringAsFixed(1)),
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
              if (onActivate != null) ...[
                const SizedBox(height: AppSpacing.m),
                AppButton(
                  label: l10n.mlFingerspellActivate,
                  icon: AppIcons.checkBold,
                  onPressed: onActivate,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ModelDetails extends StatelessWidget {
  const _ModelDetails({required this.model});

  final FingerspellModel model;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final shape = model.inputShape.isEmpty
        ? '—'
        : model.inputShape.join(' × ');
    final rows = <(String, String)>[
      (l10n.mlFingerspellFieldId, model.id),
      (l10n.mlFingerspellFieldVersion, model.version),
      (l10n.mlFingerspellFieldDataset, model.dataset ?? 'asl_alphabet'),
      if (model.datasetDir != null)
        (l10n.mlFingerspellFieldDatasetDir, model.datasetDir!),
      (l10n.mlFingerspellFieldArchitecture, model.architecture ?? 'CNN-BiLSTM'),
      (l10n.mlFingerspellFieldInput, shape),
      if (model.numClasses != null)
        (l10n.mlFingerspellFieldClasses, '${model.numClasses}'),
      if (model.epochsRan != null)
        (l10n.mlFingerspellFieldEpochs, '${model.epochsRan}'),
      if (model.maxPerClass != null)
        (l10n.mlFingerspellFieldMaxPerClass, '${model.maxPerClass}'),
      if (model.runtime != null)
        (l10n.mlFingerspellFieldRuntime, model.runtime!),
      if (model.tfliteSizeKb != null)
        (
          l10n.mlFingerspellFieldSize,
          '${model.tfliteSizeKb!.toStringAsFixed(0)} Ko',
        ),
      if (model.valAccuracy != null)
        (
          l10n.mlFingerspellFieldValAcc,
          '${(model.valAccuracy! * 100).toStringAsFixed(2)} %'
          '${model.valSamples != null ? ' (${model.valSamples})' : ''}',
        ),
      if (model.accuracy != null)
        (
          l10n.mlFingerspellTestAccuracy,
          '${(model.accuracy! * 100).toStringAsFixed(2)} %'
          '${model.testSamples != null ? ' (${model.testSamples})' : ''}',
        ),
      if (model.top3Accuracy != null)
        (
          l10n.mlFingerspellTop3,
          '${(model.top3Accuracy! * 100).toStringAsFixed(2)} %',
        ),
      (
        l10n.mlFingerspellFieldTflite,
        model.hasTflite ? l10n.mlYes : l10n.mlNo,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: AppRadius.radiusL,
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: AppSpacing.l),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    rows[i].$1,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    rows[i].$2,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PerfCharts extends StatelessWidget {
  const _PerfCharts({required this.model});

  final FingerspellModel model;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final history = model.history;
    final train = [
      for (final h in history)
        if (h.epoch > 0) FlSpot(h.epoch, h.accuracy),
    ];
    final val = [
      for (final h in history)
        if (h.epoch > 0 && h.valAccuracy > 0) FlSpot(h.epoch, h.valAccuracy),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.mlFingerspellChartAccuracy,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.s),
        if (train.isEmpty)
          Text(
            l10n.mlFingerspellNoHistory,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary(context),
            ),
          )
        else
          MlLineChart(
            semanticLabel: l10n.mlFingerspellChartAccuracy,
            minY: 0,
            maxY: 1.05,
            formatY: (v) => '${(v * 100).round()} %',
            series: [
              MlChartSeries(
                label: l10n.mlChartTrain,
                color: AppColors.primary,
                spots: train,
              ),
              MlChartSeries(
                label: l10n.mlChartVal,
                color: AppColors.warning,
                spots: val,
                dashed: true,
              ),
            ],
          ),
      ],
    );
  }
}
