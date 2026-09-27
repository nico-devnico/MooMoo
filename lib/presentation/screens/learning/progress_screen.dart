import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/learning.dart';
import '../../../domain/providers/learning_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_panel.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/skeletons.dart';
import 'widgets/learning_widgets.dart';
import '../../../domain/providers/error_text.dart';

const List<int> _goalOptions = [10, 20, 30, 50];

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summaryAsync = ref.watch(learnerSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.progressTitle)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(learnerSummaryProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
          child: PageContainer.reading(
            child: summaryAsync.when(
              data: (summary) => _ProgressContent(summary: summary),
              loading: () => const _ProgressSkeleton(),
              error: (error, _) => AppEmptyState(
                icon: AppIcons.error,
                title: l10n.errorGeneric,
                message: ref.userErrorText(error, l10n),
                actionLabel: l10n.retry,
                onAction: () => ref.invalidate(learnerSummaryProvider),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressContent extends ConsumerStatefulWidget {
  const _ProgressContent({required this.summary});

  final LearnerSummary summary;

  @override
  ConsumerState<_ProgressContent> createState() => _ProgressContentState();
}

class _ProgressContentState extends ConsumerState<_ProgressContent> {
  int? _savingGoal;

  Future<void> _setGoal(int goal) async {
    if (goal == widget.summary.dailyGoalXp || _savingGoal != null) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _savingGoal = goal);
    try {
      await ref.read(learningRepositoryProvider).setDailyGoal(goal);
      ref.invalidate(learnerSummaryProvider);
      if (mounted) AppSnackbar.showSuccess(context, l10n.progressGoalSaved);
    } catch (_) {
      if (mounted) AppSnackbar.showError(context, l10n.errorGeneric);
    } finally {
      if (mounted) setState(() => _savingGoal = null);
    }
  }

  String _goalName(AppLocalizations l10n, int goal) => switch (goal) {
        10 => l10n.progressGoalCasual,
        20 => l10n.progressGoalRegular,
        30 => l10n.progressGoalSerious,
        _ => l10n.progressGoalIntense,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final summary = widget.summary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: adaptiveGridDelegate(maxItemWidth: 200, childAspectRatio: 1.35),
          children: [
            _StatTile(
              icon: AppIcons.streakActive,
              color: AppColors.warning,
              value: l10n.lessonDays(summary.currentStreak),
              label: l10n.progressCurrentStreak,
            ),
            _StatTile(
              icon: AppIcons.trophy,
              color: AppColors.warning,
              value: l10n.lessonDays(summary.longestStreak),
              label: l10n.progressLongestStreak,
            ),
            _StatTile(
              icon: AppIcons.pointsActive,
              color: AppColors.primary,
              value: '${summary.totalXp}',
              label: l10n.progressTotalXp,
            ),
            _StatTile(
              icon: AppIcons.success,
              color: AppColors.success,
              value: '${summary.lessonsCompleted}',
              label: l10n.progressLessonsDone,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        DailyGoalCard(summary: summary),
        const SizedBox(height: AppSpacing.xl),
        Semantics(
          header: true,
          child: Text(l10n.progressDailyGoalTitle, style: AppTextStyles.h3),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.progressDailyGoalHint,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context)),
        ),
        const SizedBox(height: AppSpacing.m),
        for (final goal in _goalOptions) ...[
          _GoalOption(
            title: _goalName(l10n, goal),
            subtitle: l10n.progressGoalOption(goal),
            selected: summary.dailyGoalXp == goal,
            saving: _savingGoal == goal,
            onTap: () => _setGoal(goal),
          ),
          const SizedBox(height: AppSpacing.s),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      semanticLabel: '$label: $value',
      padding: const EdgeInsets.all(AppSpacing.m),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 26),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: AppTextStyles.h2),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary(context)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalOption extends StatelessWidget {
  const _GoalOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.saving,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final bool saving;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: AppPanel(
        onTap: onTap,
        semanticLabel: '$title, $subtitle',
        color: selected ? AppColors.primarySoft : null,
        borderColor: selected ? AppColors.primary : null,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
        child: ExcludeSemantics(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: selected ? AppColors.primary : null,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary(context)),
                    ),
                  ],
                ),
              ),
              if (saving)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  selected ? AppIcons.success : Icons.circle_outlined,
                  color: selected ? AppColors.primary : AppColors.border(context),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressSkeleton extends StatelessWidget {
  const _ProgressSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      label: AppLocalizations.of(context)!.loading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: adaptiveGridDelegate(maxItemWidth: 200, childAspectRatio: 1.35),
            itemCount: 4,
            itemBuilder: (_, _) => const SkeletonBlock(height: double.infinity, radius: AppRadius.l),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SkeletonBlock(height: 108, radius: AppRadius.l),
          const SizedBox(height: AppSpacing.xl),
          const SkeletonBlock(width: 180, height: 20),
          const SizedBox(height: AppSpacing.m),
          for (var i = 0; i < 4; i++) ...[
            const SkeletonBlock(height: 68, radius: AppRadius.l),
            const SizedBox(height: AppSpacing.s),
          ],
        ],
      ),
    );
  }
}
