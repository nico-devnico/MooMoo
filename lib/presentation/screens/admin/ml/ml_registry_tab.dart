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
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/app_panel.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/confirm_dialog.dart';
import 'ml_common.dart';
import 'ml_skeletons.dart';
import 'ml_training_dialog.dart';

const _pipeline = ['trained', 'evaluated', 'validated', 'staging', 'production'];

int _stageOrder(String stage) => switch (stage) {
  'production' => 0,
  'staging' => 1,
  'validated' => 2,
  'evaluated' => 3,
  'trained' => 4,
  'training' => 5,
  _ => 6,
};

class MlRegistryTab extends ConsumerWidget {
  const MlRegistryTab({super.key, required this.onJobQueued});

  final VoidCallback onJobQueued;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(mlRegistryProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(mlRegistryProvider);
        await ref.read(mlRegistryProvider.future);
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
              title: l10n.mlTabRegistry,
              subtitle: l10n.mlRegistrySubtitle,
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          MlConstrained(
            child: async.when(
              loading: () => MlCardListSkeleton(label: l10n.loading),
              error: (e, _) => MlErrorPanel(
                error: e,
                onRetry: () => ref.invalidate(mlRegistryProvider),
              ),
              data: (models) {
                if (models.isEmpty) {
                  return AppPanel(
                    child: AppEmptyState(
                      icon: AppIcons.model,
                      title: l10n.mlRegistryEmpty,
                      message: l10n.mlRegistryEmptyMessage,
                    ),
                  );
                }
                final byLanguage = <String, List<RegistryModel>>{};
                for (final m in models) {
                  byLanguage.putIfAbsent(m.language, () => []).add(m);
                }
                final languages = byLanguage.keys.toList()..sort();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final lang in languages) ...[
                      _LanguageSection(
                        language: lang,
                        models: byLanguage[lang]!
                          ..sort((a, b) {
                            final byStage = _stageOrder(a.stage)
                                .compareTo(_stageOrder(b.stage));
                            if (byStage != 0) return byStage;
                            return (b.createdAt ?? DateTime(0))
                                .compareTo(a.createdAt ?? DateTime(0));
                          }),
                        onJobQueued: onJobQueued,
                      ),
                      const SizedBox(height: AppSpacing.xl),
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

class _LanguageSection extends StatelessWidget {
  const _LanguageSection({
    required this.language,
    required this.models,
    required this.onJobQueued,
  });

  final String language;
  final List<RegistryModel> models;
  final VoidCallback onJobQueued;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final production = models.where((m) => m.stage == 'production').firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const ExcludeSemantics(
              child: Icon(AppIcons.language, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.s),
            Expanded(child: MlSectionTitle(l10n.mlRegistryLanguage(language))),
            Text(
              l10n.mlRegistryCount(models.length),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
          ],
        ),
        if (production == null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.mlRegistryNoProduction,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.warningLedge,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.m),
        for (var i = 0; i < models.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.m),
          _RegistryCard(
            model: models[i],
            currentProduction: production,
            onJobQueued: onJobQueued,
          ),
        ],
      ],
    );
  }
}

class _RegistryCard extends ConsumerStatefulWidget {
  const _RegistryCard({
    required this.model,
    required this.currentProduction,
    required this.onJobQueued,
  });

  final RegistryModel model;
  final RegistryModel? currentProduction;
  final VoidCallback onJobQueued;

  @override
  ConsumerState<_RegistryCard> createState() => _RegistryCardState();
}

class _RegistryCardState extends ConsumerState<_RegistryCard> {
  bool _busy = false;

  RegistryModel get _m => widget.model;

  String _transitionLabel(AppLocalizations l10n, String stage) =>
      switch (stage) {
        'validated' => l10n.mlActionValidate,
        'staging' =>
          _m.stage == 'archived' ? l10n.mlActionRestoreStaging : l10n.mlActionStaging,
        'production' => l10n.mlActionPromote,
        'archived' => l10n.mlActionArchive,
        _ => mlStageLabel(l10n, stage),
      };

