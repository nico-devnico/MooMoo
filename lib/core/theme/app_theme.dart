import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_radius.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceLight,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimaryLight,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: TextTheme(
        headlineLarge: AppTextStyles.h1.copyWith(color: AppColors.textPrimaryLight),
        headlineMedium: AppTextStyles.h2.copyWith(color: AppColors.textPrimaryLight),
        headlineSmall: AppTextStyles.h3.copyWith(color: AppColors.textPrimaryLight),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimaryLight),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimaryLight),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryLight),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        centerTitle: true,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.primary,
        size: 24,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: AppTextStyles.button,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusL),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppRadius.radiusL,
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusL,
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusL,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        selectedColor: AppColors.primarySoft,
        backgroundColor: AppColors.surfaceLight,
        labelStyle: AppTextStyles.bodySmall,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusCircular),
        side: const BorderSide(color: AppColors.borderLight),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            );
          }
          return AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryLight);
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusM),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusL,
          side: const BorderSide(color: AppColors.borderLight),
        ),
      ),
      bottomAppBarTheme: const BottomAppBarThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceDark,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimaryDark,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: TextTheme(
        headlineLarge: AppTextStyles.h1.copyWith(color: AppColors.textPrimaryDark),
        headlineMedium: AppTextStyles.h2.copyWith(color: AppColors.textPrimaryDark),
        headlineSmall: AppTextStyles.h3.copyWith(color: AppColors.textPrimaryDark),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimaryDark),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimaryDark),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryDark),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        centerTitle: true,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.primary,
        size: 24,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: AppTextStyles.button,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusL),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.neutralDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppRadius.radiusL,
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusL,
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusL,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        backgroundColor: AppColors.neutralDark,
        labelStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimaryDark),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusCircular),
        side: BorderSide.none,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: AppColors.primary.withValues(alpha: 0.2),
        backgroundColor: AppColors.surfaceDark,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusM),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusL,
          side: const BorderSide(color: AppColors.borderDark),
        ),
      ),
      bottomAppBarTheme: const BottomAppBarThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
      ),
    );
  }
}
