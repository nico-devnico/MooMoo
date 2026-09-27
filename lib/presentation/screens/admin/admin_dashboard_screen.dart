import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/providers/admin_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_loader.dart';
import '../../widgets/app_empty_state.dart';
import 'admin_shell.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(adminStatsProvider);

    return AdminShell(
      selectedIndex: 0,
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminStatsProvider),
        child: statsAsync.when(
          data: (stats) {
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.l),
              children: [
                Text(l10n.adminDashboard, style: AppTextStyles.h2),
                const SizedBox(height: AppSpacing.s),
                Text(l10n.adminDashboardSubtitle, style: AppTextStyles.bodyMedium.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                )),
                const SizedBox(height: AppSpacing.xl),
                GridView(
                  gridDelegate: adaptiveGridDelegate(
                    maxItemWidth: 260,
                    childAspectRatio: 1.35,
                  ),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _StatCard(
                      label: l10n.adminStatUsers,
                      value: stats.usersCount.toString(),
                      icon: Icons.people_outline,
                      color: AppColors.primary,
                      onTap: () => context.goNamed(AppRoutes.adminUsersName),
                    ),
                    _StatCard(
                      label: l10n.adminStatSigns,
                      value: stats.signsCount.toString(),
                      icon: Icons.menu_book_outlined,
                      color: AppColors.secondary,
                      onTap: () => context.goNamed(AppRoutes.adminSignsName),
                    ),
                    _StatCard(
                      label: l10n.adminStatPending,
                      value: stats.pendingContributionsCount.toString(),
                      icon: Icons.hourglass_empty,
                      color: AppColors.warning,
                      onTap: () => context.goNamed(AppRoutes.adminContributionsName),
                    ),
                    _StatCard(
                      label: l10n.adminStatValidated,
                      value: stats.validatedSignsCount.toString(),
                      icon: Icons.verified_outlined,
                      color: AppColors.success,
                      onTap: () => context.goNamed(AppRoutes.adminSignsName),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(l10n.adminQuickActions, style: AppTextStyles.h3),
                const SizedBox(height: AppSpacing.m),
                _QuickActionTile(
                  icon: Icons.rate_review_outlined,
                  title: l10n.adminReviewPending,
                  subtitle: l10n.adminReviewPendingDesc(stats.pendingContributionsCount),
                  onTap: () => context.goNamed(AppRoutes.adminContributionsName),
                ),
                const SizedBox(height: AppSpacing.s),
                _QuickActionTile(
                  icon: Icons.library_books_outlined,
                  title: l10n.adminManageSigns,
                  subtitle: l10n.adminManageSignsDesc,
                  onTap: () => context.goNamed(AppRoutes.adminSignsName),
                ),
                const SizedBox(height: AppSpacing.s),
                _QuickActionTile(
                  icon: Icons.people_outline,
                  title: l10n.adminManageUsers,
                  subtitle: l10n.adminManageUsersDesc,
                  onTap: () => context.goNamed(AppRoutes.adminUsersName),
                ),
                const SizedBox(height: AppSpacing.s),
                _QuickActionTile(
                  icon: Icons.memory_outlined,
                  title: l10n.adminModels,
                  subtitle: l10n.adminModelsSubtitle,
                  onTap: () => context.goNamed(AppRoutes.adminModelsName),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.adminContributionsOverview, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: AppSpacing.m),
                      _MiniStatRow(label: l10n.statusPending, value: stats.pendingContributionsCount, color: AppColors.warning),
                      _MiniStatRow(label: l10n.statusApproved, value: stats.approvedContributionsCount, color: AppColors.success),
                      _MiniStatRow(label: l10n.statusRejected, value: stats.rejectedContributionsCount, color: AppColors.error),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: AppLoader()),
          error: (e, _) => AppEmptyState(
            title: l10n.errorGeneric,
            message: e.toString(),
            imagePath: null,
            actionLabel: l10n.retry,
            onAction: () => ref.invalidate(adminStatsProvider),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTextStyles.h2.copyWith(color: color)),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _MiniStatRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _MiniStatRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          Text('$value', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
