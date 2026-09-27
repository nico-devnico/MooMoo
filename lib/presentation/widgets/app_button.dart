import 'package:flutter/material.dart';
import '../../core/layout/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, outline, ghost }

class AppButton extends StatelessWidget {
  /// Height of every variant. Comfortably above the 48 px touch target floor.
  static const double height = 56;

  /// Beyond this, a single action button reads as a banner rather than a button.
  static const double desktopMaxWidth = 280;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;

  /// Stretch to the parent width. Honoured on mobile only; from the tablet
  /// breakpoint up the button is capped at [desktopMaxWidth].
  final bool fullWidth;

  /// Lifts the [desktopMaxWidth] cap. For buttons already inside a narrow
  /// container, such as an auth card, where the cap would leave a stray gap.
  final bool stretchOnLargeScreens;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
    this.stretchOnLargeScreens = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: 8),
          ],
          Text(label, style: AppTextStyles.button.copyWith(
            color: variant == AppButtonVariant.outline ? AppColors.primary : _getTextColor(theme),
          )),
        ],
      ],
    );

    final button = Semantics(
      button: true,
      enabled: !isLoading && onPressed != null,
      label: label,
      child: _buildButton(context, buttonContent),
    );

    if (!fullWidth) {
      return SizedBox(height: height, child: button);
    }

    if (context.isMobile || stretchOnLargeScreens) {
      return SizedBox(width: double.infinity, height: height, child: button);
    }

    // Large screens: fill the column, but never past a width where the button
    // stops reading as a button.
    return ConstrainedBox(
      constraints: const BoxConstraints.tightFor(
        width: desktopMaxWidth,
        height: height,
      ),
      child: button,
    );
  }

  Widget _buildButton(BuildContext context, Widget content) {
    switch (variant) {
      case AppButtonVariant.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          child: content,
        );
      case AppButtonVariant.secondary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          child: content,
        );
      case AppButtonVariant.outline:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.primary, width: 2),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusL),
          ),
          child: content,
        );
      case AppButtonVariant.ghost:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusL),
          ),
          child: content,
        );
    }
  }

  Color _getTextColor(ThemeData theme) {
    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.secondary:
        return Colors.white;
      case AppButtonVariant.outline:
      case AppButtonVariant.ghost:
        return AppColors.primary;
    }
  }
}
