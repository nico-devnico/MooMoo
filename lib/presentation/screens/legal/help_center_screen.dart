import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_panel.dart';
import '../settings/settings_screen.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final secondary = AppColors.textSecondary(context);

    final faqs = [
      (l10n.accountHelpTranslatorQ, l10n.accountHelpTranslatorA),
      (l10n.accountHelpLearningQ, l10n.accountHelpLearningA),
      (l10n.accountHelpSignLanguageQ, l10n.accountHelpSignLanguageA),
      (l10n.accountHelpFavoritesQ, l10n.accountHelpFavoritesA),
      (l10n.accountHelpProfileQ, l10n.accountHelpProfileA),
      (l10n.accountHelpAccessibilityQ, l10n.accountHelpAccessibilityA),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.helpCenter)),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: AppSpacing.l,
          bottom: settingsBottomPadding(context),
        ),
        child: PageContainer.reading(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                child: Text(
                  l10n.accountHelpIntro,
                  style: AppTextStyles.bodyMedium.copyWith(color: secondary),
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              AppButton(
                label: l10n.userGuide,
                icon: PhosphorIconsRegular.bookOpen,
                variant: AppButtonVariant.outline,
                onPressed: () => context.pushNamed(AppRoutes.userGuideName),
              ),
              const SizedBox(height: AppSpacing.m),
              AppPanel(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < faqs.length; i++) ...[
                      if (i > 0) Divider(height: 1, thickness: 1, color: AppColors.border(context)),
                      _FaqTile(question: faqs[i].$1, answer: faqs[i].$2),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SettingsIcon(PhosphorIconsRegular.lifebuoy),
                    const SizedBox(height: AppSpacing.m),
                    Semantics(
                      header: true,
                      child: Text(l10n.accountHelpContactTitle, style: AppTextStyles.h3),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.accountHelpContactBody,
                      style: AppTextStyles.bodyMedium.copyWith(color: secondary),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    AppButton(
                      label: l10n.accountHelpContactAction,
                      icon: PhosphorIconsRegular.envelopeSimple,
                      variant: AppButtonVariant.outline,
                      onPressed: () => openSupportEmail(context, subject: l10n.helpCenter),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      shape: const Border(),
      collapsedShape: const Border(),
      tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.xs),
      childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.m, 0, AppSpacing.m, AppSpacing.m),
      expandedAlignment: Alignment.centerLeft,
      title: Text(
        question,
        style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
      ),
      children: [
        Text(
          answer,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary(context),
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
