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
import '../../../domain/providers/workspace_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_nav_bar.dart';

/// Role spaces sharing this shell. Access is also enforced by row level
/// security, this only decides what the interface offers.
enum Workspace { admin, teacher, expert }

class AdminShell extends ConsumerWidget {
  final Widget child;
  final int selectedIndex;
  final Workspace workspace;

  const AdminShell({
    super.key,
    required this.child,
    required this.selectedIndex,
    this.workspace = Workspace.admin,
  });

  static List<_AdminDest> _destinationsFor(
    Workspace workspace,
    AppLocalizations l10n,
  ) {
    return switch (workspace) {
      Workspace.admin => [
        _AdminDest(
          AppIcons.dashboard,
          PhosphorIconsFill.chartBar,
          l10n.adminDashboard,
          AppRoutes.adminDashboardName,
        ),
        _AdminDest(
          AppIcons.moderation,
          PhosphorIconsFill.notePencil,
          l10n.adminModeration,
          AppRoutes.adminContributionsName,
        ),
        _AdminDest(
          AppIcons.dictionary,
          AppIcons.dictionaryActive,
          l10n.adminSigns,
          AppRoutes.adminSignsName,
        ),
        _AdminDest(
          AppIcons.learning,
          AppIcons.learningActive,
          l10n.adminLearning,
          AppRoutes.adminLearningName,
        ),
        _AdminDest(
          AppIcons.users,
          PhosphorIconsFill.users,
          l10n.adminUsers,
          AppRoutes.adminUsersName,
        ),
        _AdminDest(
          AppIcons.model,
          PhosphorIconsFill.cpu,
          l10n.adminModels,
          AppRoutes.adminModelsName,
        ),
        _AdminDest(
          AppIcons.settings,
          PhosphorIconsFill.gear,
          l10n.adminSettings,
          AppRoutes.adminSettingsName,
        ),
      ],
      Workspace.teacher => [
        _AdminDest(
          AppIcons.dashboard,
          PhosphorIconsFill.chartBar,
          l10n.adminDashboard,
          AppRoutes.teacherDashboardName,
        ),
        _AdminDest(
          AppIcons.learning,
          AppIcons.learningActive,
          l10n.adminLearning,
          AppRoutes.teacherLearningName,
        ),
      ],
      Workspace.expert => [
        _AdminDest(
          AppIcons.dashboard,
          PhosphorIconsFill.chartBar,
          l10n.adminDashboard,
          AppRoutes.expertDashboardName,
        ),
        _AdminDest(
          AppIcons.moderation,
          PhosphorIconsFill.notePencil,
          l10n.adminModeration,
          AppRoutes.expertContributionsName,
        ),
        _AdminDest(
          AppIcons.dictionary,
          AppIcons.dictionaryActive,
          l10n.adminSigns,
          AppRoutes.expertSignsName,
        ),
        _AdminDest(
          AppIcons.learning,
          AppIcons.learningActive,
          l10n.adminLearning,
          AppRoutes.expertLearningName,
        ),
      ],
    };
  }

  static String titleFor(Workspace workspace, AppLocalizations l10n) =>
      switch (workspace) {
        Workspace.admin => l10n.adminPanel,
        Workspace.teacher => l10n.teacherSpace,
        Workspace.expert => l10n.expertSpace,
      };

  static IconData iconFor(Workspace workspace) => switch (workspace) {
    Workspace.admin => AppIcons.admin,
    Workspace.teacher => PhosphorIconsRegular.chalkboardTeacher,
    Workspace.expert => PhosphorIconsRegular.sealCheck,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isWide = context.hasSideNavigation;
    final title = titleFor(workspace, l10n);
    final rolesLoading = ref.watch(currentUserRolesProvider).isLoading;
    final allowed = switch (workspace) {
      Workspace.admin => ref.watch(isAdminProvider),
      Workspace.teacher => ref.watch(isTeacherProvider),
      Workspace.expert => ref.watch(isSignExpertProvider),
    };

    if (!allowed) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: rolesLoading
            ? const Center(child: CircularProgressIndicator())
            : PageContainer.form(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      AppIcons.locked,
                      size: 56,
                      color: AppColors.warning,
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      l10n.adminAccessDenied,
                      style: AppTextStyles.h3,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      workspace == Workspace.admin
                          ? l10n.adminAccessDeniedMessage
                          : l10n.roleSpaceDeniedMessage,
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

    final destinations = _destinationsFor(workspace, l10n);
    void go(int index) => context.goNamed(destinations[index].routeName);

    if (isWide) {
      return Scaffold(
        body: Column(
          children: [
            AppNavBar(
              semanticLabel: title,
              brand: AppNavBrand(title: title, icon: iconFor(workspace)),
              selectedIndex: selectedIndex,
              onDestinationSelected: go,
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
        title: Text(title),
        leading: IconButton(
          tooltip: l10n.backToApp,
          icon: const Icon(AppIcons.back),
          onPressed: () => context.goNamed(AppRoutes.homeName),
        ),
      ),
      body: PageContainer(padding: 0, child: child),
      bottomNavigationBar: _MobileBottomBar(
        destinations: destinations,
        selectedIndex: selectedIndex,
        onSelected: go,
      ),
    );
  }
}

/// Phones show at most [_maxVisible] items; beyond that the first ones stay in
/// the bar and the rest move to a "Menu" item opening a sheet.
class _MobileBottomBar extends StatelessWidget {
  const _MobileBottomBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const int _maxVisible = 4;

  final List<_AdminDest> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final overflows = destinations.length > _maxVisible;
    final visibleCount = overflows ? _maxVisible - 1 : destinations.length;
    final menuIndex = visibleCount;
    final inMenu = overflows && selectedIndex >= visibleCount;

    return NavigationBar(
      selectedIndex: inMenu
          ? menuIndex
          : selectedIndex.clamp(0, visibleCount - 1),
      onDestinationSelected: (i) {
        if (overflows && i == menuIndex) {
          _openMenu(context, visibleCount);
        } else {
          onSelected(i);
        }
      },
      destinations: [
        for (final d in destinations.take(visibleCount))
          NavigationDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: d.label,
          ),
        if (overflows)
          NavigationDestination(
            icon: const Icon(AppIcons.list),
            selectedIcon: Icon(
              inMenu ? destinations[selectedIndex].selectedIcon : AppIcons.list,
            ),
            label: inMenu ? destinations[selectedIndex].label : l10n.navMenu,
          ),
      ],
    );
  }

  Future<void> _openMenu(BuildContext context, int firstHidden) {
    final l10n = AppLocalizations.of(context)!;
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (var i = firstHidden; i < destinations.length; i++)
              ListTile(
                leading: Icon(
                  i == selectedIndex
                      ? destinations[i].selectedIcon
                      : destinations[i].icon,
                ),
                title: Text(destinations[i].label),
                selected: i == selectedIndex,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onSelected(i);
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(AppIcons.back),
              title: Text(l10n.backToApp),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.goNamed(AppRoutes.homeName);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminDest {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String routeName;

  const _AdminDest(this.icon, this.selectedIcon, this.label, this.routeName);
}
