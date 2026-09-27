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

class AdminShell extends ConsumerWidget {
  final Widget child;
  final int selectedIndex;

  const AdminShell({
    super.key,
    required this.child,
    required this.selectedIndex,
  });

  void _go(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.goNamed(AppRoutes.adminDashboardName);
        break;
      case 1:
        context.goNamed(AppRoutes.adminContributionsName);
        break;
      case 2:
        context.goNamed(AppRoutes.adminSignsName);
        break;
      case 3:
        context.goNamed(AppRoutes.adminUsersName);
        break;
      case 4:
        context.goNamed(AppRoutes.adminModelsName);
        break;
      case 5:
        context.goNamed(AppRoutes.adminSettingsName);
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isAdmin = ref.watch(isAdminProvider);
    final isWide = context.hasSideNavigation;

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.adminPanel)),
        body: PageContainer.form(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 56, color: AppColors.warning),
              const SizedBox(height: AppSpacing.m),
              Text(l10n.adminAccessDenied, style: AppTextStyles.h3, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.s),
              Text(
                l10n.adminAccessDeniedMessage,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.l),
              FilledButton(
                onPressed: () => context.goNamed(AppRoutes.profileName),
                child: Text(l10n.backToProfile),
              ),
            ],
          ),
        ),
      );
    }

    final destinations = [
      _AdminDest(Icons.dashboard_outlined, Icons.dashboard, l10n.adminDashboard),
      _AdminDest(Icons.rate_review_outlined, Icons.rate_review, l10n.adminModeration),
      _AdminDest(Icons.menu_book_outlined, Icons.menu_book, l10n.adminSigns),
      _AdminDest(Icons.people_outline, Icons.people, l10n.adminUsers),
      _AdminDest(Icons.memory_outlined, Icons.memory, l10n.adminModels),
      _AdminDest(Icons.tune_outlined, Icons.tune, l10n.adminSettings),
    ];

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (i) => _go(context, i),
              extended: context.hasExtendedSideNavigation,
              minWidth: 80,
              minExtendedWidth: 220,
              labelType: context.hasExtendedSideNavigation
                  ? null
                  : NavigationRailLabelType.all,
              backgroundColor: Theme.of(context).colorScheme.surface,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
                child: Column(
                  children: [
                    const Icon(Icons.admin_panel_settings, color: AppColors.primary, size: 32),
                    const SizedBox(height: AppSpacing.s),
                    Text(l10n.adminPanel, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.l),
                    child: IconButton(
                      tooltip: l10n.backToApp,
                      onPressed: () => context.goNamed(AppRoutes.homeName),
                      icon: const Icon(Icons.arrow_back),
                    ),
                  ),
                ),
              ),
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            // Admin screens are data-dense: cap them so tables and card
            // columns stay readable on very wide monitors.
            Expanded(child: PageContainer(padding: 0, child: child)),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminPanel),
        leading: IconButton(
          tooltip: l10n.backToApp,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goNamed(AppRoutes.homeName),
        ),
      ),
      body: PageContainer(padding: 0, child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) => _go(context, i),
        // Six destinations do not fit side by side on a phone with all labels
        // visible; showing only the active one keeps them legible.
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}

class _AdminDest {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _AdminDest(this.icon, this.selectedIcon, this.label);
}
