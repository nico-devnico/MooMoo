import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../settings/settings_screen.dart';

final DateTime _lastUpdated = DateTime(2026, 5, 21);

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    final sections = [
      (l10n.accountTermsAcceptTitle, l10n.accountTermsAcceptBody),
      (l10n.accountTermsUseTitle, l10n.accountTermsUseBody),
      (l10n.accountTermsIpTitle, l10n.accountTermsIpBody),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.termsOfService)),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: AppSpacing.l,
          bottom: settingsBottomPadding(context),
        ),
        child: PageContainer.reading(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(l10n.termsOfService, style: AppTextStyles.h2),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                l10n.accountLegalUpdated(DateFormat.yMMMMd(locale).format(_lastUpdated)),
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary(context)),
              ),
              const SizedBox(height: AppSpacing.xl),
              for (final section in sections)
                _LegalSection(title: section.$1, body: section.$2),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  const _LegalSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: AppTextStyles.h3),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(body, style: AppTextStyles.bodyMedium.copyWith(height: 1.6)),
        ],
      ),
    );
  }
}
