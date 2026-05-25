import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/providers/profile_provider.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/storage_provider.dart';
import '../../../data/models/user_profile.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_avatar.dart';
import '../../../l10n/app_localizations.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  bool _isLoading = false;
  bool _isInitialized = false;
  XFile? _imageFile;
  String? _currentAvatarUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );

    if (image != null) {
      setState(() {
        _imageFile = image;
      });
    }
  }

  Future<void> _saveProfile(UserProfile profile) async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isLoading = true);
    try {
      String? newAvatarUrl = profile.avatarUrl;

      // 1. Upload image if picked
      if (_imageFile != null) {
        final storageRepo = ref.read(storageRepositoryProvider);
        if (kIsWeb) {
          final bytes = await _imageFile!.readAsBytes();
          newAvatarUrl = await storageRepo.uploadAvatar(
            bytes: bytes,
            userId: profile.id,
          );
        } else {
          newAvatarUrl = await storageRepo.uploadAvatar(
            path: _imageFile!.path,
            userId: profile.id,
          );
        }
        
        // Add timestamp to bust cache
        newAvatarUrl = '$newAvatarUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      }

      // 2. Update profile
      final updatedProfile = profile.copyWith(
        displayName: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        avatarUrl: newAvatarUrl,
      );
      
      await ref.read(profileRepositoryProvider).updateProfile(updatedProfile);
      
      // Force refresh the profile provider
      ref.invalidate(userProfileProvider);

      if (mounted) {
        AppSnackbar.show(context, message: l10n.profileUpdateSuccess, type: AppSnackbarType.success);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, message: 'Erreur : $e', type: AppSnackbarType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editProfile)),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) return Center(child: Text(l10n.profileNotFound));
          
          if (!_isInitialized) {
            _nameController.text = profile.displayName ?? '';
            _bioController.text = profile.bio ?? '';
            _currentAvatarUrl = profile.avatarUrl;
            _isInitialized = true;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Center(
                    child: Stack(
                      children: [
                        _imageFile != null
                            ? CircleAvatar(
                                radius: 60,
                                backgroundImage: kIsWeb
                                    ? NetworkImage(_imageFile!.path)
                                    : FileImage(File(_imageFile!.path)) as ImageProvider,
                              )
                            : AppAvatar(
                                imageUrl: _currentAvatarUrl,
                                name: profile.displayName,
                                radius: 60,
                              ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: CircleAvatar(
                            backgroundColor: AppColors.primary,
                            radius: 18,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                              onPressed: _pickImage,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppTextField(
                    label: l10n.displayName,
                    controller: _nameController,
                    validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null,
                  ),
                  const SizedBox(height: AppSpacing.l),
                  AppTextField(
                    label: l10n.bio,
                    controller: _bioController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: l10n.save,
                    isLoading: _isLoading,
                    onPressed: () => _saveProfile(profile),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Erreur : $e')),
      ),
    );
  }
}
