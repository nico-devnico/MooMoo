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

class _GuideSection {
  const _GuideSection({
    required this.icon,
    required this.title,
    required this.intro,
    required this.steps,
    this.color = AppColors.primary,
    this.bullets = false,
    this.routeName,
    this.push = false,
  });

  final IconData icon;
  final String title;
  final String intro;

  /// One step per line in the ARB value.
  final String steps;
  final Color color;
  final bool bullets;
  final String? routeName;

  /// Tab destinations use `goNamed`; nested pages are pushed.
  final bool push;
}

class UserGuideScreen extends StatefulWidget {
  const UserGuideScreen({super.key});

  @override
  State<UserGuideScreen> createState() => _UserGuideScreenState();
}

class _UserGuideScreenState extends State<UserGuideScreen> {
  final _keys = <int, GlobalKey>{};

  GlobalKey _keyFor(int index) => _keys.putIfAbsent(index, GlobalKey.new);

  List<_GuideSection> _sections(AppLocalizations l10n) => [
        _GuideSection(
          icon: PhosphorIconsRegular.userPlus,
          title: l10n.guideAccountTitle,
          intro: l10n.guideAccountIntro,
          steps: l10n.guideAccountSteps,
        ),
        _GuideSection(
          icon: PhosphorIconsRegular.signIn,
          title: l10n.guideLoginTitle,
          intro: l10n.guideLoginIntro,
          steps: l10n.guideLoginSteps,
        ),
        _GuideSection(
          icon: PhosphorIconsRegular.compass,
          title: l10n.guideNavigationTitle,
          intro: l10n.guideNavigationIntro,
          steps: l10n.guideNavigationSteps,
          bullets: true,
        ),
        _GuideSection(
          icon: PhosphorIconsRegular.translate,
          title: l10n.guideTranslateTitle,
          intro: l10n.guideTranslateIntro,
          steps: l10n.guideTranslateSteps,
          routeName: AppRoutes.translatorName,
        ),
        _GuideSection(
          icon: PhosphorIconsRegular.books,
          title: l10n.guideDictionaryTitle,
          intro: l10n.guideDictionaryIntro,
          steps: l10n.guideDictionarySteps,
          routeName: AppRoutes.dictionaryName,
        ),
        _GuideSection(
          icon: PhosphorIconsRegular.graduationCap,
          title: l10n.guideLearningTitle,
          intro: l10n.guideLearningIntro,
          steps: l10n.guideLearningSteps,
          routeName: AppRoutes.learningName,
        ),
        _GuideSection(
          icon: PhosphorIconsRegular.userCircle,
          title: l10n.guideProfileTitle,
          intro: l10n.guideProfileIntro,
          steps: l10n.guideProfileSteps,
          routeName: AppRoutes.editProfileName,
          push: true,
        ),
        _GuideSection(
          icon: PhosphorIconsRegular.clockCounterClockwise,
          title: l10n.guideHistoryTitle,
          intro: l10n.guideHistoryIntro,
          steps: l10n.guideHistorySteps,
          routeName: AppRoutes.historyName,
          push: true,
        ),
        _GuideSection(
          icon: PhosphorIconsRegular.gear,
          title: l10n.guideSettingsTitle,
          intro: l10n.guideSettingsIntro,
          steps: l10n.guideSettingsSteps,
          bullets: true,
          routeName: AppRoutes.settingsName,
          push: true,
        ),
        _GuideSection(
          icon: PhosphorIconsRegular.users,
          title: l10n.guideRolesTitle,
          intro: l10n.guideRolesIntro,
          steps: l10n.guideRolesSteps,
          bullets: true,
        ),
        _GuideSection(
          icon: PhosphorIconsRegular.warningCircle,
          title: l10n.guideErrorsTitle,
          intro: l10n.guideErrorsIntro,
          steps: l10n.guideErrorsSteps,
          color: AppColors.warning,
          bullets: true,
        ),
      ];

  void _scrollTo(int index) {
    final target = _keys[index]?.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sections = _sections(l10n);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.userGuide)),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: AppSpacing.l,
          bottom: settingsBottomPadding(context),
        ),
        child: PageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GuideHero(l10n: l10n),
              const SizedBox(height: AppSpacing.l),
              Semantics(
                header: true,
                child: Text(l10n.guideContents, style: AppTextStyles.h3),
              ),
              const SizedBox(height: AppSpacing.s),
              Wrap(
                spacing: AppSpacing.s,
                runSpacing: AppSpacing.s,
                children: [
                  for (var i = 0; i < sections.length; i++)
                    ActionChip(
                      avatar: Icon(sections[i].icon, size: 18, color: sections[i].color),
                      label: Text(sections[i].title),
                      onPressed: () => _scrollTo(i),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900 ? 2 : 1;
                  final width = columns == 1
                      ? constraints.maxWidth
                      : (constraints.maxWidth - AppSpacing.l) / 2;
                  return Wrap(
                    spacing: AppSpacing.l,
                    runSpacing: AppSpacing.l,
                    children: [
                      for (var i = 0; i < sections.length; i++)
                        SizedBox(
                          key: _keyFor(i),
                          width: width,
                          child: _GuideCard(section: sections[i], index: i + 1),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              AppPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SettingsIcon(PhosphorIconsRegular.lifebuoy),
                    const SizedBox(height: AppSpacing.m),
                    Text(l10n.guideMoreHelpTitle, style: AppTextStyles.h3),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.guideMoreHelpBody,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    AppButton(
                      label: l10n.helpCenter,
                      icon: PhosphorIconsRegular.question,
                      variant: AppButtonVariant.outline,
                      onPressed: () => context.pushNamed(AppRoutes.helpCenterName),
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

class _GuideHero extends StatelessWidget {
  const _GuideHero({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SettingsIcon(PhosphorIconsRegular.bookOpen, circle: true),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(l10n.guideHeroTitle, style: AppTextStyles.h2),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.guideHeroBody,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary(context),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.section, required this.index});

  final _GuideSection section;
  final int index;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final secondary = AppColors.textSecondary(context);
    final steps = section.steps
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SettingsIcon(section.icon, color: section.color),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(section.title, style: AppTextStyles.h3),
                ),
              ),
              Text(
                index.toString().padLeft(2, '0'),
                style: AppTextStyles.bodySmall.copyWith(color: secondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            section.intro,
            style: AppTextStyles.bodyMedium.copyWith(color: secondary, height: 1.5),
          ),
          const SizedBox(height: AppSpacing.m),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StepMarker(
                    label: section.bullets ? null : '${i + 1}',
                    color: section.color,
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          if (section.routeName != null) ...[
            const SizedBox(height: AppSpacing.s),
            AppButton(
              label: l10n.guideOpen(section.title),
              icon: PhosphorIconsRegular.arrowRight,
              variant: AppButtonVariant.outline,
              onPressed: () => section.push
                  ? context.pushNamed(section.routeName!)
                  : context.goNamed(section.routeName!),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepMarker extends StatelessWidget {
  const _StepMarker({required this.label, required this.color});

  final String? label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (label == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8, left: 6, right: 6),
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      );
    }
    return Container(
      width: 22,
      height: 22,
      margin: const EdgeInsets.only(top: 1),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Text(
        label!,
        style: AppTextStyles.bodySmall.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
