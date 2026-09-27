import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/providers/admin_provider.dart';
import '../../../domain/providers/app_settings_provider.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/profile_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_logo.dart';

/// Replaces the whole app with a maintenance page for everyone but admins.
///
/// The sign-in pages stay reachable so an admin can still log in and turn
/// maintenance off. Writes are refused server-side as well (RLS and API), so
/// this is only the visible half of the lock.
class MaintenanceGate extends ConsumerWidget {
  const MaintenanceGate({super.key, required this.router, required this.child});

  final GoRouter router;
  final Widget child;

  static const _openPaths = {
    AppRoutes.splash,
    AppRoutes.login,
    AppRoutes.forgotPassword,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider).value;
    if (settings == null || !settings.maintenanceEnabled) return child;

    final user = ref.watch(currentUserProvider);
    // Don't flash the lock at an admin whose profile is still loading.
    if (user != null && ref.watch(userProfileProvider).isLoading) return child;
    if (ref.watch(isAdminProvider)) return child;

    return ListenableBuilder(
      listenable: router.routerDelegate,
      builder: (context, _) {
        final path = router.routerDelegate.currentConfiguration.uri.path;
        if (user == null && _openPaths.contains(path)) return child;
        return _MaintenancePage(
          message: settings.maintenanceMessage,
          signedIn: user != null,
          onAdminLogin: () => router.go(AppRoutes.login),
          onSignOut: () => ref.read(authRepositoryProvider).signOut(),
        );
      },
    );
  }
}

class _MaintenancePage extends ConsumerWidget {
  const _MaintenancePage({
    required this.message,
    required this.signedIn,
    required this.onAdminLogin,
    required this.onSignOut,
  });

  final String? message;
  final bool signedIn;
  final VoidCallback onAdminLogin;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final appName = ref.watch(appNameProvider);
    final text = (message?.trim().isNotEmpty ?? false)
        ? message!.trim()
        : l10n.maintenanceDefaultMessage;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(width: 88, height: 88),
                  const SizedBox(height: AppSpacing.l),
                  Text(appName, style: AppTextStyles.h2),
                  const SizedBox(height: AppSpacing.xl),
                  Icon(AppIcons.settings, size: 40, color: AppColors.primary),
                  const SizedBox(height: AppSpacing.m),
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.maintenanceTitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.h3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  if (signedIn)
                    OutlinedButton.icon(
                      onPressed: onSignOut,
                      icon: Icon(AppIcons.logout),
                      label: Text(l10n.signOut),
                    )
                  else
                    TextButton(
                      onPressed: onAdminLogin,
                      child: Text(l10n.maintenanceAdminLogin),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
