import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Outlined provider button (Google, …) sized like [AppButton].
class OAuthButton extends StatelessWidget {
  const OAuthButton({
    super.key,
    required this.label,
    required this.assetName,
    required this.fallbackIcon,
    this.onTap,
  });

  final String label;
  final String assetName;
  final IconData fallbackIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    assetName,
                    height: 20,
                    width: 20,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(fallbackIcon, size: 22, color: AppColors.primary),
                  ),
                  const SizedBox(width: AppSpacing.s + AppSpacing.xs),
                  Flexible(
                    child: Text(
                      label,
                      style: AppTextStyles.bodyLarge.copyWith(fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
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
