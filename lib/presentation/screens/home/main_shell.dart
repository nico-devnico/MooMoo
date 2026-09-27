import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/providers/profile_provider.dart';
import '../../../domain/providers/app_settings_provider.dart';
import '../../widgets/app_nav_bar.dart';
import '../../widgets/profile_avatar_button.dart';
import '../../../l10n/app_localizations.dart';

/// Branch indices of the [StatefulShellRoute] declared in the router.
class _Branch {
  _Branch._();

  static const int home = 0;
  static const int translator = 1;
  static const int dictionary = 2;
  static const int learning = 3;
  static const int profile = 4;
}

/// Branches reachable from the navigation links, in display order. The
/// profile is opened from the avatar instead.
const _linkBranches = [
  _Branch.home,
  _Branch.dictionary,
  _Branch.learning,
  _Branch.translator,
];

List<NavBarDestination> _destinations(AppLocalizations l10n) => [
      NavBarDestination(
        icon: AppIcons.home,
        selectedIcon: AppIcons.homeActive,
        label: l10n.home,
      ),
      NavBarDestination(
        icon: AppIcons.dictionary,
        selectedIcon: AppIcons.dictionaryActive,
        label: l10n.dictionary,
      ),
      NavBarDestination(
        icon: AppIcons.learning,
        selectedIcon: AppIcons.learningActive,
        label: l10n.learning,
      ),
      NavBarDestination(
        icon: AppIcons.translate,
        selectedIcon: AppIcons.translateActive,
        label: l10n.translate,
      ),
    ];

class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  void _goBranch(int branch) {
    navigationShell.goBranch(
      branch,
      // Tapping the current tab again returns to its first page.
      initialLocation: branch == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch profile to force rebuild on locale/theme change
    ref.watch(userProfileProvider);

    if (context.hasTopNavigation) {
      return Scaffold(
        body: Column(
          children: [
            _MainNavBar(
              currentIndex: navigationShell.currentIndex,
              onBranchSelected: _goBranch,
            ),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _FloatingBottomBar(
        currentIndex: navigationShell.currentIndex,
        onBranchSelected: _goBranch,
      ),
    );
  }
}

/// Horizontal navigation used from the tablet breakpoint up.
class _MainNavBar extends ConsumerWidget {
  const _MainNavBar({
    required this.currentIndex,
    required this.onBranchSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onBranchSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return AppNavBar(
      semanticLabel: l10n.navigationMenu,
      centerDestinations: true,
      brand: AppNavBrand(
        title: ref.watch(appNameProvider),
        onTap: () => onBranchSelected(_Branch.home),
      ),
      selectedIndex: _linkBranches.indexOf(currentIndex),
      onDestinationSelected: (i) => onBranchSelected(_linkBranches[i]),
      destinations: _destinations(l10n),
      actions: [
        ProfileAvatarButton(
          selected: currentIndex == _Branch.profile,
          onTap: () => onBranchSelected(_Branch.profile),
        ),
      ],
    );
  }
}

/// Detached pill-shaped bottom bar with the same four links as the top bar.
class _FloatingBottomBar extends StatelessWidget {
  const _FloatingBottomBar({
    required this.currentIndex,
    required this.onBranchSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onBranchSelected;

  static const double _barHeight = 64;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final destinations = _destinations(l10n);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.m,
          0,
          AppSpacing.m,
          AppSpacing.m,
        ),
        child: Semantics(
          container: true,
          label: l10n.navigationMenu,
          child: Container(
            height: _barHeight,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(_barHeight / 2),
              border: Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDeep.withValues(
                    alpha: isDark ? 0.40 : 0.08,
                  ),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                for (var i = 0; i < destinations.length; i++)
                  _BottomNavItem(
                    icon: destinations[i].icon,
                    selectedIcon: destinations[i].selectedIcon,
                    label: destinations[i].label,
                    isSelected: currentIndex == _linkBranches[i],
                    onTap: () => onBranchSelected(_linkBranches[i]),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unselectedColor = theme.brightness == Brightness.light
        ? AppColors.textSecondaryLight
        : AppColors.textSecondaryDark;
    final color = isSelected ? AppColors.primary : unselectedColor;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.radiusCircular,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: kMinTouchTarget,
              minHeight: kMinTouchTarget,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isSelected ? selectedIcon : icon, size: 22, color: color),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
