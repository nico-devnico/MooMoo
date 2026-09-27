import 'package:flutter/material.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../settings/settings_screen.dart';

class _GuideSection {
  const _GuideSection({
    required this.title,
    required this.intro,
    required this.steps,
    this.numbered = true,
  });

  final String title;
  final String intro;

  /// One step per line in the ARB value.
  final String steps;
  final bool numbered;
}

/// A plain, readable guide: one column of sections, each with a short
/// introduction and its steps.
class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({super.key});

  List<_GuideSection> _sections(AppLocalizations l10n) => [
        _GuideSection(
          title: l10n.guideAccountTitle,
          intro: l10n.guideAccountIntro,
          steps: l10n.guideAccountSteps,
        ),
        _GuideSection(
          title: l10n.guideLoginTitle,
          intro: l10n.guideLoginIntro,
          steps: l10n.guideLoginSteps,
        ),
        _GuideSection(
          title: l10n.guideNavigationTitle,
          intro: l10n.guideNavigationIntro,
          steps: l10n.guideNavigationSteps,
          numbered: false,
        ),
        _GuideSection(
          title: l10n.guideTranslateTitle,
          intro: l10n.guideTranslateIntro,
          steps: l10n.guideTranslateSteps,
        ),
        _GuideSection(
          title: l10n.guideDictionaryTitle,
          intro: l10n.guideDictionaryIntro,
          steps: l10n.guideDictionarySteps,
        ),
        _GuideSection(
          title: l10n.guideLearningTitle,
          intro: l10n.guideLearningIntro,
          steps: l10n.guideLearningSteps,
        ),
        _GuideSection(
          title: l10n.guideProfileTitle,
          intro: l10n.guideProfileIntro,
          steps: l10n.guideProfileSteps,
        ),
        _GuideSection(
          title: l10n.guideHistoryTitle,
          intro: l10n.guideHistoryIntro,
          steps: l10n.guideHistorySteps,
        ),
        _GuideSection(
          title: l10n.guideSettingsTitle,
          intro: l10n.guideSettingsIntro,
          steps: l10n.guideSettingsSteps,
          numbered: false,
        ),
        _GuideSection(
          title: l10n.guideRolesTitle,
          intro: l10n.guideRolesIntro,
          steps: l10n.guideRolesSteps,
          numbered: false,
        ),
        _GuideSection(
          title: l10n.guideErrorsTitle,
          intro: l10n.guideErrorsIntro,
          steps: l10n.guideErrorsSteps,
          numbered: false,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final secondary = AppColors.textSecondary(context);
    final sections = _sections(l10n);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.userGuide)),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: AppSpacing.l,
          bottom: settingsBottomPadding(context),
        ),
        child: PageContainer.reading(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.guideHeroBody,
                style: AppTextStyles.bodyLarge.copyWith(color: secondary, height: 1.5),
              ),
              for (final section in sections) ...[
                const SizedBox(height: AppSpacing.l),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.l),
                _GuideSectionView(section: section),
              ],
              const SizedBox(height: AppSpacing.l),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.l),
              Text(
                l10n.guideMoreHelpBody,
                style: AppTextStyles.bodyMedium.copyWith(color: secondary, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideSectionView extends StatelessWidget {
  const _GuideSectionView({required this.section});

  final _GuideSection section;

  @override
  Widget build(BuildContext context) {
    final steps = section.steps
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final body = AppTextStyles.bodyMedium.copyWith(height: 1.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(section.title, style: AppTextStyles.h3),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          section.intro,
          style: body.copyWith(color: AppColors.textSecondary(context)),
        ),
        const SizedBox(height: AppSpacing.s),
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: Text(section.numbered ? '${i + 1}.' : '•', style: body),
                ),
                Expanded(child: Text(steps[i], style: body)),
              ],
            ),
          ),
      ],
    );
  }
}
