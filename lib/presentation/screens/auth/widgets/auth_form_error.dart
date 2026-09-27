import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Inline error banner above an auth form.
///
/// Announced to screen readers as a live region so the failure is not silent
/// for users who cannot see the colour change.
class AuthFormError extends StatelessWidget {
  const AuthFormError({super.key, required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 20),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Text(
                  message!,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
