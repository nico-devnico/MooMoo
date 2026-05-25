import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/providers/translator_provider.dart';
import '../../../domain/providers/stt_provider.dart';
import '../../../domain/providers/profile_provider.dart';
import '../../widgets/app_avatar.dart';
import '../../../l10n/app_localizations.dart';

class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 1000;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isTranslating = ref.watch(translatorStateProvider);
    final isListening = ref.watch(speechControllerProvider);
    final isActive = isTranslating || isListening;
    
    // Watch profile to force rebuild on locale/theme change
    ref.watch(userProfileProvider);

    if (isWide) {
      return Scaffold(
        appBar: _ModernTopBar(
          currentIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => navigationShell.goBranch(index),
        ),
        body: IconTheme(
          data: IconThemeData(
            color: AppColors.primary,
            size: 24,
          ),
          child: navigationShell,
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
          onPressed: () {
            final isOnTranslator = navigationShell.currentIndex == 1;
            
            if (!isOnTranslator) {
              // First click: navigate to translator
              navigationShell.goBranch(1);
              return;
            }
            
            // Second click (already on translator): toggle translation
            final mode = ref.read(translationModeStateProvider);
            
            if (isActive) {
              ref.read(translatorStateProvider.notifier).stop();
              ref.read(speechControllerProvider.notifier).stopListening();
            } else {
              if (mode == TranslationMode.signToText) {
                ref.read(translatorStateProvider.notifier).start();
              } else {
                // For Text-to-Sign mode, the FAB triggers speech recognition
                // The result handling will be synchronized via a shared state if needed,
                // but for now let's just trigger the start.
                // We'll use a specific method in TranslatorScreen or a shared provider.
                ref.read(speechControllerProvider.notifier).startListening(
                  onResult: (text) {
                    // This will be handled by listening to the speech result if we implement it.
                  },
                );
              }
            }
          },
          backgroundColor: isActive ? AppColors.error : AppColors.primary,
          elevation: 4,
          shape: const CircleBorder(),
          child: isActive 
            ? const Icon(Icons.stop, color: Colors.white, size: 32)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), duration: 600.ms)
            : const Icon(Icons.translate, color: Colors.white, size: 32),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 8,
        height: 70,
        color: theme.brightness == Brightness.light ? AppColors.surfaceLight : AppColors.surfaceDark,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BottomNavItem(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              label: l10n.home,
              isSelected: navigationShell.currentIndex == 0,
              onTap: () => navigationShell.goBranch(0),
            ),
            _BottomNavItem(
              icon: Icons.menu_book_outlined,
              selectedIcon: Icons.menu_book,
              label: l10n.dictionary,
              isSelected: navigationShell.currentIndex == 2,
              onTap: () => navigationShell.goBranch(2),
            ),
            const SizedBox(width: 48), // Space for notched FAB
            _BottomNavItem(
              icon: Icons.school_outlined,
              selectedIcon: Icons.school,
              label: l10n.learning,
              isSelected: navigationShell.currentIndex == 3,
              onTap: () => navigationShell.goBranch(3),
            ),
            _BottomNavItem(
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              label: l10n.profile,
              isSelected: navigationShell.currentIndex == 4,
              onTap: () => navigationShell.goBranch(4),
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

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? selectedIcon : icon,
            color: isSelected ? AppColors.primary : unselectedColor,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? AppColors.primary : unselectedColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernTopBar extends ConsumerWidget implements PreferredSizeWidget {
  final int currentIndex;
  final Function(int) onDestinationSelected;

  const _ModernTopBar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profileAsync = ref.watch(userProfileProvider);

    return Material(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Container(
        height: 70,
        color: isDark ? AppColors.surfaceDark : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Row(
          children: [
            // Logo
            Image.asset(
              'assets/images/logo.png',
              width: 32,
              height: 32,
            ),
            const SizedBox(width: AppSpacing.m),
            Text(
              'MooMoo',
              style: AppTextStyles.h3.copyWith(color: AppColors.primary),
            ),
            const Spacer(),
            // Navigation Items
            _TopNavItem(
              label: l10n.home,
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              isSelected: currentIndex == 0,
              onTap: () => onDestinationSelected(0),
            ),
            _TopNavItem(
              label: l10n.translate,
              icon: Icons.translate_outlined,
              selectedIcon: Icons.translate,
              isSelected: currentIndex == 1,
              onTap: () => onDestinationSelected(1),
            ),
            _TopNavItem(
              label: l10n.dictionary,
              icon: Icons.menu_book_outlined,
              selectedIcon: Icons.menu_book,
              isSelected: currentIndex == 2,
              onTap: () => onDestinationSelected(2),
            ),
            _TopNavItem(
              label: l10n.learning,
              icon: Icons.school_outlined,
              selectedIcon: Icons.school,
              isSelected: currentIndex == 3,
              onTap: () => onDestinationSelected(3),
            ),
            _TopNavItem(
              label: l10n.profile,
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              isSelected: currentIndex == 4,
              onTap: () => onDestinationSelected(4),
            ),
            const SizedBox(width: AppSpacing.l),
            // Profile Action with real Avatar
            profileAsync.when(
              data: (profile) => AppAvatar(
                imageUrl: profile?.avatarUrl,
                name: profile?.displayName,
                radius: 18,
              ),
              loading: () => CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, __) => CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: const Icon(Icons.person, color: AppColors.primary, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}

class _TopNavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TopNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unselectedColor = theme.brightness == Brightness.light 
        ? AppColors.textSecondaryLight 
        : AppColors.textSecondaryDark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? AppColors.primary : unselectedColor,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : unselectedColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
