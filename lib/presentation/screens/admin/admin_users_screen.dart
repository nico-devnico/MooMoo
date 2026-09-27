import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/user_profile.dart';
import '../../../domain/providers/admin_provider.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/adaptive_card_list.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_loader.dart';
import '../../widgets/app_snackbar.dart';
import 'admin_shell.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _searchController = TextEditingController();
  String? _query;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final usersAsync = ref.watch(adminUsersProvider(_query));
    final currentUser = ref.watch(currentUserProvider);

    return AdminShell(
      selectedIndex: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.l, AppSpacing.l, AppSpacing.s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.adminUsers, style: AppTextStyles.h2),
                const SizedBox(height: AppSpacing.s),
                Text(l10n.adminUsersSubtitle, style: AppTextStyles.bodyMedium),
                const SizedBox(height: AppSpacing.m),
                TextField(
                  controller: _searchController,
                  onSubmitted: (v) => setState(() => _query = v.trim().isEmpty ? null : v.trim()),
                  decoration: InputDecoration(
                    hintText: l10n.searchUsers,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => setState(
                        () => _query = _searchController.text.trim().isEmpty
                            ? null
                            : _searchController.text.trim(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(adminUsersProvider(_query)),
              child: usersAsync.when(
                data: (users) {
                  if (users.isEmpty) {
                    return ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.45,
                          child: AppEmptyState(
                            title: l10n.adminNoUsers,
                            message: l10n.adminNoUsersMessage,
                            imagePath: null,
                          ),
                        ),
                      ],
                    );
                  }
                  return AdaptiveCardList(
                    itemCount: users.length,
                    maxColumns: 2,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final isSelf = currentUser?.id == user.id;
                      return _UserAdminTile(
                        profile: user,
                        isSelf: isSelf,
                        onToggleAdmin: isSelf ? null : () => _toggleAdmin(user),
                      );
                    },
                  );
                },
                loading: () => const Center(child: AppLoader()),
                error: (e, _) => AppEmptyState(
                  title: l10n.errorGeneric,
                  message: e.toString(),
                  imagePath: null,
                  actionLabel: l10n.retry,
                  onAction: () => ref.invalidate(adminUsersProvider(_query)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAdmin(UserProfile profile) async {
    final l10n = AppLocalizations.of(context)!;
    final makeAdmin = !profile.isAdmin;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(makeAdmin ? l10n.grantAdmin : l10n.revokeAdmin),
        content: Text(
          makeAdmin
              ? l10n.grantAdminConfirm(profile.displayName ?? profile.email ?? profile.id)
              : l10n.revokeAdminConfirm(profile.displayName ?? profile.email ?? profile.id),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.confirm)),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(adminRepositoryProvider).setUserAdmin(profile.id, makeAdmin);
      ref.invalidate(adminUsersProvider(_query));
      if (mounted) {
        AppSnackbar.show(context, message: l10n.userUpdated, type: AppSnackbarType.success);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, message: '${l10n.errorGeneric}: $e', type: AppSnackbarType.error);
      }
    }
  }
}

class _UserAdminTile extends StatelessWidget {
  final UserProfile profile;
  final bool isSelf;
  final VoidCallback? onToggleAdmin;

  const _UserAdminTile({
    required this.profile,
    required this.isSelf,
    this.onToggleAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = profile.displayName ?? profile.email ?? l10n.guest;

    return AppCard(
      child: Row(
        children: [
          AppAvatar(imageUrl: profile.avatarUrl, name: name, radius: 28),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelf) ...[
                      const SizedBox(width: 8),
                      AppBadge(label: l10n.you, color: AppColors.info),
                    ],
                  ],
                ),
                if (profile.email != null)
                  Text(profile.email!, style: AppTextStyles.bodySmall),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (profile.isAdmin)
                      AppBadge(label: l10n.adminRole, color: AppColors.primary),
                    if (profile.isDeaf)
                      AppBadge(label: l10n.deafUser, color: AppColors.secondary),
                    AppBadge(
                      label: profile.preferredSignLanguage,
                      color: AppColors.textSecondaryLight,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onToggleAdmin != null)
            IconButton(
              tooltip: profile.isAdmin ? l10n.revokeAdmin : l10n.grantAdmin,
              onPressed: onToggleAdmin,
              icon: Icon(
                profile.isAdmin ? Icons.shield : Icons.shield_outlined,
                color: profile.isAdmin ? AppColors.primary : AppColors.textSecondaryLight,
              ),
            ),
        ],
      ),
    );
  }
}