  IconData _transitionIcon(String stage) => switch (stage) {
    'validated' => AppIcons.success,
    'staging' => PhosphorIconsRegular.flask,
    'production' => PhosphorIconsRegular.rocketLaunch,
    'archived' => PhosphorIconsRegular.archive,
    _ => AppIcons.forward,
  };

  Future<void> _setStage(String stage) async {
    final l10n = AppLocalizations.of(context)!;
    if (stage == 'production' || stage == 'archived') {
      final current = widget.currentProduction;
      final ok = await showConfirmDialog(
        context,
        title: stage == 'production'
            ? l10n.mlPromoteTitle(_m.language)
            : l10n.mlArchiveTitle,
        message: stage == 'production'
            ? (current == null || current.id == _m.id
                ? l10n.mlPromoteMessageNoCurrent(_m.version, _m.language)
                : l10n.mlPromoteMessage(_m.version, current.version, _m.language))
            : l10n.mlArchiveMessage(_m.version),
        confirmLabel: _transitionLabel(l10n, stage),
        cancelLabel: l10n.cancel,
        destructive: stage == 'archived',
      );
      if (!ok || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(mlTrainingRepositoryProvider).setStage(_m.id, stage);
      ref.invalidate(mlRegistryProvider);
      if (mounted) {
        AppSnackbar.showSuccess(
          context,
          l10n.mlStageChanged(mlStageLabel(l10n, stage)),
        );
      }
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, mlErrorText(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _convert() async {
    final l10n = AppLocalizations.of(context)!;
    final quantization = await showMlQuantizationDialog(
      context,
      title: l10n.mlConvertTitle,
    );
    if (quantization == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(mlTrainingRepositoryProvider)
          .convertModel(_m, quantization: quantization);
      ref.invalidate(mlJobsProvider);
      if (mounted) AppSnackbar.showSuccess(context, l10n.mlJobQueuedMessage);
      widget.onJobQueued();
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, mlErrorText(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final secondary = AppColors.textSecondary(context);
    final isProduction = _m.stage == 'production';
    final bench = _m.tfliteBenchmark;
    double? n(Object? v) => (v as num?)?.toDouble();
    final latency = n(bench['latency_ms_mean']);
    final tfliteAcc = n(bench['accuracy']);
    final agreement = n(bench['agreement_with_keras']);
    final mobile = _m.mobileCompatible;
    final shape = _m.inputShape.isEmpty ? null : '[${_m.inputShape.join(', ')}]';

    return AppPanel(
      borderColor: isProduction ? AppColors.primary : null,
      color: isProduction ? AppColors.primary.withValues(alpha: 0.04) : null,
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
                child: const Icon(AppIcons.model, color: AppColors.primary, size: 22),
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
                        Semantics(
                          header: true,
                          child: Text(
                            '${_m.name} · ${l10n.version} ${_m.version}',
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isProduction)
                          AppBadge(
                            label: l10n.mlStageProduction,
                            color: AppColors.primary,
                          )
                        else
                          MlStatusBadge(info: mlStageStatus(l10n, _m.stage)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      [
                        _m.dataset,
                        l10n.mlClassesCount(_m.classes.length),
                        if (shape != null) l10n.mlInputShape(shape),
                        if (_m.architectureText.isNotEmpty) _m.architectureText,
                      ].join(' · '),
                      style: AppTextStyles.bodySmall.copyWith(color: secondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          _StagePipeline(stage: _m.stage),
          const SizedBox(height: AppSpacing.m),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: [
              MlMetricChip(label: l10n.mlMetricAccuracy, value: mlPercent(_m.accuracy)),
              MlMetricChip(label: l10n.mlColMacroF1, value: mlPercent(_m.macroF1)),
              MlMetricChip(
                label: l10n.mlMetricKerasSize,
                value: mlFormatBytes(l10n, _m.sizeBytes),
              ),
              MlMetricChip(
                label: l10n.mlMetricTfliteSize,
                value: mlFormatBytes(l10n, _m.tfliteSizeBytes),
              ),
              if (latency != null)
                MlMetricChip(
                  label: l10n.mlMetricTfliteLatency,
                  value: '${latency.toStringAsFixed(1)} ms',
                ),
              if (tfliteAcc != null)
                MlMetricChip(label: l10n.mlMetricTfliteAccuracy, value: mlPercent(tfliteAcc)),
              if (agreement != null)
                MlMetricChip(label: l10n.mlMetricAgreement, value: mlPercent(agreement)),
              if (mobile != null)
                MlMetricChip(
                  label: l10n.mlMetricMobile,
                  value: mobile ? l10n.mlYes : l10n.mlFlexRequired,
                  color: mobile ? AppColors.successLedge : AppColors.warningLedge,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            [
              if (_m.trainingDurationS != null)
                l10n.mlTrainingDuration(mlFormatSeconds(_m.trainingDurationS)),
              if (_m.createdAt != null)
                l10n.admxCreatedOn(mlFormatDate(_m.createdAt!)),
              if (_m.promotedAt != null)
                l10n.mlPromotedOn(mlFormatDate(_m.promotedAt!)),
            ].join(' · '),
            style: AppTextStyles.bodySmall.copyWith(color: secondary),
          ),
          if (_m.description?.isNotEmpty ?? false) ...[
            const SizedBox(height: AppSpacing.s),
            Text(_m.description!, style: AppTextStyles.bodyMedium),
          ],
          const SizedBox(height: AppSpacing.m),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final stage in _m.allowedTransitions)
                stage == 'production'
                    ? FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, kMinTouchTarget),
                        ),
                        onPressed: _busy ? null : () => _setStage(stage),
                        icon: Icon(_transitionIcon(stage), size: 18),
                        label: Text(_transitionLabel(l10n, stage)),
                      )
                    : OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, kMinTouchTarget),
                          foregroundColor:
                              stage == 'archived' ? AppColors.error : null,
                        ),
                        onPressed: _busy ? null : () => _setStage(stage),
                        icon: Icon(_transitionIcon(stage), size: 18),
                        label: Text(_transitionLabel(l10n, stage)),
                      ),
              if (_m.stage != 'training')
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, kMinTouchTarget),
                  ),
                  onPressed: _busy ? null : _convert,
                  icon: const Icon(PhosphorIconsRegular.deviceMobile, size: 18),
                  label: Text(l10n.mlActionConvert),
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

/// TRAINED → EVALUATED → VALIDATED → STAGING → PRODUCTION, current step
/// highlighted; passed steps carry a check mark, not only a colour.
class _StagePipeline extends StatelessWidget {
  const _StagePipeline({required this.stage});

  final String stage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = _pipeline.indexOf(stage);
    final archived = stage == 'archived';
    final secondary = AppColors.textSecondary(context);

    return Semantics(
      label: l10n.mlPipelineSemantics(mlStageLabel(l10n, stage)),
      child: ExcludeSemantics(
        child: Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (var i = 0; i < _pipeline.length; i++) ...[
              if (i > 0)
                Icon(PhosphorIconsRegular.caretRight, size: 14, color: secondary),
              _step(context, l10n, i, current, archived),
            ],
            if (archived) ...[
              const SizedBox(width: AppSpacing.s),
              MlStatusBadge(info: mlStageStatus(l10n, 'archived')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _step(
    BuildContext context,
    AppLocalizations l10n,
    int i,
    int current,
    bool archived,
  ) {
    final isCurrent = i == current;
    final passed = current >= 0 && i < current;
    final color = archived
        ? AppColors.textSecondary(context)
        : isCurrent
            ? AppColors.primary
            : passed
                ? AppColors.successLedge
                : AppColors.textSecondary(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrent && !archived ? AppColors.primary : null,
        borderRadius: AppRadius.radiusCircular,
        border: Border.all(
          color: isCurrent && !archived ? AppColors.primary : AppColors.border(context),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (passed && !archived) ...[
            Icon(AppIcons.check, size: 12, color: color),
            const SizedBox(width: 2),
          ],
          Text(
            mlStageLabel(l10n, _pipeline[i]),
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 11,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              color: isCurrent && !archived ? Colors.white : color,
            ),
          ),
        ],
      ),
    );
  }
}
