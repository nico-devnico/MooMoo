import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/workspace_overview.dart';
import '../../../domain/providers/workspace_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_panel.dart';
import '../../widgets/skeletons.dart';
import '../admin/admin_shell.dart';
import 'workspace_widgets.dart';

class ExpertDashboardScreen extends ConsumerWidget {
  const ExpertDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final overviewAsync = ref.watch(expertOverviewProvider);

    return AdminShell(
      workspace: Workspace.expert,
      selectedIndex: 0,
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(expertOverviewProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.l, AppSpacing.l, AppSpacing.xxl),
          children: [
            WorkspaceHeader(
              title: l10n.expertSpace,
              subtitle: l10n.expertSpaceSubtitle,
              onRefresh: overviewAsync.isLoading ? null : () => ref.invalidate(expertOverviewProvider),
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
                onAction: () => ref.invalidate(expertOverviewProvider),
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

  final ExpertOverview overview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final o = overview;
    void signs() => context.goNamed(AppRoutes.expertSignsName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WorkspaceStatGrid(children: [
          WorkspaceStatCard(
            label: l10n.adminStatPending,
            value: '${o.pendingContributions}',
            icon: PhosphorIconsRegular.hourglassMedium,
            color: AppColors.warning,
            onTap: () => context.goNamed(AppRoutes.expertContributionsName),
          ),
          WorkspaceStatCard(
            label: l10n.wsReviewedByMe,
            value: '${o.reviewedByMe}',
            icon: PhosphorIconsRegular.sealCheck,
            color: AppColors.success,
          ),
          WorkspaceStatCard(
            label: l10n.dmPublished,
            value: '${o.signsPublished} / ${o.signsTotal}',
            icon: AppIcons.dictionary,
            color: AppColors.primary,
            onTap: signs,
          ),
          WorkspaceStatCard(
            label: l10n.dmDraft,
            value: '${o.signsDraft}',
            icon: PhosphorIconsRegular.notePencil,
            color: AppColors.warning,
            onTap: signs,
          ),
          WorkspaceStatCard(
            label: l10n.wsSignsWithoutVideo,
            value: '${o.signsWithoutVideo}',
            icon: AppIcons.video,
            color: AppColors.error,
            onTap: signs,
          ),
          WorkspaceStatCard(
            label: l10n.wsSignsWithoutCategory,
            value: '${o.signsWithoutCategory}',
            icon: PhosphorIconsRegular.tag,
            color: AppColors.error,
            onTap: signs,
          ),
          WorkspaceStatCard(
            label: l10n.dmCategories,
            value: '${o.categoriesTotal}',
            icon: PhosphorIconsRegular.squaresFour,
            color: AppColors.primary,
            onTap: signs,
          ),
        ]),
        const SizedBox(height: AppSpacing.xl),
        Semantics(header: true, child: Text(l10n.wsByLanguage, style: AppTextStyles.h3)),
        const SizedBox(height: AppSpacing.s),
        for (final lang in o.languages)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s),
            child: AppPanel(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${lang.name} (${lang.code})', style: AppTextStyles.bodyLarge),
                  ),
                  Text(
                    l10n.wsLanguageCounts(lang.signs, lang.published),
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
