import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/storage_repository.dart';
import '../../../domain/providers/error_text.dart';
import '../../../domain/providers/profile_provider.dart';
import '../../../domain/providers/storage_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_panel.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/skeletons.dart';
import '../settings/settings_screen.dart';

const double _avatarRadius = 40;

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isSaving = false;
  bool _isInitialized = false;
  bool _isDeaf = false;
  bool _photoBusy = false;

  /// Shown while the chosen photo is being sent.
  Uint8List? _previewBytes;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _initFrom(UserProfile profile) {
    if (_isInitialized) return;
    _nameController.text = profile.displayName ?? '';
    _bioController.text = profile.bio ?? '';
    _isDeaf = profile.isDeaf;
    _isInitialized = true;
  }

  /// The photo is saved as soon as it is chosen, independently of the form,
  /// so it shows everywhere right away.
  Future<void> _pickAndUploadPhoto(UserProfile profile) async {
    final l10n = AppLocalizations.of(context)!;
    XFile? image;
    try {
      image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
    } catch (_) {
      if (mounted) AppSnackbar.showError(context, l10n.accountPhotoPickError);
      return;
    }
    if (image == null || !mounted) return;

    Uint8List bytes;
    try {
      bytes = await image.readAsBytes();
    } catch (_) {
      if (mounted) AppSnackbar.showError(context, l10n.accountPhotoPickError);
      return;
    }
    if (!mounted) return;
    // Checked before sending so the user gets the precise reason at once.
    if (bytes.length > kMaxAvatarBytes) {
      AppSnackbar.showError(context, l10n.accountPhotoTooLarge);
      return;
    }
    if (StorageRepositoryImpl.detectImageType(bytes) == null) {
      AppSnackbar.showError(context, l10n.accountPhotoBadFormat);
      return;
    }

    setState(() {
      _previewBytes = bytes;
      _photoBusy = true;
    });
    try {
      final url = await ref
          .read(storageRepositoryProvider)
          .uploadAvatar(bytes: bytes, userId: profile.id);
      await ref.read(profileRepositoryProvider).updateAvatarUrl(profile.id, url);
      ref.invalidate(userProfileProvider);
      if (mounted) AppSnackbar.showSuccess(context, l10n.accountPhotoUpdated);
    } catch (e) {
      if (mounted) {
        setState(() => _previewBytes = null);
        AppSnackbar.showError(
          context,
          ref.userErrorText(e, l10n, fallback: l10n.accountPhotoUploadError),
        );
      }
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _removePhoto(UserProfile profile) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.accountRemovePhotoTitle,
      message: l10n.accountRemovePhotoMessage,
      confirmLabel: l10n.accountRemovePhoto,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _photoBusy = true);
    try {
      // Profile first: it must never point at a file that no longer exists.
      await ref.read(profileRepositoryProvider).updateAvatarUrl(profile.id, null);
      ref.invalidate(userProfileProvider);
      try {
        await ref.read(storageRepositoryProvider).deleteAvatar(profile.id);
      } catch (e) {
        debugPrint('[avatar] stored file not removed: $e');
      }
      if (mounted) {
        setState(() => _previewBytes = null);
        AppSnackbar.showSuccess(context, l10n.accountPhotoRemoved);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          ref.userErrorText(e, l10n, fallback: l10n.accountPhotoRemoveError),
        );
      }
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _save(UserProfile profile) async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isSaving = true);
    try {
      final bio = _bioController.text.trim();
      final current = ref.read(userProfileProvider).value ?? profile;
      await ref.read(profileRepositoryProvider).updateProfile(
            current.copyWith(
              displayName: _nameController.text.trim(),
              bio: bio.isEmpty ? null : bio,
              isDeaf: _isDeaf,
            ),
          );
      ref.invalidate(userProfileProvider);

      if (!mounted) return;
      AppSnackbar.showSuccess(context, l10n.profileUpdateSuccess);
      if (context.canPop()) {
        context.pop();
      } else {
        context.goNamed(AppRoutes.profileName);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          ref.userErrorText(e, l10n, fallback: l10n.accountSaveError),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editProfile)),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: AppSpacing.l,
          bottom: settingsBottomPadding(context),
        ),
        child: PageContainer.form(
          alignment: Alignment.topCenter,
          verticalPadding: 0,
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
              _initFrom(profile);
              return _buildForm(context, profile);
            },
            loading: () => const _EditProfileSkeleton(),
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

  Widget _buildForm(BuildContext context, UserProfile profile) {
    final l10n = AppLocalizations.of(context)!;
    final secondary = AppColors.textSecondary(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPanel(
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    _photoBusy && _previewBytes != null
                        ? ClipOval(
                            child: Image.memory(
                              _previewBytes!,
                              width: _avatarRadius * 2,
                              height: _avatarRadius * 2,
                              fit: BoxFit.cover,
                              semanticLabel: l10n.accountPhotoTitle,
                            ),
                          )
                        : Semantics(
                            image: true,
                            label: l10n.accountPhotoTitle,
                            child: ExcludeSemantics(
                              child: AppAvatar(
                                imageUrl: profile.avatarUrl,
                                name: _nameController.text.isEmpty
                                    ? profile.displayName
                                    : _nameController.text,
                                radius: _avatarRadius,
                              ),
                            ),
                          ),
                    if (_photoBusy)
                      Container(
                        width: _avatarRadius * 2,
                        height: _avatarRadius * 2,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black38,
                        ),
                        child: Center(
                          child: Semantics(
                            label: l10n.accountPhotoSending,
                            child: const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.accountPhotoTitle,
                        style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${l10n.accountPhotoHint} ${l10n.accountPhotoRules}',
                        style: AppTextStyles.bodySmall.copyWith(color: secondary),
                      ),
                      const SizedBox(height: AppSpacing.s),
                      Wrap(
                        spacing: AppSpacing.s,
                        runSpacing: AppSpacing.s,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _isSaving || _photoBusy
                                ? null
                                : () => _pickAndUploadPhoto(profile),
                            icon: const Icon(AppIcons.camera, size: 18),
                            label: Text(
                              profile.avatarUrl == null
                                  ? l10n.accountAddPhoto
                                  : l10n.accountChangePhoto,
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, kMinTouchTarget),
                              shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusM),
                            ),
                          ),
                          if (profile.avatarUrl != null)
                            TextButton.icon(
                              onPressed: _isSaving || _photoBusy
                                  ? null
                                  : () => _removePhoto(profile),
                              icon: const Icon(AppIcons.delete, size: 18),
                              label: Text(l10n.accountRemovePhoto),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.error,
                                minimumSize: const Size(0, kMinTouchTarget),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            label: l10n.displayName,
            controller: _nameController,
            validator: (v) => (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
          ),
          const SizedBox(height: AppSpacing.l),
          AppTextField(
            label: l10n.bio,
            controller: _bioController,
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.xl),
          SettingsGroup(
            title: l10n.accountAccessibility,
            footer: l10n.accountDeafSwitchHint,
            children: [
              SettingsSwitchTile(
                icon: PhosphorIconsRegular.ear,
                title: l10n.accountDeafSwitch,
                value: _isDeaf,
                onChanged: _isSaving ? null : (v) => setState(() => _isDeaf = v),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: AppButton(
              label: l10n.save,
              isLoading: _isSaving,
              onPressed: () => _save(profile),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditProfileSkeleton extends StatelessWidget {
  const _EditProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    final outline = BoxDecoration(
      border: Border.all(color: Colors.white),
      borderRadius: AppRadius.radiusL,
    );

    return Skeleton(
      label: AppLocalizations.of(context)!.loading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: outline,
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
                        SkeletonBlock(width: 120, height: 16),
                        SizedBox(height: AppSpacing.s),
                        SkeletonBlock(width: 200, height: 12),
                        SizedBox(height: AppSpacing.s),
                        SkeletonBlock(width: 150, height: kMinTouchTarget, radius: AppRadius.m),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SkeletonBlock(height: 58, radius: AppRadius.l),
          const SizedBox(height: AppSpacing.l),
          const SkeletonBlock(height: 106, radius: AppRadius.l),
          const SizedBox(height: AppSpacing.xl),
          const Padding(
            padding: EdgeInsets.only(left: AppSpacing.m, bottom: AppSpacing.s),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SkeletonBlock(width: 120, height: 14),
            ),
          ),
          DecoratedBox(
            decoration: outline,
            child: const SettingsRowSkeleton(lines: 2),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: SkeletonBlock(
              width: context.isMobile ? double.infinity : AppButton.desktopMaxWidth,
              height: AppButton.height,
              radius: AppRadius.l,
            ),
          ),
        ],
      ),
    );
  }
}
