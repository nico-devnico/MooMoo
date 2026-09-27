import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'domain/providers/app_settings_provider.dart';
import 'domain/providers/profile_provider.dart';
import 'presentation/screens/maintenance/maintenance_gate.dart';

class MooMooApp extends ConsumerWidget {
  const MooMooApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.value;
    
    final localeCode = profile?.locale ?? 'fr';
    
    // The white and blue identity is the default; following the OS is opt-in
    // through the settings screen, otherwise the light theme never shows on a
    // machine that prefers dark.
    final themeMode = switch (profile?.theme) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };

    return MaterialApp.router(
      key: ValueKey('app_locale_$localeCode'),
      title: ref.watch(appNameProvider),
      debugShowCheckedModeBanner: false,
      builder: (context, child) => MaintenanceGate(
        router: router,
        child: child ?? const SizedBox.shrink(),
      ),
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      locale: Locale(localeCode),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
