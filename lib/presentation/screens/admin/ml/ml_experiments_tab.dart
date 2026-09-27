import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/ml_training.dart';
import '../../../../domain/providers/ml_training_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/app_badge.dart';
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/app_panel.dart';
import '../../../widgets/app_snackbar.dart';
import 'ml_common.dart';
import 'ml_experiment_compare.dart';
import 'ml_experiment_detail.dart';
import 'ml_skeletons.dart';

const _maxCompared = 4;

class MlExperimentsTab extends ConsumerStatefulWidget {
  const MlExperimentsTab({super.key});

  @override
  ConsumerState<MlExperimentsTab> createState() => _MlExperimentsTabState();
}

class _MlExperimentsTabState extends ConsumerState<MlExperimentsTab> {
  String? _language;
  final List<String> _selected = [];
  bool _comparing = false;

  void _toggle(MlExperiment exp) {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      if (_selected.contains(exp.id)) {
        _selected.remove(exp.id);
        if (_selected.length < 2) _comparing = false;
      } else if (_selected.length >= _maxCompared) {
        AppSnackbar.showWarning(context, l10n.mlCompareMax(_maxCompared));
      } else {
        _selected.add(exp.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(mlExperimentsProvider(null));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(mlExperimentsProvider);
        await ref.read(mlExperimentsProvider(null).future);
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
              title: l10n.mlTabExperiments,
              subtitle: l10n.mlExperimentsSubtitle,
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          MlConstrained(
            child: async.when(
              loading: () => MlCardListSkeleton(label: l10n.loading, count: 3),
              error: (e, _) => MlErrorPanel(
                error: e,
                onRetry: () => ref.invalidate(mlExperimentsProvider),
              ),
              data: _content,
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(List<MlExperiment> all) {
    final l10n = AppLocalizations.of(context)!;
    if (all.isEmpty) {
      return AppPanel(
        child: AppEmptyState(
          icon: PhosphorIconsRegular.flask,
          title: l10n.mlExperimentsEmpty,
          message: l10n.mlExperimentsEmptyMessage,
        ),
      );
    }
    final languages = all.map((e) => e.languageCode).toSet().toList()..sort();
    final visible = _language == null
        ? all
        : all.where((e) => e.languageCode == _language).toList();
    final selected = [
      for (final id in _selected) ...all.where((e) => e.id == id),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            ChoiceChip(
              label: Text(l10n.mlFilterAll),
              selected: _language == null,
              onSelected: (_) => setState(() => _language = null),
            ),
            for (final lang in languages)
              ChoiceChip(
                label: Text(lang),
                selected: _language == lang,
                onSelected: (_) => setState(() => _language = lang),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              l10n.mlCompareSelection(selected.length, _maxCompared),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, kMinTouchTarget),
              ),
              onPressed: selected.length >= 2
                  ? () => setState(() => _comparing = true)
                  : null,
              icon: const Icon(PhosphorIconsRegular.chartLine, size: 18),
              label: Text(l10n.mlCompare),
            ),
            if (selected.isNotEmpty)
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, kMinTouchTarget),
                ),
                onPressed: () => setState(() {
                  _selected.clear();
                  _comparing = false;
                }),
                child: Text(l10n.mlClearSelection),
              ),
          ],
        ),
        if (_comparing && selected.length >= 2) ...[
          const SizedBox(height: AppSpacing.m),
          MlExperimentCompare(
            experiments: selected,
            onClose: () => setState(() => _comparing = false),
          ),
        ],
        const SizedBox(height: AppSpacing.m),
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.s),
          _ExperimentCard(
            experiment: visible[i],
            selected: _selected.contains(visible[i].id),
            onToggle: () => _toggle(visible[i]),
          ),
        ],
      ],
    );
  }
}

class _ExperimentCard extends StatelessWidget {
  const _ExperimentCard({
    required this.experiment,
    required this.selected,
    required this.onToggle,
  });

  final MlExperiment experiment;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final e = experiment;
    final secondary = AppColors.textSecondary(context);

    return AppPanel(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s,
        AppSpacing.m,
        AppSpacing.m,
        AppSpacing.m,
      ),
      borderColor: selected ? AppColors.primary : null,
      onTap: () => showMlExperimentDetail(context, e),
      semanticLabel: l10n.mlExperimentTitle(e.code),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: selected,
            onChanged: (_) => onToggle(),
            semanticLabel: l10n.mlCompareSelect(e.code),
          ),
          const SizedBox(width: AppSpacing.xs),
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
                      e.code,
                      style: AppTextStyles.mono.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    MlStatusBadge(info: mlExperimentStatus(l10n, e.status)),
                    AppBadge(label: e.languageCode, color: AppColors.primary),
                    if (e.modelId != null)
                      MlStatusBadge(
                        info: (
                          label: l10n.mlRegistered,
                          color: AppColors.success,
                          icon: PhosphorIconsRegular.package,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  [e.architectureText, mlHyperparamsText(e)]
                      .where((s) => s.isNotEmpty)
                      .join(' Â· '),
                  style: AppTextStyles.bodySmall.copyWith(color: secondary),
                ),
                const SizedBox(height: AppSpacing.s),
                Wrap(
                  spacing: AppSpacing.s,
                  runSpacing: AppSpacing.s,
                  children: [
                    MlMetricChip(
                      label: l10n.mlColEpochs,
                      value:
                          '${e.currentEpoch} / ${e.totalEpochs ?? e.budgetEpochs ?? '—'}',
                    ),
                    MlMetricChip(
                      label: l10n.mlColBestValAcc,
                      value: mlPercent(e.bestValAccuracy),
                    ),
                    MlMetricChip(
                      label: l10n.mlMetricAccuracy,
                      value: mlPercent(e.accuracy),
                    ),
                    MlMetricChip(
                      label: l10n.mlColMacroF1,
                      value: mlPercent(e.macroF1),
                    ),
                    MlMetricChip(
                      label: l10n.mlColDuration,
                      value: mlFormatSeconds(e.durationS),
                    ),
                    if (e.modelSizeBytes != null)
                      MlMetricChip(
                        label: l10n.mlMetricSize,
                        value: mlFormatBytes(l10n, e.modelSizeBytes),
                      ),
                  ],
                ),
                if (e.status == 'failed' && (e.errorMessage?.isNotEmpty ?? false))
                  MlNoticeLine(
                    icon: AppIcons.error,
                    color: AppColors.error,
                    text: e.errorMessage!,
                  ),
              ],
            ),
          ),
          ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s),
              child: Icon(AppIcons.chevron, color: secondary, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
