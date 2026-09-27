import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/workspace_overview.dart';
import '../../../domain/providers/workspace_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_panel.dart';
import '../../widgets/skeletons.dart';
import '../admin/admin_shell.dart';
import 'workspace_widgets.dart';

class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final overviewAsync = ref.watch(teacherOverviewProvider);

    return AdminShell(
      workspace: Workspace.teacher,
      selectedIndex: 0,
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(teacherOverviewProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.l, AppSpacing.l, AppSpacing.xxl),
          children: [
            WorkspaceHeader(
              title: l10n.teacherSpace,
              subtitle: l10n.teacherSpaceSubtitle,
              onRefresh: overviewAsync.isLoading ? null : () => ref.invalidate(teacherOverviewProvider),
            ),
            const SizedBox(height: AppSpacing.xl),
            overviewAsync.when(
              data: (o) => _Body(overview: o),
              loading: () => const SkeletonList(itemCount: 4, hasTrailing: true),
              error: (e, _) => AppEmptyState(
                icon: AppIcons.error,
                title: l10n.errorGeneric,
                message: e.toString(),
                actionLabel: l10n.retry,
                onAction: () => ref.invalidate(teacherOverviewProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.overview});

  final TeacherOverview overview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final o = overview;
    final dateFormat = DateFormat.yMMMd(Localizations.localeOf(context).toString());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WorkspaceStatGrid(children: [
          WorkspaceStatCard(
            label: l10n.wsUnitsPublished,
            value: '${o.unitsPublished} / ${o.unitsTotal}',
            icon: AppIcons.learning,
            color: AppColors.primary,
            onTap: () => context.goNamed(AppRoutes.teacherLearningName),
          ),
          WorkspaceStatCard(
            label: l10n.wsLessons,
            value: '${o.lessonsTotal}',
            icon: PhosphorIconsRegular.bookOpen,
            color: AppColors.primary,
            onTap: () => context.goNamed(AppRoutes.teacherLearningName),
          ),
          WorkspaceStatCard(
            label: l10n.wsLearners,
            value: '${o.learnersTotal}',
            icon: AppIcons.users,
            color: AppColors.success,
          ),
          WorkspaceStatCard(
            label: l10n.wsCompletions7d(o.completionsTotal),
            value: '${o.completions7d}',
            icon: PhosphorIconsRegular.checkSquare,
            color: AppColors.warning,
          ),
          WorkspaceStatCard(
            label: l10n.wsAverageScore,
            value: o.averageScore == null ? '—' : '${o.averageScore!.toStringAsFixed(1)} %',
            icon: PhosphorIconsRegular.target,
            color: AppColors.success,
          ),
        ]),
        const SizedBox(height: AppSpacing.xl),
        Semantics(header: true, child: Text(l10n.wsLessonStats, style: AppTextStyles.h3)),
        const SizedBox(height: AppSpacing.s),
        if (o.lessons.isEmpty)
          AppEmptyState(
            icon: AppIcons.learning,
            title: l10n.wsNoLessons,
            message: l10n.wsNoLessonsMessage,
            actionLabel: l10n.learnManagePath,
            onAction: () => context.goNamed(AppRoutes.teacherLearningName),
          )
        else
          for (final lesson in o.lessons)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s),
              child: AppPanel(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: AppSpacing.s,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(lesson.lessonTitle,
                                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                              if (!lesson.unitPublished)
                                AppBadge(label: l10n.dmDraft, color: AppColors.warning),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            [
                              lesson.unitTitle,
                              if (lesson.lastCompletedAt != null)
                                l10n.wsLastCompletion(dateFormat.format(lesson.lastCompletedAt!.toLocal())),
                            ].join(' · '),
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary(context)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(l10n.wsCompletionsCount(lesson.completions), style: AppTextStyles.bodyMedium),
                        Text(
                          '${l10n.wsLearnersCount(lesson.learners)} · '
                          '${lesson.averageScore == null ? '—' : '${lesson.averageScore!.toStringAsFixed(0)} %'}',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary(context)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
