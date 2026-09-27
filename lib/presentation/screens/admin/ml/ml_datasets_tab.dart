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
import '../../../widgets/app_button.dart';
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/app_panel.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/confirm_dialog.dart';
import 'ml_common.dart';
import 'ml_dataset_dialogs.dart';
import 'ml_skeletons.dart';
import 'ml_training_dialog.dart';

const _maxClassBars = 30;

class MlDatasetsTab extends ConsumerWidget {
  const MlDatasetsTab({super.key, required this.onJobQueued});

  /// Called once a job has been queued, to bring the jobs tab forward.
  final VoidCallback onJobQueued;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final datasetsAsync = ref.watch(mlDatasetsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(mlDatasetsProvider);
        await ref.read(mlDatasetsProvider.future);
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
              title: l10n.mlTabDatasets,
              subtitle: l10n.mlDatasetsSubtitle,
              actions: [
                AppButton(
                  label: l10n.mlDatasetAdd,
                  icon: AppIcons.add,
                  fullWidth: false,
                  onPressed: () => showMlAddDatasetDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          MlConstrained(
            child: datasetsAsync.when(
              loading: () => MlCardListSkeleton(label: l10n.loading),
              error: (e, _) => MlErrorPanel(
                error: e,
                onRetry: () => ref.invalidate(mlDatasetsProvider),
              ),
              data: (datasets) {
                if (datasets.isEmpty) {
                  return AppPanel(
                    child: AppEmptyState(
                      icon: AppIcons.database,
                      title: l10n.mlDatasetsEmpty,
                      message: l10n.mlDatasetsEmptyMessage,
                      actionLabel: l10n.mlDatasetAdd,
                      onAction: () => showMlAddDatasetDialog(context),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < datasets.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.m),
                      MlDatasetCard(
                        dataset: datasets[i],
                        allDatasets: datasets,
                        onJobQueued: onJobQueued,
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MlDatasetCard extends ConsumerStatefulWidget {
  const MlDatasetCard({
    super.key,
    required this.dataset,
    required this.allDatasets,
    required this.onJobQueued,
  });

  final MlDataset dataset;
  final List<MlDataset> allDatasets;
  final VoidCallback onJobQueued;

  @override
  ConsumerState<MlDatasetCard> createState() => _MlDatasetCardState();
}

class _MlDatasetCardState extends ConsumerState<MlDatasetCard> {
  bool _showClasses = false;
  bool _busy = false;

  MlDataset get _ds => widget.dataset;

  Future<bool> _run(Future<void> Function() action, String success) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      await action();
      refreshMlTraining(ref);
      if (mounted) AppSnackbar.showSuccess(context, success);
      return true;
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, mlErrorText(l10n, e));
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reanalyze() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await _run(
      () => ref
          .read(mlTrainingRepositoryProvider)
          .enqueue(kind: 'analyze', dataset: _ds),
      l10n.mlJobQueuedMessage,
    );
    if (ok) widget.onJobQueued();
  }

  Future<void> _preprocess() async {
    if (await showMlPreprocessDialog(context, _ds)) widget.onJobQueued();
  }

  Future<void> _train() async {
    final queued = await showMlTrainingDialog(
      context,
      dataset: _ds,
      datasets: widget.allDatasets,
    );
    if (queued) widget.onJobQueued();
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showConfirmDialog(
      context,
      title: l10n.mlDatasetDeleteTitle,
      message: l10n.mlDatasetDeleteMessage(_ds.name),
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await _run(
      () => ref.read(mlTrainingRepositoryProvider).deleteDataset(_ds.id),
      l10n.mlDatasetDeleted,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final secondary = AppColors.textSecondary(context);
    final status = mlDatasetStatus(l10n, _ds.status);
    final hasAnalysis = _ds.analysis.isNotEmpty;
    final disabled = _busy || _ds.isBusy;

    return AppPanel(
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
                  AppIcons.database,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        _ds.name,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.s,
                      runSpacing: AppSpacing.xs,
                      children: [
                        AppBadge(
                          label: _ds.languageCode,
                          color: AppColors.primary,
                        ),
                        MlStatusBadge(info: status),
                        if (_ds.isTrainable)
                          MlStatusBadge(
                            info: (
                              label: l10n.mlDatasetTrainable,
                              color: AppColors.success,
                              icon: AppIcons.check,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s),
                    SelectableText(
                      '${_ds.sourceType == 'url' ? l10n.mlSourceUrl : l10n.mlSourceLocal} · ${_ds.uri}',
                      style: AppTextStyles.bodySmall.copyWith(color: secondary),
                    ),
                    Text(
                      [
                        mlMediaFormatLabel(l10n, _ds.mediaFormat),
                        _ds.isStructured
                            ? l10n.mlFieldStructured
                            : l10n.mlUnstructured,
                        if (_ds.labelMapping.isNotEmpty)
                          l10n.mlMappingCount(_ds.labelMapping.length),
                        if (_ds.createdAt != null)
                          l10n.admxCreatedOn(mlFormatDate(_ds.createdAt!)),
                      ].join(' · '),
                      style: AppTextStyles.bodySmall.copyWith(color: secondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_ds.isBusy) ...[
            const SizedBox(height: AppSpacing.m),
            LinearProgressIndicator(
              minHeight: 6,
              borderRadius: AppRadius.radiusCircular,
              backgroundColor: AppColors.neutral(context),
              semanticsLabel: status.label,
            ),
          ],
          const SizedBox(height: AppSpacing.m),
          if (!hasAnalysis)
            Text(
              l10n.mlAnalysisPending,
              style: AppTextStyles.bodySmall.copyWith(color: secondary),
            )
          else
            _AnalysisSummary(dataset: _ds),
          if (_ds.status == DatasetStatus.failed &&
              (_ds.errorMessage?.isNotEmpty ?? false)) ...[
            const SizedBox(height: AppSpacing.s),
            MlNoticeLine(
              icon: AppIcons.error,
              color: AppColors.error,
              text: _ds.errorMessage!,
            ),
          ],
          if (_ds.warnings.isNotEmpty || _ds.recommendations.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.m),
            for (final w in _ds.warnings)
              MlNoticeLine(
                icon: AppIcons.warning,
                color: AppColors.warningLedge,
                text: w,
              ),
            for (final r in _ds.recommendations)
              MlNoticeLine(
                icon: PhosphorIconsRegular.lightbulb,
                color: AppColors.info,
                text: r,
              ),
          ],
          if (_ds.classCounts.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s),
            TextButton.icon(
              style: TextButton.styleFrom(
                minimumSize: const Size(0, kMinTouchTarget),
              ),
              onPressed: () => setState(() => _showClasses = !_showClasses),
              icon: Icon(
                _showClasses
                    ? PhosphorIconsRegular.caretUp
                    : PhosphorIconsRegular.caretDown,
                size: 18,
              ),
              label: Text(
                _showClasses
                    ? l10n.mlHideClasses
                    : l10n.mlShowClasses(_ds.classCounts.length),
              ),
            ),
            if (_showClasses) _ClassDistribution(counts: _ds.classCounts),
          ],
          const SizedBox(height: AppSpacing.m),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _withTooltip(
                _ds.isTrainable ? null : l10n.mlTrainDisabledHint,
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, kMinTouchTarget),
                  ),
                  onPressed: disabled || !_ds.isTrainable ? null : _train,
                  icon: const Icon(PhosphorIconsRegular.brain, size: 18),
                  label: Text(l10n.mlActionTrain),
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, kMinTouchTarget),
                ),
                onPressed: disabled ? null : _preprocess,
                icon: const Icon(PhosphorIconsRegular.handWaving, size: 18),
                label: Text(l10n.mlActionPreprocess),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, kMinTouchTarget),
                ),
                onPressed: disabled ? null : _reanalyze,
                icon: const Icon(AppIcons.refresh, size: 18),
                label: Text(l10n.mlActionReanalyze),
              ),
              MlIconButton(
                icon: PhosphorIconsRegular.tag,
                tooltip: l10n.mlActionEditMapping,
                onPressed: disabled
                    ? null
                    : () => showMlLabelMappingDialog(context, _ds),
              ),
              MlIconButton(
                icon: AppIcons.delete,
                tooltip: l10n.mlActionDeleteDataset,
                color: AppColors.error,
                onPressed: _busy ? null : _delete,
              ),
              if (_busy)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _withTooltip(String? message, Widget child) =>
    message == null ? child : Tooltip(message: message, child: child);

class _AnalysisSummary extends StatelessWidget {
  const _AnalysisSummary({required this.dataset});

  final MlDataset dataset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ds = dataset;
    final imbalance = ds.imbalanceRatio;
    final media = ds.media;
    String? summary(String key, {String suffix = ''}) {
      final m = media[key];
      if (m is! Map) return null;
      final mean = (m['mean'] as num?)?.toDouble();
      final min = (m['min'] as num?)?.toDouble();
      final max = (m['max'] as num?)?.toDouble();
      if (mean == null) return null;
      return l10n.mlMediaSummary(
        mean.toStringAsFixed(1),
        (min ?? mean).toStringAsFixed(1),
        (max ?? mean).toStringAsFixed(1),
        suffix,
      );
    }

    final fps = summary('fps');
    final duration = summary('duration_s', suffix: ' s');
    final resolutions = media['resolutions'] is Map
        ? (media['resolutions'] as Map).keys.map((e) => e.toString()).toList()
        : const <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            MlMetricChip(label: l10n.mlStatFiles, value: '${ds.filesTotal}'),
            MlMetricChip(label: l10n.mlStatClasses, value: '${ds.classesCount}'),
            MlMetricChip(
              label: l10n.mlStatLabeled,
              value: '${ds.labeledSamples}',
            ),
            if (ds.unlabeledSamples > 0)
              MlMetricChip(
                label: l10n.mlStatUnlabeled,
                value: '${ds.unlabeledSamples}',
                color: AppColors.warningLedge,
              ),
            MlMetricChip(label: l10n.mlStatSigners, value: '${ds.signersCount}'),
            MlMetricChip(
              label: l10n.mlStatInvalid,
              value: '${ds.invalidCount}',
              color: ds.invalidCount > 0 ? AppColors.error : null,
            ),
            MlMetricChip(
              label: l10n.mlStatDuplicates,
              value: '${ds.duplicateGroups}',
              color: ds.duplicateGroups > 0 ? AppColors.warningLedge : null,
            ),
            if (imbalance != null)
              MlMetricChip(
                label: l10n.mlStatImbalance,
                value: imbalance.toStringAsFixed(2),
                color: imbalance > 3 ? AppColors.warningLedge : null,
              ),
            if (ds.preprocessing.isNotEmpty) ...[
              MlMetricChip(
                label: l10n.mlStatPrepared,
                value: '${ds.preparedSamples}',
                color: AppColors.success,
              ),
              MlMetricChip(
                label: l10n.mlStatRejected,
                value: '${ds.rejectedSamples}',
                color: ds.rejectedSamples > 0 ? AppColors.warningLedge : null,
              ),
            ],
          ],
        ),
        if (fps != null || duration != null || resolutions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: [
              if (fps != null) MlMetricChip(label: l10n.mlStatFps, value: fps),
              if (duration != null)
                MlMetricChip(label: l10n.mlStatDuration, value: duration),
              if (resolutions.isNotEmpty)
                MlMetricChip(
                  label: l10n.mlStatResolutions,
                  value: resolutions.join(', '),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Horizontal bars of the most frequent classes, count written next to each.
class _ClassDistribution extends StatelessWidget {
  const _ClassDistribution({required this.counts});

  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(_maxClassBars).toList();
    final max = top.isEmpty ? 1 : top.first.value;
    final labelWidth = context.isMobile ? 110.0 : 180.0;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final e in top)
            Semantics(
              label: l10n.mlClassBarSemantics(e.key, e.value),
              excludeSemantics: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: labelWidth,
                      child: Text(
                        e.key,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, c) => Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: (c.maxWidth * e.value / max).clamp(2, c.maxWidth),
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: AppRadius.radiusCircular,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    SizedBox(
                      width: 48,
                      child: Text(
                        '${e.value}',
                        textAlign: TextAlign.right,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (entries.length > top.length)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                l10n.mlMoreClasses(entries.length - top.length),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary(context),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
