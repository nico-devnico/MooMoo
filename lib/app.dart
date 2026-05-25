import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'domain/providers/profile_provider.dart';

class MooMooApp extends ConsumerWidget {
  const MooMooApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.value;
    
    final localeCode = profile?.locale ?? 'fr';
    
    ThemeMode themeMode = ThemeMode.system;
    if (profile?.theme == 'light') themeMode = ThemeMode.light;
    if (profile?.theme == 'dark') themeMode = ThemeMode.dark;

    return MaterialApp.router(
      key: ValueKey('app_locale_$localeCode'),
      title: 'MooMoo',
      debugShowCheckedModeBanner: false,
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
