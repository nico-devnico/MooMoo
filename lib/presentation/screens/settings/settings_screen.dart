import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:moomoo/core/constants/character_constants.dart';
import 'package:moomoo/core/layout/responsive.dart';
import 'package:moomoo/core/router/app_routes.dart';
import 'package:moomoo/core/theme/app_colors.dart';
import 'package:moomoo/core/theme/app_icons.dart';
import 'package:moomoo/core/theme/app_radius.dart';
import 'package:moomoo/core/theme/app_spacing.dart';
import 'package:moomoo/core/theme/app_text_styles.dart';
import 'package:moomoo/data/models/sign_language.dart';
import 'package:moomoo/data/models/user_profile.dart';
import 'package:moomoo/domain/providers/auth_provider.dart';
import 'package:moomoo/domain/providers/character_provider.dart';
import 'package:moomoo/domain/providers/profile_provider.dart';
import 'package:moomoo/domain/providers/sign_provider.dart';
import 'package:moomoo/domain/providers/three_d_settings_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_panel.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/skeletons.dart';

/// Seule voie de contact pour ce que l'application ne traite pas elle-même,
/// comme la suppression d'un compte.
const String kSupportEmail = 'nicodevnico@gmail.com';

/// Doit rester aligné sur `version` dans pubspec.yaml.
const String kAppVersion = '1.0.0';

const double _groupGap = AppSpacing.xl;

/// Marge basse des pages défilantes : sur mobile, la barre de navigation
/// flottante recouvre le bas de l'écran.
double settingsBottomPadding(BuildContext context) =>
    context.isMobile ? 100 : AppSpacing.xxl;

String signLanguageName(List<SignLanguage>? languages, String code) {
  for (final language in languages ?? const <SignLanguage>[]) {
    if (language.code == code) return language.name;
  }
  return code;
}

String themeLabel(AppLocalizations l10n, String theme) => switch (theme) {
      'light' => l10n.light,
      'dark' => l10n.dark,
      _ => l10n.system,
    };

String viewLabel(AppLocalizations l10n, String view) =>
    view == '3d' ? l10n.model3D : l10n.video;

/// Ouvre la messagerie vers l'équipe ; sans client e-mail, l'adresse est
/// affichée pour que l'utilisateur puisse écrire par un autre moyen.
Future<void> openSupportEmail(
  BuildContext context, {
  required String subject,
  String? body,
}) async {
  final l10n = AppLocalizations.of(context)!;
  // `queryParameters` encoderait les espaces en « + », que les clients
  // e-mail affichent tels quels.
  final query = [
    'subject=${Uri.encodeComponent(subject)}',
    if (body != null) 'body=${Uri.encodeComponent(body)}',
  ].join('&');
  final uri = Uri.parse('mailto:$kSupportEmail?$query');

  var launched = false;
  try {
    launched = await launchUrl(uri);
  } catch (_) {
    launched = false;
  }
  if (!launched && context.mounted) {
    AppSnackbar.showInfo(context, l10n.accountMailUnavailable(kSupportEmail));
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: AppSpacing.l,
          bottom: settingsBottomPadding(context),
        ),
        child: PageContainer.reading(
          child: profileAsync.when(
            data: (profile) {
              if (profile == null) {
                return AppEmptyState(
                  icon: AppIcons.profile,
                  title: l10n.profileNotFound,
                  message: l10n.loginToSave,
                  actionLabel: l10n.signIn,
                  onAction: () => context.goNamed(AppRoutes.loginName),
                );
              }
              return _SettingsContent(profile: profile);
            },
            loading: () => const SettingsSkeleton(groups: [2, 1, 4, 3, 4]),
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
    );
  }
}

