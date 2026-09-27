import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/learning.dart';
import '../../../data/models/sign_category.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/learning_provider.dart';
import '../../../domain/providers/notification_provider.dart';
import '../../../domain/providers/profile_provider.dart';
import '../../../domain/providers/sign_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/app_panel.dart';
import '../../widgets/skeletons.dart';
import '../learning/widgets/learning_widgets.dart';

/// Vertical rhythm between landing sections.
const double _sectionGap = AppSpacing.xxxl;

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref
              ..invalidate(learnerSummaryProvider)
              ..invalidate(unreadNotificationsCountProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              top: AppSpacing.l,
              bottom: AppSpacing.xxxl + AppSpacing.xl,
            ),
            child: const PageContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HomeTopBar(),
                  SizedBox(height: AppSpacing.l),
                  _Hero(),
                  SizedBox(height: _sectionGap),
                  _WaysSection(),
                  SizedBox(height: _sectionGap),
                  _LearningSection(),
                  _CategoriesSection(),
                  _ForEveryoneSection(),
                  SizedBox(height: _sectionGap),
                  _ContributionBanner(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeTopBar extends ConsumerWidget {
  const _HomeTopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(userProfileProvider);
    final unread = ref.watch(unreadNotificationsCountProvider).value ?? 0;

    final name = profile.value?.displayName ??
        user?.email?.split('@').first ??
        l10n.guest;

    return Row(
      children: [
        Expanded(
          child: profile.isLoading && !profile.hasValue
              ? const Skeleton(child: Align(
                  alignment: Alignment.centerLeft,
                  child: SkeletonBlock(width: 180, height: 22),
                ))
              : Text(
                  l10n.greeting(name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.h3,
                ),
        ),
        IconButton(
          tooltip: unread > 0 ? '${l10n.homeNotifications} ($unread)' : l10n.homeNotifications,
          onPressed: () => context.pushNamed(AppRoutes.notificationsName),
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text('$unread'),
            child: const Icon(AppIcons.notification),
          ),
        ),
        IconButton(
          tooltip: l10n.settings,
          onPressed: () => context.pushNamed(AppRoutes.settingsName),
          icon: const Icon(AppIcons.settings),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isWide = context.hasSideNavigation;

    final actions = Wrap(
      spacing: AppSpacing.m,
      runSpacing: AppSpacing.m,
      children: [
        AppButton(
          label: l10n.homeTranslateNow,
          icon: AppIcons.translate,
          fullWidth: context.isMobile,
          onPressed: () => context.goNamed(AppRoutes.translatorName),
        ),
        AppButton(
          label: l10n.homeContinueLearning,
          icon: AppIcons.learning,
          variant: AppButtonVariant.outline,
          fullWidth: context.isMobile,
          onPressed: () => context.goNamed(AppRoutes.learningName),
        ),
      ],
    );

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.homeHeroTitle,
            style: (isWide ? AppTextStyles.h1.copyWith(fontSize: 44) : AppTextStyles.h1)
                .copyWith(height: 1.15),
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        Text(
          l10n.homeHeroSubtitle,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary(context),
            fontWeight: FontWeight.w400,
            fontSize: isWide ? 18 : 16,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        actions,
      ],
    );

    if (!isWide) return text;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 6,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: text,
          ),
        ),
        const SizedBox(width: AppSpacing.xxl),
        const Expanded(flex: 5, child: _HeroVisual()),
      ],
    );
  }
}

/// Brand panel next to the hero text on large screens: the app mark and the
/// three things MooMoo does, drawn flat.
class _HeroVisual extends StatelessWidget {
  const _HeroVisual();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: 1.15,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: AppRadius.radiusXL,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderLight),
                ),
                padding: const EdgeInsets.all(AppSpacing.m),
                child: const ClipOval(child: AppLogo(fit: BoxFit.cover)),
              ),
              const SizedBox(height: AppSpacing.xl),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.s,
                runSpacing: AppSpacing.s,
                children: [
                  _HeroChip(icon: AppIcons.camera, label: l10n.signToText),
                  _HeroChip(icon: AppIcons.keyboard, label: l10n.textToSign),
                  _HeroChip(icon: AppIcons.learning, label: l10n.learning),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppRadius.radiusCircular,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.s),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle, this.action});

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(header: true, child: Text(title, style: AppTextStyles.h2)),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle!,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context)),
                ),
              ],
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}

