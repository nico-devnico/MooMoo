import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/password_policy.dart';
import '../../../../l10n/app_localizations.dart';

/// Live checklist of the server-side password rules.
class PasswordRequirements extends StatelessWidget {
  const PasswordRequirements({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final rules = <(String, bool)>[
      (l10n.passwordRuleLength, PasswordPolicy.hasMinLength(password)),
      (l10n.passwordRuleLowercase, PasswordPolicy.hasLowercase(password)),
      (l10n.passwordRuleUppercase, PasswordPolicy.hasUppercase(password)),
      (l10n.passwordRuleDigit, PasswordPolicy.hasDigit(password)),
      (l10n.passwordRuleSymbol, PasswordPolicy.hasSymbol(password)),
    ];

    return Semantics(
      label: l10n.passwordRequirementsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.passwordRequirementsTitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.m,
            runSpacing: AppSpacing.xs,
            children: [
              for (final (label, met) in rules) _Rule(label: label, met: met),
            ],
          ),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final color = met ? AppColors.success : AppColors.textSecondaryLight;

    return Semantics(
      checked: met,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: color,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: color)),
        ],
      ),
    );
  }
}
