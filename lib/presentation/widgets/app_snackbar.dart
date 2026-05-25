import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_text_styles.dart';

enum AppSnackbarType { success, error, info, warning }

class AppSnackbar {
  AppSnackbar._();

  static void show(
    BuildContext context, {
    required String message,
    AppSnackbarType type = AppSnackbarType.info,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    scaffoldMessenger.clearSnackBars();
    
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_getIcon(type), color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: _getColor(type),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusM),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - (MediaQuery.of(context).padding.top + 100),
          left: 16,
          right: 16,
        ),
        duration: const Duration(seconds: 3),
        dismissDirection: DismissDirection.up,
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    show(context, message: message, type: AppSnackbarType.success);
  }

  static void showError(BuildContext context, String message) {
    show(context, message: message, type: AppSnackbarType.error);
  }

  static void showInfo(BuildContext context, String message) {
    show(context, message: message, type: AppSnackbarType.info);
  }

  static void showWarning(BuildContext context, String message) {
    show(context, message: message, type: AppSnackbarType.warning);
  }

  static Color _getColor(AppSnackbarType type) {
    switch (type) {
      case AppSnackbarType.success:
        return AppColors.success;
      case AppSnackbarType.error:
        return AppColors.error;
      case AppSnackbarType.info:
        return AppColors.info;
      case AppSnackbarType.warning:
        return AppColors.warning;
    }
  }

  static IconData _getIcon(AppSnackbarType type) {
    switch (type) {
      case AppSnackbarType.success:
        return Icons.check_circle_outline;
      case AppSnackbarType.error:
        return Icons.error_outline;
      case AppSnackbarType.info:
        return Icons.info_outline;
      case AppSnackbarType.warning:
        return Icons.warning_amber_outlined;
    }
  }
}
