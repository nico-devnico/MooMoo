import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_text_styles.dart';

class AppEmptyState extends StatelessWidget {
  /// Keeps the message a readable line length on wide screens.
  static const double maxContentWidth = 420;

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
    final fallbackIcon = _IconBadge(icon: icon ?? AppIcons.empty);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bounded = constraints.hasBoundedHeight;
        final content = ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxContentWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imagePath != null)
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: bounded ? 200 : 160),
                  child: ExcludeSemantics(
                    child: isSvg
                        ? SvgPicture.asset(imagePath!, fit: BoxFit.contain)
                        : Image.asset(
                            imagePath!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => fallbackIcon,
                          ),
                  ),
                )
              else
                fallbackIcon,
              const SizedBox(height: AppSpacing.l),
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h3.copyWith(
                    color: isDark ? Colors.white : AppColors.neutralDark,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(color: secondary, height: 1.5),
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
        );

        final padded = Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: content,
        );

        if (!bounded) return Center(child: padded);
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: padded),
          ),
        );
      },
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;

  const _IconBadge({required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ExcludeSemantics(
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 40, color: AppColors.primary),
      ),
    );
  }
}
