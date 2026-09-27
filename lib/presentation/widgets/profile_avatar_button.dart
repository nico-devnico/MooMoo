import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../domain/providers/profile_provider.dart';
import '../../l10n/app_localizations.dart';
import 'app_avatar.dart';

/// The user's photo, opening the profile. The main navigation has no profile
/// link: this button is the entry to it.
class ProfileAvatarButton extends ConsumerWidget {
  const ProfileAvatarButton({super.key, this.selected = false, this.onTap});

  final bool selected;
  final VoidCallback? onTap;

  static const double _radius = 18;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(userProfileProvider);

    return Semantics(
      button: true,
      selected: selected,
      label: l10n.profile,
      child: Tooltip(
        message: l10n.profile,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap ?? () => context.goNamed(AppRoutes.profileName),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: profileAsync.when(
              data: (profile) => AppAvatar(
                imageUrl: profile?.avatarUrl,
                name: profile?.displayName,
                radius: _radius,
              ),
              loading: () => const CircleAvatar(
                radius: _radius,
                backgroundColor: AppColors.primarySoft,
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, _) => const CircleAvatar(
                radius: _radius,
                backgroundColor: AppColors.primarySoft,
                child: Icon(AppIcons.profile, color: AppColors.primary, size: 20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
