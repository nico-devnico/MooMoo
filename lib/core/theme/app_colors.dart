import 'package:flutter/material.dart';

/// White and deep blue palette.
///
/// One hue family carries the whole interface: a sapphire primary for actions,
/// a navy for text, and blue-tinted neutrals instead of grey so surfaces read
/// as intentional rather than washed out. Colours are applied flat — no
/// gradients anywhere in the product.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF1A56DB);
  static const Color primaryDeep = Color(0xFF0A2540);
  static const Color primarySoft = Color(0xFFEAF0FE);
  static const Color secondary = Color(0xFF4C8DFF);

  // Status
  static const Color error = Color(0xFFD92D20);
  static const Color success = Color(0xFF0E9F6E);
  static const Color warning = Color(0xFFD9820A);
  static const Color info = Color(0xFF1A56DB);

  // Light
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF7F9FD);
  static const Color neutralLight = Color(0xFFEEF3FC);
  static const Color borderLight = Color(0xFFE1E8F5);
  static const Color textPrimaryLight = Color(0xFF0A2540);
  static const Color textSecondaryLight = Color(0xFF5B6B85);

  // Dark
  static const Color backgroundDark = Color(0xFF070B14);
  static const Color surfaceDark = Color(0xFF0E1524);
  static const Color neutralDark = Color(0xFF182132);
  static const Color borderDark = Color(0xFF24304A);
  static const Color textPrimaryDark = Color(0xFFF5F8FF);
  static const Color textSecondaryDark = Color(0xFF9BABC7);

  static const Color overlay = Color(0x330A2540);

  /// Solid darker tones drawn under raised learning-path nodes: a flat ledge
  /// that makes them look pressable without a gradient or a blur.
  static const Color primaryLedge = Color(0xFF1240A8);
  static const Color successLedge = Color(0xFF0A7A55);
  static const Color warningLedge = Color(0xFFA86306);
  static const Color errorLedge = Color(0xFFA3221A);

  /// Reward colour of a mastered lesson, distinct from the warning orange.
  static const Color gold = Color(0xFFE8A800);
  static const Color goldLedge = Color(0xFFB07F00);

  static const Color successSoft = Color(0xFFE7F6F0);
  static const Color errorSoft = Color(0xFFFDECEA);
  static const Color warningSoft = Color(0xFFFDF3E4);

  /// Parses a `#RRGGBB` value stored in the database (e.g.
  /// `sign_categories.color_hex`). Malformed values return null so the caller
  /// falls back to the brand colour instead of failing.
  static Color? fromHex(String? hex) {
    if (hex == null) return null;
    final cleaned = hex.trim().replaceFirst('#', '');
    if (cleaned.length != 6) return null;
    final value = int.tryParse(cleaned, radix: 16);
    return value == null ? null : Color(0xFF000000 | value);
  }

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? surfaceDark : surfaceLight;

  static Color neutral(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? neutralDark : neutralLight;

  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? borderDark : borderLight;

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? textSecondaryDark
          : textSecondaryLight;
}
