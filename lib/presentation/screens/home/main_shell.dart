import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/providers/translator_provider.dart';
import '../../../domain/providers/stt_provider.dart';
import '../../../domain/providers/app_settings_provider.dart';
import '../../../domain/providers/camera_provider.dart';
import '../../widgets/app_logo.dart';
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

/// Branches reachable from the top bar links, in display order. On the top
/// bar the profile is opened from the avatar on the far right.
const _linkBranches = [
  _Branch.home,
  _Branch.dictionary,
  _Branch.learning,
  _Branch.translator,
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

  /// First press moves to the translator branch, a second one toggles the
  /// capture (camera inference or speech recognition depending on the mode).
  void _handleTranslateAction(WidgetRef ref, {required bool isActive}) {
    if (navigationShell.currentIndex != _Branch.translator) {
      navigationShell.goBranch(_Branch.translator);
      return;
    }

    if (isActive) {
      ref.read(translatorStateProvider.notifier).stop();
      ref.read(speechControllerProvider.notifier).stopListening();
      // Libère le capteur immédiatement (indicateur OS / LED Windows).
      unawaited(ref.read(cameraStateProvider.notifier).releaseCamera());
      return;
    }

    final mode = ref.read(translationModeStateProvider);
    if (mode == TranslationMode.signToText) {
      ref.read(translatorStateProvider.notifier).start();
    } else {
      // Results are picked up by the translator screen through sttResultProvider.
      ref.read(speechControllerProvider.notifier).startListening(
            onResult: (_) {},
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

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

    final isActive =
        ref.watch(translatorStateProvider) || ref.watch(speechControllerProvider);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _FloatingBottomBar(
        currentIndex: navigationShell.currentIndex,
        isActive: isActive,
        onDestinationSelected: _goBranch,
        onTranslateAction: () => _handleTranslateAction(ref, isActive: isActive),
        translateLabel: l10n.translate,
      ),
    );
  }
}

/// Horizontal navigation used from the tablet breakpoint up: brand on the
/// left, links centred, the user's photo on the far right.
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
      destinations: [
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
      ],
      actions: [
        ProfileAvatarButton(onTap: () => onBranchSelected(_Branch.profile)),
      ],
    );
  }
}

/// Detached pill-shaped bottom bar. The translate action is a circle that
/// rises a few pixels above the bar, but it shares the bar's colour, border
/// and shadow, so the lift reads as part of the same surface rather than as a
/// separate floating control. The mark on it is the app logo.
class _FloatingBottomBar extends StatelessWidget {
  const _FloatingBottomBar({
    required this.currentIndex,
    required this.isActive,
    required this.onDestinationSelected,
    required this.onTranslateAction,
    required this.translateLabel,
  });

  final int currentIndex;
  final bool isActive;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onTranslateAction;
  final String translateLabel;

  static const double _barHeight = 64;
  static const double _buttonSize = 62;

  /// How far the button rises above the bar. Small on purpose: enough to be
  /// raised, not enough to read as a control breaking out of the bar.
  static const double _lift = 8;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.m,
          0,
          AppSpacing.m,
          AppSpacing.m,
        ),
        child: SizedBox(
          height: _barHeight + _lift,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
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
                    _BottomNavItem(
                      icon: AppIcons.home,
                      selectedIcon: AppIcons.homeActive,
                      label: l10n.home,
                      isSelected: currentIndex == _Branch.home,
                      onTap: () => onDestinationSelected(_Branch.home),
                    ),
                    _BottomNavItem(
                      icon: AppIcons.dictionary,
                      selectedIcon: AppIcons.dictionaryActive,
                      label: l10n.dictionary,
                      isSelected: currentIndex == _Branch.dictionary,
                      onTap: () => onDestinationSelected(_Branch.dictionary),
                    ),
                    const SizedBox(width: _buttonSize),
                    _BottomNavItem(
                      icon: AppIcons.learning,
                      selectedIcon: AppIcons.learningActive,
                      label: l10n.learning,
                      isSelected: currentIndex == _Branch.learning,
                      onTap: () => onDestinationSelected(_Branch.learning),
                    ),
                    _BottomNavItem(
                      icon: AppIcons.profile,
                      selectedIcon: AppIcons.profileActive,
                      label: l10n.profile,
                      isSelected: currentIndex == _Branch.profile,
                      onTap: () => onDestinationSelected(_Branch.profile),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                child: _TranslateButton(
                  size: _buttonSize,
                  isActive: isActive,
                  label: translateLabel,
                  onTap: onTranslateAction,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TranslateButton extends StatelessWidget {
  const _TranslateButton({
    required this.size,
    required this.isActive,
    required this.label,
    required this.onTap,
  });

  final double size;
  final bool isActive;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: surface,
            // Idle, the circle is the same colour as the bar and carries the
            // same shadow, so the few pixels it rises go unnoticed. While a
            // capture is running the ring is the only signal, and it has to
            // stand on its own because nothing is announced by sound.
            border: isActive
                ? Border.all(color: AppColors.error, width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDeep.withValues(
                  alpha: isDark ? 0.40 : 0.06,
                ),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: size,
                height: size,
                child: const Padding(
                  padding: EdgeInsets.all(5),
                  child: ClipOval(
                    child: AppLogo(
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
              ),
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
