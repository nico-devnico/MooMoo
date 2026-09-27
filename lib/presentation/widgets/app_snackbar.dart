import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_text_styles.dart';

enum AppSnackbarType { success, error, info, warning }

class AppSnackbar {
  AppSnackbar._();

  /// Past this screen width the snackbar stops spanning the viewport.
  static const double _wideBreakpoint = 600;
  static const double _wideWidth = 440;

  static void show(
    BuildContext context, {
    required String message,
    AppSnackbarType type = AppSnackbarType.info,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;

    scaffoldMessenger.clearSnackBars();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            ExcludeSemantics(
              child: Icon(_getIcon(type), color: Colors.white, size: 22),
            ),
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
        width: isWide ? _wideWidth : null,
        margin: isWide ? null : const EdgeInsets.fromLTRB(16, 0, 16, 16),
        // Errors stay longer so they can be read without hearing an alert sound.
        duration: Duration(seconds: type == AppSnackbarType.error ? 6 : 4),
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
        return AppColors.successLedge;
      case AppSnackbarType.error:
        return AppColors.error;
      case AppSnackbarType.info:
        return AppColors.primaryDeep;
      case AppSnackbarType.warning:
        return AppColors.warningLedge;
    }
  }

  static IconData _getIcon(AppSnackbarType type) {
    switch (type) {
      case AppSnackbarType.success:
        return AppIcons.success;
      case AppSnackbarType.error:
        return AppIcons.error;
      case AppSnackbarType.info:
        return AppIcons.info;
      case AppSnackbarType.warning:
        return AppIcons.warning;
    }
  }
}