class _WaysSection extends StatelessWidget {
  const _WaysSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cards = [
      _FeatureCard(
        icon: AppIcons.camera,
        title: l10n.signToText,
        body: l10n.homeSignToTextDesc,
        cta: l10n.homeOpen,
        onTap: () => context.goNamed(AppRoutes.translatorName),
      ),
      _FeatureCard(
        icon: AppIcons.keyboard,
        title: l10n.textToSign,
        body: l10n.homeTextToSignDesc,
        cta: l10n.homeOpen,
        onTap: () => context.goNamed(AppRoutes.translatorName),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(title: l10n.homeWaysTitle),
        const SizedBox(height: AppSpacing.l),
        if (context.isMobile)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [cards[0], const SizedBox(height: AppSpacing.m), cards[1]],
          )
        else
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: AppSpacing.l),
                Expanded(child: cards[1]),
              ],
            ),
          ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.cta,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final String cta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      onTap: onTap,
      semanticLabel: '$title. $body',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: AppRadius.radiusM,
              ),
              child: Icon(icon, color: AppColors.primary, size: 26),
            ),
            const SizedBox(height: AppSpacing.l),
            Text(title, style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.s),
            Text(
              body,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context)),
            ),
            const SizedBox(height: AppSpacing.l),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cta,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                const Icon(AppIcons.forward, size: 16, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LearningSection extends ConsumerWidget {
  const _LearningSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summaryAsync = ref.watch(learnerSummaryProvider);

    final Widget content = summaryAsync.when(
      data: (summary) => _LearningStrip(summary: summary),
      loading: () => const Skeleton(
        child: SkeletonBlock(height: 108, radius: AppRadius.l),
      ),
      // Le résumé est un bonus sur l'accueil : en cas d'échec, la section
      // s'efface au lieu d'afficher une erreur au milieu de la page.
      error: (_, _) => const SizedBox.shrink(),
    );

    if (summaryAsync.hasError) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: _sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(
            title: l10n.homeLearningTitle,
            subtitle: l10n.homeLearningSubtitle,
            action: TextButton(
              onPressed: () => context.goNamed(AppRoutes.learningName),
              child: Text(l10n.homeContinueLearning),
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          content,
        ],
      ),
    );
  }
}

class _LearningStrip extends StatelessWidget {
  const _LearningStrip({required this.summary});

  final LearnerSummary summary;

  @override
  Widget build(BuildContext context) {
    final goal = DailyGoalCard(
      summary: summary,
      onTap: () => context.goNamed(AppRoutes.learningName),
    );
    final pills = Wrap(
      spacing: AppSpacing.s,
      runSpacing: AppSpacing.s,
      children: [StreakPill(summary: summary), XpPill(summary: summary)],
    );

    if (context.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [pills, const SizedBox(height: AppSpacing.m), goal],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        pills,
        const SizedBox(width: AppSpacing.l),
        Expanded(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: goal,
        )),
      ],
    );
  }
}

class _CategoriesSection extends ConsumerWidget {
  const _CategoriesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final language = ref.watch(learningLanguageProvider).value;
    if (language == null) return const SizedBox.shrink();

    final categoriesAsync = ref.watch(signCategoriesProvider(language.id));
    final categories = categoriesAsync.value;

    // Sans catégorie en base, la section n'a rien à montrer : elle disparaît
    // plutôt que d'afficher un bloc vide sur la page d'accueil.
    if (categoriesAsync.hasError || (categories != null && categories.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: _sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(
            title: l10n.learnByCategory,
            action: TextButton(
              onPressed: () => context.goNamed(AppRoutes.dictionaryName),
              child: Text(l10n.seeAll),
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          if (categories == null)
            Skeleton(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: adaptiveGridDelegate(maxItemWidth: 220, childAspectRatio: 2.6),
                itemCount: 6,
                itemBuilder: (_, _) => const SkeletonBlock(height: double.infinity, radius: AppRadius.l),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: adaptiveGridDelegate(maxItemWidth: 220, childAspectRatio: 2.6),
              itemCount: categories.length.clamp(0, 12),
              itemBuilder: (context, i) => _CategoryTile(category: categories[i]),
            ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});

  final SignCategory category;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.fromHex(category.colorHex) ?? AppColors.primary;
    return AppPanel(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      semanticLabel: category.name,
      onTap: () => context.pushNamed(
        AppRoutes.categoryName,
        pathParameters: {'id': category.id.toString()},
      ),
      child: ExcludeSemantics(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: AppRadius.radiusM,
              ),
              child: Icon(AppIcons.fromName(category.iconName), color: color, size: 22),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Text(
                category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForEveryoneSection extends StatelessWidget {
  const _ForEveryoneSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = [
      (AppIcons.signLanguage, l10n.homeDeafTitle, l10n.homeDeafBody),
      (AppIcons.learning, l10n.homeHearingTitle, l10n.homeHearingBody),
      (AppIcons.users, l10n.homeCommunityTitle, l10n.homeCommunityBody),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(title: l10n.homeForEveryoneTitle),
        const SizedBox(height: AppSpacing.l),
        Wrap(
          spacing: AppSpacing.l,
          runSpacing: AppSpacing.l,
          children: [
            for (final (icon, title, body) in items)
              SizedBox(
                width: context.isMobile ? double.infinity : 360,
                child: Semantics(
                  container: true,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: AppColors.primary, size: 28),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              body,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ContributionBanner extends StatelessWidget {
  const _ContributionBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.helpCommunity, style: AppTextStyles.h3.copyWith(color: Colors.white)),
        const SizedBox(height: AppSpacing.s),
        Text(
          l10n.contributeDescription,
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.8)),
        ),
      ],
    );

    final button = SizedBox(
      height: AppButton.height,
      width: context.isMobile ? double.infinity : null,
      child: FilledButton.icon(
        onPressed: () => context.pushNamed(AppRoutes.contributeName),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primaryDeep,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusL),
          textStyle: AppTextStyles.button,
        ),
        icon: const Icon(AppIcons.upload, size: 20),
        label: Text(l10n.contributeNow),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.primaryDeep,
        borderRadius: AppRadius.radiusXL,
      ),
      child: context.isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [text, const SizedBox(height: AppSpacing.l), button],
            )
          : Row(
              children: [
                Expanded(child: text),
                const SizedBox(width: AppSpacing.xl),
                button,
              ],
            ),
    );
  }
}