class _SettingsContent extends ConsumerStatefulWidget {
  const _SettingsContent({required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends ConsumerState<_SettingsContent> {
  bool? _pendingDeaf;

  Future<bool> _save(UserProfile updated) async {
    try {
      await ref.read(profileRepositoryProvider).updateProfile(updated);
      ref.invalidate(userProfileProvider);
      return true;
    } catch (_) {
      if (mounted) {
        AppSnackbar.showError(context, AppLocalizations.of(context)!.accountSaveError);
      }
      return false;
    }
  }

  Future<void> _setDeaf(bool value) async {
    setState(() => _pendingDeaf = value);
    await _save(widget.profile.copyWith(isDeaf: value));
    if (mounted) setState(() => _pendingDeaf = null);
  }

  Future<void> _pickSignLanguage() async {
    final l10n = AppLocalizations.of(context)!;
    List<SignLanguage> languages;
    try {
      languages = await ref.read(signLanguagesProvider.future);
    } catch (_) {
      if (mounted) AppSnackbar.showError(context, l10n.errorLoadingLanguages);
      return;
    }
    if (!mounted) return;

    final code = await showOptionPicker(
      context,
      title: l10n.signLanguage,
      selected: widget.profile.preferredSignLanguage,
      options: [
        for (final language in languages.where((l) => l.isActive))
          PickerOption(
            value: language.code,
            label: language.name,
            subtitle: language.country,
            badge: language.code,
          ),
      ],
    );
    if (code == null || code == widget.profile.preferredSignLanguage) return;
    await _save(widget.profile.copyWith(preferredSignLanguage: code));
  }

  Future<void> _pickView() async {
    final l10n = AppLocalizations.of(context)!;
    final view = await showOptionPicker(
      context,
      title: l10n.defaultView,
      selected: widget.profile.preferredView,
      options: [
        PickerOption(value: '3d', label: l10n.model3D, icon: PhosphorIconsRegular.cube),
        PickerOption(value: 'video', label: l10n.video, icon: AppIcons.video),
      ],
    );
    if (view == null || view == widget.profile.preferredView) return;
    await _save(widget.profile.copyWith(preferredView: view));
  }

  Future<void> _pickTheme() async {
    final l10n = AppLocalizations.of(context)!;
    final theme = await showOptionPicker(
      context,
      title: l10n.theme,
      selected: widget.profile.theme,
      options: [
        PickerOption(value: 'light', label: l10n.light, icon: PhosphorIconsRegular.sun),
        PickerOption(value: 'dark', label: l10n.dark, icon: PhosphorIconsRegular.moon),
        PickerOption(value: 'system', label: l10n.system, icon: PhosphorIconsRegular.circleHalf),
      ],
    );
    if (theme == null || theme == widget.profile.theme) return;
    await _save(widget.profile.copyWith(theme: theme));
  }

  Future<void> _pickLocale() async {
    final l10n = AppLocalizations.of(context)!;
    final locale = await showOptionPicker(
      context,
      title: l10n.appLanguage,
      selected: widget.profile.locale,
      options: [
        PickerOption(value: 'fr', label: l10n.french, badge: 'FR'),
        PickerOption(value: 'en', label: l10n.english, badge: 'EN'),
      ],
    );
    if (locale == null || locale == widget.profile.locale) return;
    await _save(widget.profile.copyWith(locale: locale));
  }

  Future<void> _changePassword() async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => const _PasswordDialog(),
    );
    if (updated == true && mounted) {
      AppSnackbar.showSuccess(context, AppLocalizations.of(context)!.passwordUpdated);
    }
  }

  Future<void> _requestDeletion() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.accountDeleteTitle,
      message: l10n.accountDeleteMessage,
      confirmLabel: l10n.accountDeleteConfirm,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    final email = widget.profile.email ?? ref.read(currentUserProvider)?.email ?? '';
    await openSupportEmail(
      context,
      subject: l10n.accountDeleteMailSubject,
      body: l10n.accountDeleteMailBody(email),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = widget.profile;
    final languages = ref.watch(signLanguagesProvider).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsGroup(
          title: l10n.accountSecurity,
          children: [
            SettingsTile(
              icon: PhosphorIconsRegular.userCircle,
              title: l10n.personalInfo,
              onTap: () => context.pushNamed(AppRoutes.editProfileName),
            ),
            SettingsTile(
              icon: AppIcons.locked,
              title: l10n.changePassword,
              onTap: _changePassword,
            ),
          ],
        ),
        const SizedBox(height: _groupGap),
        SettingsGroup(
          title: l10n.accountAccessibility,
          footer: l10n.accountDeafSwitchHint,
          children: [
            SettingsSwitchTile(
              icon: PhosphorIconsRegular.ear,
              title: l10n.accountDeafSwitch,
              value: _pendingDeaf ?? profile.isDeaf,
              onChanged: _pendingDeaf != null ? null : _setDeaf,
            ),
          ],
        ),
        const SizedBox(height: _groupGap),
        SettingsGroup(
          title: l10n.displayPreferences,
          children: [
            SettingsTile(
              icon: AppIcons.signLanguage,
              title: l10n.signLanguage,
              value: signLanguageName(languages, profile.preferredSignLanguage),
              onTap: _pickSignLanguage,
            ),
            SettingsTile(
              icon: PhosphorIconsRegular.eye,
              title: l10n.defaultView,
              value: viewLabel(l10n, profile.preferredView),
              onTap: _pickView,
            ),
            SettingsTile(
              icon: PhosphorIconsRegular.circleHalf,
              title: l10n.theme,
              value: themeLabel(l10n, profile.theme),
              onTap: _pickTheme,
            ),
            SettingsTile(
              icon: AppIcons.language,
              title: l10n.appLanguage,
              value: profile.locale == 'fr' ? l10n.french : l10n.english,
              onTap: _pickLocale,
            ),
          ],
        ),
        const SizedBox(height: _groupGap),
        const _ThreeDGroup(),
        const SizedBox(height: _groupGap),
        SettingsGroup(
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
            SettingsTile(
              icon: AppIcons.info,
              title: l10n.about,
              value: kAppVersion,
              onTap: () => context.pushNamed(AppRoutes.aboutName),
            ),
          ],
        ),
        const SizedBox(height: _groupGap),
        SettingsGroup(
          title: l10n.accountDangerZone,
          footer: l10n.accountDeleteRequestHint,
          children: [
            SettingsTile(
              icon: AppIcons.delete,
              title: l10n.accountDeleteRequest,
              destructive: true,
              onTap: _requestDeletion,
            ),
          ],
        ),
      ],
    );
  }
}

