import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/admin_stats.dart';
import '../../../domain/providers/admin_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_panel.dart';
import '../../widgets/skeletons.dart';
import 'admin_shell.dart';
import '../../../domain/providers/error_text.dart';

/// Au-delà de cette largeur, l'aperçu et les actions rapides passent côte à côte.
const double _splitBreakpoint = 880;

/// Mêmes dimensions que [SkeletonStatCards] : le squelette et les cartes
/// occupent exactement la même place.
SliverGridDelegate _statGridDelegate() =>
    adaptiveGridDelegate(maxItemWidth: 260, childAspectRatio: 1.9);

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(adminStatsProvider);

    return AdminShell(
      selectedIndex: 0,
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(adminStatsProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.l,
            AppSpacing.l,
            AppSpacing.l,
            AppSpacing.xxl,
          ),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          l10n.adminDashboard,
                          style: AppTextStyles.h2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s),
                      Text(
                        l10n.adminDashboardSubtitle,
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
                  onPressed: statsAsync.isLoading
                      ? null
                      : () => ref.invalidate(adminStatsProvider),
                  icon: const Icon(AppIcons.refresh),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            statsAsync.when(
              data: (stats) => _DashboardBody(stats: stats),
              loading: () => const _DashboardSkeleton(),
              error: (e, _) => AppEmptyState(
                icon: AppIcons.error,
                title: l10n.errorGeneric,
                message: ref.userErrorText(e, l10n),
                actionLabel: l10n.retry,
                onAction: () => ref.invalidate(adminStatsProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.stats});

  final AdminStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final cards = [
      _StatCard(
        label: l10n.adminStatUsers,
        value: stats.usersCount,
        icon: AppIcons.users,
        color: AppColors.primary,
        onTap: () => context.goNamed(AppRoutes.adminUsersName),
      ),
      _StatCard(
        label: l10n.adminStatSigns,
        value: stats.signsCount,
        icon: AppIcons.dictionary,
        color: AppColors.primary,
        onTap: () => context.goNamed(AppRoutes.adminSignsName),
      ),
      _StatCard(
        label: l10n.adminStatPending,
        value: stats.pendingContributionsCount,
        icon: PhosphorIconsRegular.hourglassMedium,
        color: AppColors.warning,
        onTap: () => context.goNamed(AppRoutes.adminContributionsName),
      ),
      _StatCard(
        label: l10n.adminStatValidated,
        value: stats.validatedSignsCount,
        icon: PhosphorIconsRegular.sealCheck,
        color: AppColors.success,
        onTap: () => context.goNamed(AppRoutes.adminSignsName),
      ),
    ];

    final overview = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ContributionsPanel(stats: stats),
        const SizedBox(height: AppSpacing.l),
        _ValidationPanel(stats: stats),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView(
          gridDelegate: _statGridDelegate(),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: cards,
        ),
        const SizedBox(height: AppSpacing.xl),
        LayoutBuilder(
          builder: (context, constraints) {
            final quickActions = _QuickActions(stats: stats);
            if (constraints.maxWidth < _splitBreakpoint) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  overview,
                  const SizedBox(height: AppSpacing.xl),
                  quickActions,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: overview),
                const SizedBox(width: AppSpacing.l),
                Expanded(flex: 2, child: quickActions),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      onTap: onTap,
      semanticLabel: '$label : $value',
      padding: EdgeInsets.zero,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Deux colonnes sur téléphone : l'icône céderait la place au chiffre.
            final compact = constraints.maxWidth < 190;
            return Padding(
              padding: EdgeInsets.all(
                compact ? AppSpacing.m - 4 : AppSpacing.m,
              ),
              child: Row(
                children: [
                  if (!compact) ...[
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: AppRadius.radiusM,
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.m),
                  ],
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$value',
                          maxLines: 1,
                          style: AppTextStyles.h2.copyWith(height: 1.1),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        text,
        style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ContributionsPanel extends StatelessWidget {
  const _ContributionsPanel({required this.stats});

  final AdminStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final segments = [
      (l10n.statusPending, stats.pendingContributionsCount, AppColors.warning),
      (
        l10n.statusApproved,
        stats.approvedContributionsCount,
        AppColors.success,
      ),
      (l10n.statusRejected, stats.rejectedContributionsCount, AppColors.error),
    ];
    final total = segments.fold<int>(0, (sum, s) => sum + s.$2);

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle(l10n.adminContributionsOverview),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.admxContributionsTotal(total),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          // Barre empilée proportionnelle aux compteurs réels ; purement
          // décorative, la légende porte l'information.
          ExcludeSemantics(
            child: ClipRRect(
              borderRadius: AppRadius.radiusCircular,
              child: SizedBox(
                height: 12,
                child: total == 0
                    ? ColoredBox(color: AppColors.neutral(context))
                    : Row(
                        children: [
                          for (final s in segments)
                            if (s.$2 > 0)
                              Expanded(
                                flex: s.$2,
                                child: ColoredBox(color: s.$3),
                              ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          for (final s in segments)
            _LegendRow(label: s.$1, value: s.$2, total: total, color: s.$3),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  final String label;
  final int value;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0 : (value * 100 / total).round();
    return Semantics(
      label: '$label : $value ($percent %)',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.s),
            Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
            Text(
              '$percent %',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            SizedBox(
              width: 48,
              child: Text(
                '$value',
                textAlign: TextAlign.end,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValidationPanel extends StatelessWidget {
  const _ValidationPanel({required this.stats});

  final AdminStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = stats.signsCount;
    final ratio = total == 0 ? 0.0 : stats.validatedSignsCount / total;

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle(l10n.admxSignsValidation),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.admxSignsValidatedOf(stats.validatedSignsCount, total),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          ExcludeSemantics(
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 12,
              borderRadius: AppRadius.radiusCircular,
              color: AppColors.success,
              backgroundColor: AppColors.neutral(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.stats});

  final AdminStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final actions = [
      (
        AppIcons.moderation,
        l10n.adminReviewPending,
        l10n.adminReviewPendingDesc(stats.pendingContributionsCount),
        AppRoutes.adminContributionsName,
      ),
      (
        AppIcons.dictionary,
        l10n.adminSigns,
        l10n.adminManageSignsDesc,
        AppRoutes.adminSignsName,
      ),
      (
        AppIcons.users,
        l10n.adminManageUsers,
        l10n.adminManageUsersDesc,
        AppRoutes.adminUsersName,
      ),
      (
        AppIcons.model,
        l10n.adminModels,
        l10n.adminModelsSubtitle,
        AppRoutes.adminModelsName,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(l10n.adminQuickActions, style: AppTextStyles.h3),
        ),
        const SizedBox(height: AppSpacing.m),
        AppPanel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) Divider(height: 1, color: AppColors.border(context)),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.m,
                    vertical: AppSpacing.xs,
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: AppRadius.radiusM,
                    ),
                    child: Icon(
                      actions[i].$1,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    actions[i].$2,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    actions[i].$3,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  trailing: Icon(
                    AppIcons.chevron,
                    size: 18,
                    color: AppColors.textSecondary(context),
                  ),
                  onTap: () => context.goNamed(actions[i].$4),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    const overview = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SkeletonBlock(height: 208, radius: AppRadius.l),
        SizedBox(height: AppSpacing.l),
        SkeletonBlock(height: 124, radius: AppRadius.l),
      ],
    );
    const quickActions = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SkeletonBlock(width: 160, height: 22),
        ),
        SizedBox(height: AppSpacing.m),
        SkeletonBlock(height: 4 * 76, radius: AppRadius.l),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SkeletonStatCards(label: l10n.loading),
        const SizedBox(height: AppSpacing.xl),
        Skeleton(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < _splitBreakpoint) {
                return const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    overview,
                    SizedBox(height: AppSpacing.xl),
                    quickActions,
                  ],
                );
              }
              return const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: overview),
                  SizedBox(width: AppSpacing.l),
                  Expanded(flex: 2, child: quickActions),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
