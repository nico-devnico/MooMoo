import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moomoo/core/router/app_routes.dart';
import 'package:moomoo/core/theme/app_colors.dart';
import 'package:moomoo/core/theme/app_spacing.dart';
import 'package:moomoo/core/theme/app_text_styles.dart';
import 'package:moomoo/domain/providers/profile_provider.dart';
import 'package:moomoo/domain/providers/auth_provider.dart';
import 'package:moomoo/domain/providers/three_d_settings_provider.dart';
import 'package:moomoo/domain/providers/character_provider.dart';
import 'package:moomoo/core/constants/character_constants.dart';
import 'package:moomoo/data/models/character.dart';
import '../../widgets/app_snackbar.dart';
import '../../../l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final threeDSettingsAsync = ref.watch(threeDSettingsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) return Center(child: Text(l10n.profileNotFound));

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.l),
            children: [
              _buildSection(
                l10n.accountSecurity,
                [
                  ListTile(
                    leading: const Icon(Icons.person_outline, color: AppColors.primary),
                    title: Text(l10n.personalInfo),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.pushNamed(AppRoutes.editProfileName),
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock_outline, color: AppColors.primary),
                    title: Text(l10n.changePassword),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showPasswordDialog(context, ref, l10n),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.l),
              _buildSection(
                l10n.displayPreferences,
                [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(_getFlagForCode(profile.preferredSignLanguage), style: const TextStyle(fontSize: 16)),
                    ),
                    title: Text(l10n.signLanguage),
                    subtitle: Text(_getSignLanguageLabel(profile.preferredSignLanguage, l10n)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showSignLanguagePicker(context, ref, profile, l10n),
                  ),
                  ListTile(
                    leading: const Icon(Icons.visibility_outlined, color: AppColors.primary),
                    title: Text(l10n.defaultView),
                    subtitle: Text(profile.preferredView == '3d' ? l10n.model3D : l10n.video),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showViewPicker(context, ref, profile, l10n),
                  ),
                  ListTile(
                    leading: const Icon(Icons.dark_mode_outlined, color: AppColors.primary),
                    title: Text(l10n.theme),
                    subtitle: Text(profile.theme == 'light' ? l10n.light : profile.theme == 'dark' ? l10n.dark : l10n.system),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showThemePicker(context, ref, profile, l10n),
                  ),
                  ListTile(
                    leading: const Icon(Icons.language_outlined, color: AppColors.primary),
                    title: Text(l10n.appLanguage),
                    subtitle: Text(profile.locale == 'fr' ? l10n.french : l10n.english),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showLocalePicker(context, ref, profile, l10n),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.l),
              _buildSection(
                l10n.settings3D,
                [
                  threeDSettingsAsync.when(
                    data: (settings) {
                      final selectedId = settings['selectedCharacterId'] ?? CharacterConstants.defaultCharacterId;
                      return ref.watch(characterByIdProvider(selectedId)).when(
                        data: (character) => ListTile(
                          leading: const Icon(Icons.face_outlined, color: AppColors.primary),
                          title: Text(l10n.character3D),
                          subtitle: Text(character?.name ?? 'Chargement...'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showCharacterPicker(context, ref, l10n, settings),
                        ),
                        loading: () => const ListTile(
                          leading: CircularProgressIndicator.adaptive(),
                          title: Text('Chargement du personnage...'),
                        ),
                        error: (_, __) => ListTile(
                          leading: const Icon(Icons.error_outline, color: AppColors.error),
                          title: Text(l10n.character3D),
                          subtitle: const Text('Erreur de chargement'),
                          onTap: () => _showCharacterPicker(context, ref, l10n, settings),
                        ),
                      );
                    },
                    loading: () => const ListTile(title: Text('Chargement...')),
                    error: (_, __) => const ListTile(title: Text('Erreur')),
                  ),
                  threeDSettingsAsync.when(
                    data: (settings) => Column(
                      children: [
                        SwitchListTile(
                          secondary: const Icon(Icons.rotate_right, color: AppColors.primary),
                          title: Text(l10n.autoRotate),
                          subtitle: Text(l10n.autoRotateDesc),
                          value: settings['autoRotate'] ?? false,
                          onChanged: (val) {
                            ref.read(threeDSettingsProvider.notifier).setAutoRotate(val);
                          },
                        ),
                        SwitchListTile(
                          secondary: const Icon(Icons.zoom_in, color: AppColors.primary),
                          title: Text(l10n.zoomEnabled),
                          subtitle: Text(l10n.zoomEnabledDesc),
                          value: settings['zoomEnabled'] ?? true,
                          onChanged: (val) {
                            ref.read(threeDSettingsProvider.notifier).setZoomEnabled(val);
                          },
                        ),
                      ],
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Center(child: Text('Erreur : $e')),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.l),
              _buildSection(
                l10n.notifications,
                [
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_none, color: AppColors.primary),
                    title: Text(l10n.pushNotifications),
                    value: true,
                    onChanged: (val) {},
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.mail_outline, color: AppColors.primary),
                    title: Text(l10n.newsletter),
                    value: false,
                    onChanged: (val) {},
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.l),
              _buildSection(
                l10n.supportLegal,
                [
                  ListTile(
                    leading: const Icon(Icons.help_outline, color: AppColors.primary),
                    title: Text(l10n.helpCenter),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.pushNamed(AppRoutes.helpCenterName),
                  ),
                  ListTile(
                    leading: const Icon(Icons.policy_outlined, color: AppColors.primary),
                    title: Text(l10n.privacyPolicy),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.pushNamed(AppRoutes.privacyPolicyName),
                  ),
                  ListTile(
                    leading: const Icon(Icons.description_outlined, color: AppColors.primary),
                    title: Text(l10n.termsOfService),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.pushNamed(AppRoutes.termsOfServiceName),
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline, color: AppColors.primary),
                    title: Text(l10n.version),
                    trailing: const Text('1.0.0'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: Text(l10n.deleteAccount),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Erreur : $e')),
      ),
    );
  }

  String _getSignLanguageLabel(String code, AppLocalizations l10n) {
    switch (code) {
      case 'LSF': return l10n.lsf;
      case 'ASL': return l10n.asl;
      case 'BSL': return l10n.bsl;
      case 'LSC': return l10n.lsc;
      default: return code;
    }
  }

  String _getFlagForCode(String code) {
    switch (code.toUpperCase()) {
      case 'LSF': return '🇫🇷';
      case 'ASL': return '🇺🇸';
      case 'BSL': return '🇬🇧';
      case 'LSC':
      case 'CAM':
      case 'CMR':
        return '🇨🇲';
      default: return '🌎';
    }
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
              child: Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
            Card(
              elevation: 0,
              color: isDark ? AppColors.surfaceDark : AppColors.neutralLight.withOpacity(0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(children: children),
            ),
          ],
        );
      }
    );
  }

  void _showCharacterPicker(BuildContext context, WidgetRef ref, AppLocalizations l10n, Map<String, dynamic> settings) {
    final charactersAsync = ref.read(charactersProvider);
    final selectedId = settings['selectedCharacterId'] ?? CharacterConstants.defaultCharacterId;
    
    charactersAsync.whenData((characters) {
      showModalBottomSheet(
        context: context,
        builder: (context) => _PickerSheet(
          title: l10n.chooseCharacter,
          options: characters.map((c) => c.id).toList(),
          labels: {for (var c in characters) c.id: c.name},
          selected: selectedId,
          onSelected: (val) async {
            await ref.read(threeDSettingsProvider.notifier).setSelectedCharacterId(val);
            if (context.mounted) Navigator.pop(context);
          },
        ),
      );
    });
  }

  void _showSignLanguagePicker(BuildContext context, WidgetRef ref, dynamic profile, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _PickerSheet(
        title: l10n.signLanguage,
        options: const ['LSF', 'ASL', 'BSL', 'LSC'],
        labels: {
          'LSF': l10n.lsf,
          'ASL': l10n.asl,
          'BSL': l10n.bsl,
          'LSC': l10n.lsc,
        },
        icons: {
          'LSF': '🇫🇷',
          'ASL': '🇺🇸',
          'BSL': '🇬🇧',
          'LSC': '🇨🇲',
        },
        selected: profile.preferredSignLanguage,
        onSelected: (val) async {
          await ref.read(profileRepositoryProvider).updateProfile(profile.copyWith(preferredSignLanguage: val));
          ref.invalidate(userProfileProvider);
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _showPasswordDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.changePassword),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            labelText: l10n.newPassword,
            hintText: l10n.min6Chars,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.length < 6) {
                AppSnackbar.showError(context, l10n.passwordTooShort);
                return;
              }
              try {
                await ref.read(authRepositoryProvider).updatePassword(controller.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  AppSnackbar.showSuccess(context, l10n.passwordUpdated);
                }
              } catch (e) {
                if (context.mounted) AppSnackbar.showError(context, 'Erreur : $e');
              }
            },
            child: Text(l10n.modify),
          ),
        ],
      ),
    );
  }

  void _showViewPicker(BuildContext context, WidgetRef ref, dynamic profile, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _PickerSheet(
        title: l10n.defaultView,
        options: const ['3d', 'video'],
        labels: {'3d': l10n.model3D, 'video': l10n.video},
        icons: {'3d': Icons.accessibility_new, 'video': Icons.videocam},
        selected: profile.preferredView,
        onSelected: (val) async {
          await ref.read(profileRepositoryProvider).updateProfile(profile.copyWith(preferredView: val));
          ref.invalidate(userProfileProvider);
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _showThemePicker(BuildContext context, WidgetRef ref, dynamic profile, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _PickerSheet(
        title: l10n.theme,
        options: const ['light', 'dark', 'system'],
        labels: {'light': l10n.light, 'dark': l10n.dark, 'system': l10n.system},
        icons: {'light': Icons.light_mode, 'dark': Icons.dark_mode, 'system': Icons.settings_brightness},
        selected: profile.theme,
        onSelected: (val) async {
          await ref.read(profileRepositoryProvider).updateProfile(profile.copyWith(theme: val));
          ref.invalidate(userProfileProvider);
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _showLocalePicker(BuildContext context, WidgetRef ref, dynamic profile, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _PickerSheet(
        title: l10n.appLanguage,
        options: const ['fr', 'en'],
        labels: {'fr': l10n.french, 'en': l10n.english},
        icons: {'fr': '🇫🇷', 'en': '🇺🇸'},
        selected: profile.locale,
        onSelected: (val) async {
          await ref.read(profileRepositoryProvider).updateProfile(profile.copyWith(locale: val));
          ref.invalidate(userProfileProvider);
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }
}

class _PickerSheet extends StatelessWidget {
  final String title;
  final List<String> options;
  final Map<String, String>? labels;
  final Map<String, dynamic>? icons;
  final String selected;
  final Function(String) onSelected;

  const _PickerSheet({
    required this.title,
    required this.options,
    this.labels,
    this.icons,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: AppTextStyles.h3),
          const SizedBox(height: AppSpacing.l),
          ...options.map((opt) {
            Widget? leading;
            if (icons != null && icons![opt] != null) {
              if (icons![opt] is IconData) {
                leading = Icon(icons![opt] as IconData, color: AppColors.primary);
              } else if (icons![opt] is String) {
                leading = Text(icons![opt] as String, style: const TextStyle(fontSize: 24));
              }
            }

            return ListTile(
              leading: leading,
              title: Text(labels?[opt] ?? opt),
              trailing: opt == selected ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () => onSelected(opt),
            );
          }),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