class _ThreeDGroup extends ConsumerWidget {
  const _ThreeDGroup();

  Future<void> _pickCharacter(
    BuildContext context,
    WidgetRef ref,
    String selectedId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final characters = await ref.read(charactersProvider.future);
    if (!context.mounted) return;

    final id = await showOptionPicker(
      context,
      title: l10n.character3D,
      selected: selectedId,
      options: [
        for (final character in characters)
          PickerOption(
            value: character.id,
            label: character.name,
            icon: PhosphorIconsRegular.personSimple,
          ),
      ],
    );
    if (id == null || id == selectedId) return;
    await ref.read(threeDSettingsProvider.notifier).setSelectedCharacterId(id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settingsAsync = ref.watch(threeDSettingsProvider);

    return settingsAsync.when(
      data: (settings) {
        final selectedId = settings['selectedCharacterId'] as String? ??
            CharacterConstants.defaultCharacterId;
        final characterName = ref.watch(characterByIdProvider(selectedId)).when(
              data: (character) => character?.name ?? l10n.accountCharacterUnavailable,
              loading: () => null,
              error: (_, _) => l10n.accountCharacterUnavailable,
            );
        final notifier = ref.read(threeDSettingsProvider.notifier);

        return SettingsGroup(
          title: l10n.settings3D,
          children: [
            SettingsTile(
              icon: PhosphorIconsRegular.personSimple,
              title: l10n.character3D,
              value: characterName,
              onTap: () => _pickCharacter(context, ref, selectedId),
            ),
            SettingsSwitchTile(
              icon: PhosphorIconsRegular.handGrabbing,
              title: l10n.manualControl,
              subtitle: l10n.manualControlDesc,
              value: settings['cameraControlsEnabled'] as bool? ?? true,
              onChanged: notifier.setCameraControlsEnabled,
            ),
            SettingsSwitchTile(
              icon: PhosphorIconsRegular.magnifyingGlassPlus,
              title: l10n.zoomEnabled,
              subtitle: l10n.zoomEnabledDesc,
              value: settings['zoomEnabled'] as bool? ?? true,
              onChanged: notifier.setZoomEnabled,
            ),
          ],
        );
      },
      loading: () => const SettingsSkeleton(groups: [3]),
      error: (_, _) => SettingsGroup(
        title: l10n.settings3D,
        children: [
          SettingsTile(
            icon: AppIcons.error,
            iconColor: AppColors.error,
            title: l10n.errorGeneric,
            subtitle: l10n.retry,
            onTap: () => ref.invalidate(threeDSettingsProvider),
          ),
        ],
      ),
    );
  }
}

class _PasswordDialog extends ConsumerStatefulWidget {
  const _PasswordDialog();

