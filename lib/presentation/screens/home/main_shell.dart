import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/providers/translator_provider.dart';
import '../../../domain/providers/stt_provider.dart';
import '../../../domain/providers/profile_provider.dart';
import '../../widgets/app_avatar.dart';
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

class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isTranslating = ref.watch(translatorStateProvider);
    final isListening = ref.watch(speechControllerProvider);
    final isActive = isTranslating || isListening;

    // Watch profile to force rebuild on locale/theme change
    ref.watch(userProfileProvider);

    if (context.hasSideNavigation) {
      return Scaffold(
        body: Row(
          children: [
            _MainNavigationRail(
              currentIndex: navigationShell.currentIndex,
              extended: context.hasExtendedSideNavigation,
              isActive: isActive,
              onDestinationSelected: navigationShell.goBranch,
              onTranslateAction: () =>
                  _handleTranslateAction(ref, isActive: isActive),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              child: IconTheme(
                data: const IconThemeData(color: AppColors.primary, size: 24),
                child: navigationShell,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        width: 70,
        height: 70,
        child: FloatingActionButton(
          tooltip: l10n.translate,
          onPressed: () => _handleTranslateAction(ref, isActive: isActive),
          backgroundColor: isActive ? AppColors.error : AppColors.primary,
          elevation: 4,
          shape: const CircleBorder(),
          child: isActive
              ? const Icon(Icons.stop, color: Colors.white, size: 32)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.15, 1.15),
                    duration: 600.ms,
                  )
              : const Icon(Icons.translate, color: Colors.white, size: 32),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 8,
        height: 70,
        color: theme.brightness == Brightness.light
            ? AppColors.surfaceLight
            : AppColors.surfaceDark,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BottomNavItem(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              label: l10n.home,
              isSelected: navigationShell.currentIndex == _Branch.home,
              onTap: () => navigationShell.goBranch(_Branch.home),
            ),
            _BottomNavItem(
              icon: Icons.menu_book_outlined,
              selectedIcon: Icons.menu_book,
              label: l10n.dictionary,
              isSelected: navigationShell.currentIndex == _Branch.dictionary,
              onTap: () => navigationShell.goBranch(_Branch.dictionary),
            ),
            const SizedBox(width: 48), // Space for notched FAB
            _BottomNavItem(
              icon: Icons.school_outlined,
              selectedIcon: Icons.school,
              label: l10n.learning,
              isSelected: navigationShell.currentIndex == _Branch.learning,
              onTap: () => navigationShell.goBranch(_Branch.learning),
            ),
            _BottomNavItem(
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              label: l10n.profile,
              isSelected: navigationShell.currentIndex == _Branch.profile,
              onTap: () => navigationShell.goBranch(_Branch.profile),
            ),
          ],
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

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: kMinTouchTarget,
            minHeight: kMinTouchTarget,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? AppColors.primary : unselectedColor,
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? AppColors.primary : unselectedColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Side navigation used from the desktop breakpoint up. Replaces the bottom
/// bar and the floating action button without changing any route.
class _MainNavigationRail extends ConsumerWidget {
  final int currentIndex;
  final bool extended;
  final bool isActive;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onTranslateAction;

  const _MainNavigationRail({
    required this.currentIndex,
    required this.extended,
    required this.isActive,
    required this.onDestinationSelected,
    required this.onTranslateAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider);

    final destinations = <NavigationRailDestination>[
      NavigationRailDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home),
        label: Text(l10n.home),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.translate_outlined),
        selectedIcon: const Icon(Icons.translate),
        label: Text(l10n.translate),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.menu_book_outlined),
        selectedIcon: const Icon(Icons.menu_book),
        label: Text(l10n.dictionary),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.school_outlined),
        selectedIcon: const Icon(Icons.school),
        label: Text(l10n.learning),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.person_outline),
        selectedIcon: const Icon(Icons.person),
        label: Text(l10n.profile),
      ),
    ];

    return Semantics(
      container: true,
      label: l10n.navigationMenu,
      child: NavigationRail(
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        extended: extended,
        minWidth: 80,
        minExtendedWidth: 220,
        labelType: extended ? null : NavigationRailLabelType.all,
        backgroundColor: theme.colorScheme.surface,
        destinations: destinations,
        leading: Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.l,
            bottom: AppSpacing.m,
          ),
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/logo.png', width: 32, height: 32),
                  if (extended) ...[
                    const SizedBox(width: AppSpacing.s),
                    Text(
                      'MooMoo',
                      style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.l),
              if (extended)
                FloatingActionButton.extended(
                  heroTag: 'rail_translate',
                  onPressed: onTranslateAction,
                  backgroundColor:
                      isActive ? AppColors.error : AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  icon: Icon(isActive ? Icons.stop : Icons.translate),
                  label: Text(isActive ? l10n.stopTranslation : l10n.translate),
                )
              else
                FloatingActionButton(
                  heroTag: 'rail_translate',
                  tooltip: l10n.translate,
                  onPressed: onTranslateAction,
                  backgroundColor:
                      isActive ? AppColors.error : AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  child: Icon(isActive ? Icons.stop : Icons.translate),
                ),
            ],
          ),
        ),
        trailing: Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.l),
              child: profileAsync.when(
                data: (profile) => AppAvatar(
                  imageUrl: profile?.avatarUrl,
                  name: profile?.displayName,
                  radius: 18,
                ),
                loading: () => CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (_, _) => CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: 20,
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
