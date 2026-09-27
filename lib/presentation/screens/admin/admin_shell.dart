import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/providers/admin_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_nav_bar.dart';

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
        context.goNamed(AppRoutes.adminLearningName);
        break;
      case 4:
        context.goNamed(AppRoutes.adminUsersName);
        break;
      case 5:
        context.goNamed(AppRoutes.adminModelsName);
        break;
      case 6:
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
              const Icon(AppIcons.locked, size: 56, color: AppColors.warning),
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
      _AdminDest(AppIcons.dashboard, PhosphorIconsFill.chartBar, l10n.adminDashboard),
      _AdminDest(AppIcons.moderation, PhosphorIconsFill.notePencil, l10n.adminModeration),
      _AdminDest(AppIcons.dictionary, AppIcons.dictionaryActive, l10n.adminSigns),
      _AdminDest(AppIcons.learning, AppIcons.learningActive, l10n.adminLearning),
      _AdminDest(AppIcons.users, PhosphorIconsFill.users, l10n.adminUsers),
      _AdminDest(AppIcons.model, PhosphorIconsFill.cpu, l10n.adminModels),
      _AdminDest(AppIcons.settings, PhosphorIconsFill.gear, l10n.adminSettings),
    ];

    if (isWide) {
      return Scaffold(
        body: Column(
          children: [
            AppNavBar(
              semanticLabel: l10n.adminPanel,
              brand: AppNavBrand(
                title: l10n.adminPanel,
                icon: AppIcons.admin,
              ),
              selectedIndex: selectedIndex,
              onDestinationSelected: (i) => _go(context, i),
              destinations: [
                for (final d in destinations)
                  NavBarDestination(
                    icon: d.icon,
                    selectedIcon: d.selectedIcon,
                    label: d.label,
                  ),
              ],
              actions: [
                TextButton.icon(
                  onPressed: () => context.goNamed(AppRoutes.homeName),
                  icon: const Icon(AppIcons.back, size: 18),
                  label: Text(l10n.backToApp),
                ),
              ],
            ),
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
          icon: const Icon(AppIcons.back),
          onPressed: () => context.goNamed(AppRoutes.homeName),
        ),
      ),
      body: PageContainer(padding: 0, child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) => _go(context, i),
        // Seven destinations do not fit side by side on a phone with all labels
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
