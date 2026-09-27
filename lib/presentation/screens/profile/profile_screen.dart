import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;
import '../../../core/layout/responsive.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/user_profile.dart';
import '../../../domain/providers/admin_provider.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/learning_provider.dart';
import '../../../domain/providers/profile_provider.dart';
import '../../../domain/providers/sign_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_panel.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/skeletons.dart';
import '../learning/widgets/learning_widgets.dart';
import '../settings/settings_screen.dart';

const double _sectionGap = AppSpacing.xl;
const double _avatarRadius = 36;

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(AppIcons.settings),
              tooltip: l10n.settings,
              onPressed: () => context.pushNamed(AppRoutes.settingsName),
            ),
          const SizedBox(width: AppSpacing.s),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userProfileProvider);
          ref.invalidate(learnerSummaryProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            top: AppSpacing.l,
            bottom: settingsBottomPadding(context),
          ),
          child: PageContainer.reading(
            child: user == null
                ? const _GuestContent()
                : profileAsync.when(
                    data: (profile) => _ProfileContent(profile: profile, user: user),
                    loading: () => const _ProfileSkeleton(),
                    error: (_, _) => AppEmptyState(
                      icon: AppIcons.error,
                      title: l10n.errorGeneric,
                      message: l10n.accountLoadErrorMessage,
                      actionLabel: l10n.retry,
                      onAction: () => ref.invalidate(userProfileProvider),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.profile, required this.user});

  final UserProfile? profile;
  final User user;

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.accountSignOutTitle,
      message: l10n.accountSignOutMessage,
      confirmLabel: l10n.signOut,
      cancelLabel: l10n.cancel,
    );
    if (!confirmed) return;
    await ref.read(authRepositoryProvider).signOut();
    if (context.mounted) context.goNamed(AppRoutes.loginName);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isAdmin = ref.watch(isAdminProvider);
    final languages = ref.watch(signLanguagesProvider).value;

    final name = profile?.displayName?.trim();
    final displayName = (name != null && name.isNotEmpty)
        ? name
        : (user.email?.split('@').first ?? l10n.guest);
    final email = profile?.email ?? user.email ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileHeader(
          displayName: displayName,
          email: email,
          avatarUrl: profile?.avatarUrl,
          isDeaf: profile?.isDeaf ?? false,
          isAdmin: isAdmin,
        ),
        const SizedBox(height: _sectionGap),
        const _LearningSection(),
        const SizedBox(height: _sectionGap),
        SettingsGroup(
          title: l10n.myAccount,
          children: [
            SettingsTile(
              icon: PhosphorIconsRegular.userCircle,
              title: l10n.editProfile,
              onTap: () => context.pushNamed(AppRoutes.editProfileName),
            ),
            SettingsTile(
              icon: AppIcons.history,
              title: l10n.translationHistory,
              onTap: () => context.pushNamed(AppRoutes.historyName),
            ),
            SettingsTile(
              icon: AppIcons.favorite,
              title: l10n.myFavorites,
              onTap: () => context.pushNamed(AppRoutes.favoritesName),
            ),
          ],
        ),
        if (profile != null) ...[
          const SizedBox(height: _sectionGap),
          SettingsGroup(
            title: l10n.preferences,
            children: [
              SettingsTile(
                icon: AppIcons.signLanguage,
                title: l10n.signLanguage,
                value: signLanguageName(languages, profile!.preferredSignLanguage),
                onTap: () => context.pushNamed(AppRoutes.settingsName),
              ),
              SettingsTile(
                icon: PhosphorIconsRegular.eye,
                title: l10n.defaultView,
                value: viewLabel(l10n, profile!.preferredView),
                onTap: () => context.pushNamed(AppRoutes.settingsName),
              ),
              SettingsTile(
                icon: PhosphorIconsRegular.circleHalf,
                title: l10n.theme,
                value: themeLabel(l10n, profile!.theme),
                onTap: () => context.pushNamed(AppRoutes.settingsName),
              ),
            ],
          ),
        ],
        const SizedBox(height: _sectionGap),
        SettingsGroup(
          title: l10n.community,
          children: [
            SettingsTile(
              icon: AppIcons.upload,
              title: l10n.myContributions,
              onTap: () => context.pushNamed(AppRoutes.contributeName),
            ),
            if (isAdmin)
              SettingsTile(
                icon: AppIcons.admin,
                title: l10n.adminPanel,
                onTap: () => context.goNamed(AppRoutes.adminDashboardName),
              ),
          ],
        ),
        const SizedBox(height: _sectionGap),
        const _SupportGroup(),
        const SizedBox(height: _sectionGap),
        Center(
          child: AppButton(
            label: l10n.signOut,
            icon: AppIcons.logout,
            variant: AppButtonVariant.outline,
            onPressed: () => _signOut(context, ref),
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    required this.isDeaf,
    required this.isAdmin,
  });

  final String displayName;
  final String email;
  final String? avatarUrl;
  final bool isDeaf;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppPanel(
      child: Row(
        children: [
          Semantics(
            button: true,
            label: l10n.accountAvatarLabel(displayName),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.pushNamed(AppRoutes.editProfileName),
              child: ExcludeSemantics(
                child: AppAvatar(
                  imageUrl: avatarUrl,
                  name: displayName,
                  radius: _avatarRadius,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.h3,
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.s),
                Wrap(
                  spacing: AppSpacing.s,
                  runSpacing: AppSpacing.s,
                  children: [
                    _Tag(
                      icon: isDeaf ? AppIcons.signLanguage : PhosphorIconsRegular.ear,
                      label: isDeaf ? l10n.deafUser : l10n.accountHearingUser,
                      color: AppColors.primary,
                    ),
                    if (isAdmin)
                      _Tag(
                        icon: AppIcons.admin,
                        label: l10n.adminRole,
                        color: AppColors.success,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: AppRadius.radiusCircular,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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

    return summaryAsync.when(
      data: (summary) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsSectionHeader(l10n.accountLearningSection),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _StatTile(
                    icon: AppIcons.streakActive,
                    color: AppColors.warning,
                    value: l10n.lessonDays(summary.currentStreak),
                    label: l10n.progressCurrentStreak,
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: _StatTile(
                    icon: AppIcons.pointsActive,
                    color: AppColors.primary,
                    value: '${summary.totalXp}',
                    label: l10n.progressTotalXp,
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: _StatTile(
                    icon: AppIcons.success,
                    color: AppColors.success,
                    value: '${summary.lessonsCompleted}',
                    label: l10n.progressLessonsDone,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          DailyGoalCard(
            summary: summary,
            onTap: () => context.goNamed(AppRoutes.progressName),
          ),
        ],
      ),
      loading: () => const _LearningSkeleton(),
      error: (_, _) => SettingsGroup(
        title: l10n.accountLearningSection,
        children: [
          SettingsTile(
            icon: AppIcons.error,
            iconColor: AppColors.error,
            title: l10n.errorGeneric,
            subtitle: l10n.retry,
            onTap: () => ref.invalidate(learnerSummaryProvider),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      semanticLabel: '$label : $value',
      padding: const EdgeInsets.all(AppSpacing.m),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: AppSpacing.s),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: AppTextStyles.h3),
            ),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportGroup extends StatelessWidget {
  const _SupportGroup();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SettingsGroup(
      title: l10n.supportLegal,
      children: [
        SettingsTile(
          icon: PhosphorIconsRegular.lifebuoy,
          title: l10n.helpCenter,
          onTap: () => context.pushNamed(AppRoutes.helpCenterName),
        ),
        SettingsTile(
          icon: PhosphorIconsRegular.shieldCheck,
          title: l10n.privacyPolicy,
          onTap: () => context.pushNamed(AppRoutes.privacyPolicyName),
        ),
        SettingsTile(
          icon: PhosphorIconsRegular.fileText,
          title: l10n.termsOfService,
          onTap: () => context.pushNamed(AppRoutes.termsOfServiceName),
        ),
      ],
    );
  }
}

class _GuestContent extends StatelessWidget {
  const _GuestContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppPanel(
          child: Column(
            children: [
              Container(
                width: _avatarRadius * 2,
                height: _avatarRadius * 2,
                decoration: BoxDecoration(
                  color: AppColors.neutral(context),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.profile,
                  size: 32,
                  color: AppColors.textSecondary(context),
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              Text(l10n.guest, style: AppTextStyles.h3),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.loginToSave,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary(context),
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              AppButton(
                label: l10n.signIn,
                onPressed: () => context.goNamed(AppRoutes.loginName),
              ),
            ],
          ),
        ),
        const SizedBox(height: _sectionGap),
        const _SupportGroup(),
      ],
    );
  }
}

class _LearningSkeleton extends StatelessWidget {
  const _LearningSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      label: AppLocalizations.of(context)!.loading,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(left: AppSpacing.m, bottom: AppSpacing.s),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SkeletonBlock(width: 120, height: 14),
            ),
          ),
          Row(
            children: [
              Expanded(child: SkeletonBlock(height: 104, radius: AppRadius.l)),
              SizedBox(width: AppSpacing.s),
              Expanded(child: SkeletonBlock(height: 104, radius: AppRadius.l)),
              SizedBox(width: AppSpacing.s),
              Expanded(child: SkeletonBlock(height: 104, radius: AppRadius.l)),
            ],
          ),
          SizedBox(height: AppSpacing.m),
          SkeletonBlock(height: 114, radius: AppRadius.l),
        ],
      ),
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Skeleton(
          label: AppLocalizations.of(context)!.loading,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white),
              borderRadius: AppRadius.radiusL,
            ),
            child: const Padding(
              padding: EdgeInsets.all(AppSpacing.l),
              child: Row(
                children: [
                  SkeletonBlock.circle(size: _avatarRadius * 2),
                  SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBlock(width: 160, height: 20),
                        SizedBox(height: AppSpacing.s),
                        SkeletonBlock(width: 200, height: 14),
                        SizedBox(height: AppSpacing.s),
                        SkeletonBlock(width: 110, height: 24, radius: AppRadius.circular),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: _sectionGap),
        const _LearningSkeleton(),
        const SizedBox(height: _sectionGap),
        const SettingsSkeleton(groups: [3, 3]),
      ],
    );
  }
}