  @override
  ConsumerState<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends ConsumerState<_PasswordDialog> {
  final _controller = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_controller.text.length < 6) {
      setState(() => _error = l10n.passwordTooShort);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).updatePassword(_controller.text);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = l10n.errorGeneric;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.changePassword),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: TextField(
          controller: _controller,
          obscureText: true,
          autofocus: true,
          enabled: !_saving,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: l10n.newPassword,
            helperText: l10n.min6Chars,
            errorText: _error,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.modify),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Listes groupées façon réglages système, partagées par les écrans du compte.
// ---------------------------------------------------------------------------

Color _softTint(BuildContext context, Color color) => color.withValues(
      alpha: Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.10,
    );

/// Titre de section au-dessus d'un [SettingsGroup].
class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.m, bottom: AppSpacing.s),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary(context),
          ),
        ),
      ),
    );
  }
}

/// Panneau plat bordé dont les lignes sont séparées par un filet, avec un
/// titre de section et une note explicative facultatifs.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    super.key,
    this.title,
    this.footer,
    required this.children,
  });

  final String? title;
  final String? footer;
  final List<Widget> children;

  /// Aligne le filet sur le texte, après l'icône de tête.
  static const double dividerIndent = AppSpacing.m + SettingsIcon.size + AppSpacing.m;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) SettingsSectionHeader(title!),
        AppPanel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: dividerIndent,
                    color: AppColors.border(context),
                  ),
                children[i],
              ],
            ],
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.m,
              AppSpacing.s,
              AppSpacing.m,
              0,
            ),
            child: Text(
              footer!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
      ],
    );
  }
}

/// Pastille teintée qui porte l'icône d'une ligne.
class SettingsIcon extends StatelessWidget {
  const SettingsIcon(
    this.icon, {
    super.key,
    this.color = AppColors.primary,
    this.circle = false,
  });

  static const double size = 36;

  final IconData icon;
  final Color color;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _softTint(context, color),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : AppRadius.radiusM,
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.destructive = false,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Valeur courante affichée à droite, avant le chevron.
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final secondary = AppColors.textSecondary(context);
    final accent = destructive ? AppColors.error : (iconColor ?? AppColors.primary);

    Widget? trailingWidget = trailing;
    if (trailingWidget == null && (value != null || onTap != null)) {
      trailingWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(
                value!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(color: secondary),
              ),
            ),
          if (onTap != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(AppIcons.chevron, size: 18, color: secondary),
          ],
        ],
      );
    }

    return ListTile(
      minTileHeight: 56,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      horizontalTitleGap: AppSpacing.m,
      leading: SettingsIcon(icon, color: accent),
      title: Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.bodyLarge.copyWith(
          color: destructive ? AppColors.error : null,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: AppTextStyles.bodySmall.copyWith(color: secondary),
            ),
      trailing: trailingWidget,
      onTap: onTap,
    );
  }
}

class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      secondary: SettingsIcon(icon),
      title: Text(title, style: AppTextStyles.bodyLarge),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
      value: value,
      onChanged: onChanged,
    );
  }
}

