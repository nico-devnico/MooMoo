import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AppEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String? imagePath;
  final bool isSvg;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  const AppEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.imagePath,
    this.isSvg = true,
    this.actionLabel,
    this.onAction,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bounded = constraints.hasBoundedHeight;
        return Container(
          width: double.infinity,
          height: bounded ? constraints.maxHeight : null,
          color: bounded
              ? (isDark ? const Color(0xFF09090B) : Colors.white)
              : Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
              children: [
                if (imagePath != null) ...[
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                      maxHeight: bounded
                          ? MediaQuery.of(context).size.height * 0.28
                          : 160,
                    ),
                    child: isSvg
                        ? SvgPicture.asset(imagePath!, fit: BoxFit.contain)
                        : Image.asset(
                            imagePath!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              icon ?? Icons.inbox_outlined,
                              size: 72,
                              color: AppColors.primary.withValues(alpha: 0.7),
                            ),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.l),
                ] else ...[
                  Icon(
                    icon ?? Icons.inbox_outlined,
                    size: 56,
                    color: AppColors.primary.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: AppSpacing.l),
                ],
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h3.copyWith(
                    color: isDark ? Colors.white : AppColors.neutralDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(color: secondary),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: AppSpacing.l),
                  FilledButton(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
