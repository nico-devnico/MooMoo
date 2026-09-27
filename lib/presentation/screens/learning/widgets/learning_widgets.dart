import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/learning.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/app_panel.dart';

/// Compact figure with an icon, e.g. the streak or the XP total.
class LearningStatPill extends StatelessWidget {
  const LearningStatPill({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    required this.semanticLabel,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: AppRadius.radiusCircular,
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: AppSpacing.xs + 2),
            Text(
              value,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StreakPill extends StatelessWidget {
  const StreakPill({super.key, required this.summary});

  final LearnerSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final active = summary.currentStreak > 0;
    return LearningStatPill(
      icon: active ? AppIcons.streakActive : AppIcons.streak,
      color: active ? AppColors.warning : AppColors.textSecondary(context),
      value: '${summary.currentStreak}',
      semanticLabel: l10n.learnStreakDays(summary.currentStreak),
    );
  }
}

class XpPill extends StatelessWidget {
  const XpPill({super.key, required this.summary});

  final LearnerSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return LearningStatPill(
      icon: AppIcons.pointsActive,
      color: AppColors.primary,
      value: '${summary.totalXp}',
      semanticLabel: l10n.learnXpAmount(summary.totalXp),
    );
  }
}

/// Today's XP against the learner's daily goal.
class DailyGoalCard extends StatelessWidget {
  const DailyGoalCard({super.key, required this.summary, this.onTap});

  final LearnerSummary summary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reached = summary.dailyGoalReached;
    final accent = reached ? AppColors.success : AppColors.primary;
    final progressText = l10n.learnDailyGoalProgress(summary.todayXp, summary.dailyGoalXp);

    return AppPanel(
      onTap: onTap,
      semanticLabel: '${l10n.learnDailyGoal}, $progressText'
          '${reached ? ', ${l10n.learnDailyGoalReached}' : ''}',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: reached ? AppColors.successSoft : AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    reached ? AppIcons.success : AppIcons.goal,
                    color: accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Text(
                    l10n.learnDailyGoal,
                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  progressText,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            ClipRRect(
              borderRadius: AppRadius.radiusCircular,
              child: LinearProgressIndicator(
                value: summary.dailyGoalProgress,
                minHeight: 10,
                color: accent,
                backgroundColor: AppColors.neutral(context),
              ),
            ),
            if (reached) ...[
              const SizedBox(height: AppSpacing.s),
              Text(
                l10n.learnDailyGoalReached,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