/// Squelette d'une ligne de [SettingsGroup] : même pastille, même hauteur.
class SettingsRowSkeleton extends StatelessWidget {
  const SettingsRowSkeleton({super.key, this.lines = 1, this.circle = false});

  final int lines;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: lines == 1 ? 10 : 14,
      ),
      child: Row(
        crossAxisAlignment: lines > 2 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          circle
              ? const SkeletonBlock.circle(size: SettingsIcon.size)
              : const SkeletonBlock(
                  width: SettingsIcon.size,
                  height: SettingsIcon.size,
                  radius: AppRadius.m,
                ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: lines == 1
                ? const Align(
                    alignment: Alignment.centerLeft,
                    child: SkeletonBlock(width: 160, height: 14),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonBlock(width: 180, height: 14),
                      for (var i = 1; i < lines; i++) ...[
                        const SizedBox(height: AppSpacing.s),
                        SkeletonBlock(width: i == lines - 1 ? 110 : 240, height: 12),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Squelette d'une suite de [SettingsGroup] ; [groups] donne le nombre de
/// lignes de chaque groupe.
class SettingsSkeleton extends StatelessWidget {
  const SettingsSkeleton({
    super.key,
    this.groups = const [3, 3],
    this.lines = 1,
    this.circle = false,
    this.showTitles = true,
  });

  final List<int> groups;
  final int lines;
  final bool circle;
  final bool showTitles;

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      label: AppLocalizations.of(context)!.loading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var g = 0; g < groups.length; g++) ...[
            if (g > 0) const SizedBox(height: _groupGap),
            if (showTitles)
              const Padding(
                padding: EdgeInsets.only(left: AppSpacing.m, bottom: AppSpacing.s),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SkeletonBlock(width: 120, height: 14),
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white),
                borderRadius: AppRadius.radiusL,
              ),
              child: Column(
                children: [
                  for (var i = 0; i < groups[g]; i++)
                    SettingsRowSkeleton(lines: lines, circle: circle),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PickerOption {
  const PickerOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.badge,
  });

  final String value;
  final String label;
  final String? subtitle;
  final IconData? icon;

  /// Code court affiché en tête quand aucune icône ne distingue les options.
  final String? badge;
}

/// Feuille de choix unique ; renvoie la valeur choisie, ou `null` si
/// l'utilisateur ferme la feuille.
Future<String?> showOptionPicker(
  BuildContext context, {
  required String title,
  required List<PickerOption> options,
  required String selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (context) => _OptionSheet(
      title: title,
      options: options,
      selected: selected,
    ),
  );
}

class _OptionSheet extends StatelessWidget {
  const _OptionSheet({
    required this.title,
    required this.options,
    required this.selected,
  });

  final String title;
  final List<PickerOption> options;
  final String selected;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.7;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.m, 0, AppSpacing.m, AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s, 0, AppSpacing.s, AppSpacing.m),
              child: Semantics(
                header: true,
                child: Text(title, style: AppTextStyles.h3),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final option in options) _buildOption(context, option),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, PickerOption option) {
    final isSelected = option.value == selected;

    Widget? leading;
    if (option.icon != null) {
      leading = SettingsIcon(option.icon!);
    } else if (option.badge != null) {
      leading = Container(
        width: 44,
        height: SettingsIcon.size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _softTint(context, AppColors.primary),
          borderRadius: AppRadius.radiusM,
        ),
        child: Text(
          option.badge!,
          maxLines: 1,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      );
    }

    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: isSelected,
      child: ListTile(
        minTileHeight: 56,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusM),
        selected: isSelected,
        selectedTileColor: _softTint(context, AppColors.primary),
        leading: leading,
        title: Text(
          option.label,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : null,
          ),
        ),
        subtitle: option.subtitle == null
            ? null
            : Text(
                option.subtitle!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary(context),
                ),
              ),
        trailing: isSelected ? const Icon(AppIcons.check, color: AppColors.primary) : null,
        onTap: () => Navigator.pop(context, option.value),
      ),
    );
  }
}
