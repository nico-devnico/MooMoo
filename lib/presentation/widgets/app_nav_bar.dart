import 'package:flutter/material.dart';

import '../../core/layout/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// A single link of [AppNavBar].
class NavBarDestination {
  const NavBarDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Website-style horizontal navigation: brand on the left, links in the
/// middle, actions on the right.
///
/// Used instead of a navigation rail from the tablet breakpoint up so the app
/// reads like a site on a large screen. The links scroll horizontally rather
/// than overflow when the window gets narrow.
class AppNavBar extends StatelessWidget implements PreferredSizeWidget {
  const AppNavBar({
    super.key,
    required this.brand,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.actions = const [],
    this.semanticLabel,
  });

  final Widget brand;
  final List<NavBarDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<Widget> actions;
  final String? semanticLabel;

  static const double height = 72;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Icons crowd the links below the desktop breakpoint; labels alone stay
    // readable and keep every destination on one line.
    final showIcons = context.hasSideNavigation;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: Material(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.responsive(
                mobile: AppSpacing.m,
                tablet: AppSpacing.l,
                desktop: AppSpacing.xl,
              ),
            ),
            child: Row(
              children: [
                brand,
                const SizedBox(width: AppSpacing.xl),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var i = 0; i < destinations.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.xs),
                            child: _NavLink(
                              destination: destinations[i],
                              isSelected: i == selectedIndex,
                              showIcon: showIcons,
                              onTap: () => onDestinationSelected(i),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (actions.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.m),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final action in actions)
                        Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.s),
                          child: action,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({
    required this.destination,
    required this.isSelected,
    required this.showIcon,
    required this.onTap,
  });

  final NavBarDestination destination;
  final bool isSelected;
  final bool showIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isSelected
        ? AppColors.primary
        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);

    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusCircular,
        hoverColor: AppColors.primary.withValues(alpha: 0.06),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minHeight: kMinTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                    ? AppColors.primary.withValues(alpha: 0.16)
                    : AppColors.primarySoft)
                : Colors.transparent,
            borderRadius: AppRadius.radiusCircular,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIcon) ...[
                Icon(
                  isSelected ? destination.selectedIcon : destination.icon,
                  size: 20,
                  color: foreground,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                destination.label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: foreground,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Logo plus wordmark, shared by the app and admin navigation bars.
class AppNavBrand extends StatelessWidget {
  const AppNavBrand({
    super.key,
    required this.title,
    this.icon,
    this.onTap,
  });

  final String title;

  /// Replaces the logo asset, used by the admin bar.
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Icon(icon, size: 28, color: AppColors.primary)
        else
          Image.asset('assets/images/logo.png', width: 32, height: 32),
        const SizedBox(width: AppSpacing.s),
        Text(
          title,
          style: AppTextStyles.h3.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );

    if (onTap == null) return content;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.radiusM,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
        child: content,
      ),
    );
  }
}
