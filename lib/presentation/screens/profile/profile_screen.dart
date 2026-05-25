import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/profile_provider.dart';
import '../../../domain/providers/storage_provider.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_loader.dart';
import '../../../l10n/app_localizations.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploading = false;

  Future<void> _pickAndUploadAvatar() async {
    final l10n = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );

    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      String? url;
      final storageRepo = ref.read(storageRepositoryProvider);
      
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        url = await storageRepo.uploadAvatar(
          bytes: bytes,
          userId: user.id,
        );
      } else {
        url = await storageRepo.uploadAvatar(
          path: image.path,
          userId: user.id,
        );
      }

      // Add timestamp to bust cache
      final timestampedUrl = '$url?t=${DateTime.now().millisecondsSinceEpoch}';

      final currentProfile = await ref.read(profileRepositoryProvider).getProfile(user.id);
      if (currentProfile != null) {
        await ref.read(profileRepositoryProvider).updateProfile(
              currentProfile.copyWith(avatarUrl: timestampedUrl),
            );
        
        // Force refresh the profile provider
        ref.invalidate(userProfileProvider);
      }

      if (mounted) {
        AppSnackbar.show(context, message: l10n.profileUpdated, type: AppSnackbarType.success);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, message: '${l10n.uploadError} : $e', type: AppSnackbarType.error);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final user = ref.watch(currentUserProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.pushNamed(AppRoutes.settingsName),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          final displayName = profile?.displayName ?? user?.email?.split('@').first ?? l10n.guest;
          final photoUrl = profile?.avatarUrl;
          final email = profile?.email ?? user?.email ?? l10n.loginToSave;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.l),
                children: [
                  // Header
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            AppAvatar(
                              imageUrl: photoUrl,
                              name: displayName,
                              radius: 60,
                              showEditIcon: true,
                              onTap: _isUploading ? null : _pickAndUploadAvatar,
                            ),
                            if (_isUploading)
                              const CircularProgressIndicator(color: AppColors.primary),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.m),
                        Text(displayName, style: AppTextStyles.h2),
                        Text(email, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryLight)),
                        if (user != null) ...[
                          const SizedBox(height: AppSpacing.s),
                          const _UserTypeBadge(),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Sections
                  _buildSection(
                    context,
                    l10n.myAccount,
                    [
                      _ProfileTile(
                        icon: Icons.person_outline,
                        title: l10n.editProfile,
                        onTap: () => context.pushNamed(AppRoutes.editProfileName),
                      ),
                      _ProfileTile(
                        icon: Icons.history,
                        title: l10n.translationHistory,
                        onTap: () => context.pushNamed(AppRoutes.historyName),
                      ),
                      _ProfileTile(
                        icon: Icons.favorite_border,
                        title: l10n.myFavorites,
                        onTap: () => context.pushNamed(AppRoutes.favoritesName),
                      ),
                    ],
                  ),

                  _buildSection(
                    context,
                    l10n.preferences,
                    [
                      _ProfileTile(
                        icon: Icons.language,
                        title: l10n.signLanguage,
                        trailing: Text(() {
                          final ls = profile?.preferredSignLanguage ?? 'LSF';
                          String flag = '🇫🇷';
                          if (ls == 'ASL') flag = '🇺🇸';
                          if (ls == 'BSL') flag = '🇬🇧';
                          return '$ls $flag';
                        }()),
                        onTap: () => context.pushNamed(AppRoutes.settingsName),
                      ),
                      _ProfileTile(
                        icon: Icons.visibility_outlined,
                        title: l10n.defaultView,
                        trailing: Text(profile?.preferredView == '3d' ? 'Modèle 3D' : 'Vidéo'),
                        onTap: () => context.pushNamed(AppRoutes.settingsName),
                      ),
                      _ProfileTile(
                        icon: Icons.dark_mode_outlined,
                        title: l10n.theme,
                        trailing: Text(profile?.theme ?? 'Auto'),
                        onTap: () => context.pushNamed(AppRoutes.settingsName),
                      ),
                    ],
                  ),

                  _buildSection(
                    context,
                    l10n.community,
                    [
                      _ProfileTile(
                        icon: Icons.cloud_upload_outlined,
                        title: l10n.myContributions,
                        onTap: () => context.pushNamed(AppRoutes.contributeName),
                      ),
                    ],
                  ),

                  _buildSection(
                    context,
                    l10n.supportLegal,
                    [
                      _ProfileTile(
                        icon: Icons.help_outline,
                        title: l10n.helpCenter,
                        onTap: () => context.pushNamed(AppRoutes.helpCenterName),
                      ),
                      _ProfileTile(
                        icon: Icons.privacy_tip,
                        title: l10n.privacyPolicy,
                        onTap: () => context.pushNamed(AppRoutes.privacyPolicyName),
                      ),
                      _ProfileTile(
                        icon: Icons.description_outlined,
                        title: l10n.termsOfService,
                        onTap: () => context.pushNamed(AppRoutes.termsOfServiceName),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: user != null ? l10n.signOut : l10n.signIn,
                    variant: user != null ? AppButtonVariant.outline : AppButtonVariant.primary,
                    onPressed: () async {
                      if (user != null) {
                        await ref.read(authRepositoryProvider).signOut();
                        if (context.mounted) context.goNamed(AppRoutes.loginName);
                      } else {
                        context.goNamed(AppRoutes.loginName);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: AppLoader()),
        error: (e, s) => Center(child: Text(l10n.profileNotFound)),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
          child: Text(
            title,
            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ),
        Card(
          elevation: 0,
          color: isDark ? AppColors.surfaceDark : AppColors.neutralLight.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(
        icon, 
        color: isDark ? AppColors.primary : AppColors.textPrimaryLight, 
        size: 22
      ),
      title: Text(title, style: AppTextStyles.bodyMedium),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    );
  }
}

class _UserTypeBadge extends StatelessWidget {
  const _UserTypeBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
      ),
      child: Text(
        'Sourd / Malentendant',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary, fontWeight: FontWeight.bold),
      ),
    );
  }
}
