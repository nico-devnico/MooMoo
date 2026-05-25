import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Palette
  static const Color primary = Color(0xFF5B6BF8);
  static const Color secondary = Color(0xFF00C6AE);
  
  // Status Colors
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFA000);
  static const Color info = Color(0xFF1976D2);

  // Neutral Palette - Light
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF4F4F8);
  static const Color neutralLight = Color(0xFFF4F4F8);
  static const Color textPrimaryLight = Color(0xFF1C1C2E);
  static const Color textSecondaryLight = Color(0xFF6E6E80);

  // Neutral Palette - Dark
  static const Color backgroundDark = Color(0xFF09090B); // Zinc 950
  static const Color surfaceDark = Color(0xFF121217);    // Zinc 900 custom
  static const Color neutralDark = Color(0xFF1E1E24);    // Zinc 800 custom
  static const Color textPrimaryDark = Color(0xFFFAFAFA); // Zinc 50
  static const Color textSecondaryDark = Color(0xFFA1A1AA); // Zinc 400

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color overlay = Color(0x33000000); // 20% semi-transparent
}
