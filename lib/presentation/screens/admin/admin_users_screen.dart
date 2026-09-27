import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../domain/providers/admin_provider.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/skeletons.dart';
import 'admin_shell.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _searchController = TextEditingController();
  AdminUsersFilter _filter = const AdminUsersFilter();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    final text = _searchController.text.trim();
    setState(() => _filter = AdminUsersFilter(
          query: text.isEmpty ? null : text,
          status: _filter.status,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final usersAsync = ref.watch(adminUsersProvider(_filter));
    final currentUser = ref.watch(currentUserProvider);

    return AdminShell(
      selectedIndex: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              AppSpacing.l,
              AppSpacing.l,
              AppSpacing.s,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.adminUsers, style: AppTextStyles.h2),
                    const SizedBox(height: AppSpacing.s),
                    Text(l10n.adminUsersSubtitle, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: AppSpacing.m),
                    TextField(
                      controller: _searchController,
                      onSubmitted: (_) => _search(),
                      decoration: InputDecoration(
                        hintText: l10n.searchUsers,
                        prefixIcon: const Icon(AppIcons.search),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Wrap(
                      spacing: AppSpacing.s,
                      runSpacing: AppSpacing.s,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _StatusChip(
                          label: l10n.filterAll,
                          selected: _filter.status == null,
                          onTap: () => setState(
                            () => _filter = AdminUsersFilter(query: _filter.query),
                          ),
                        ),
                        _StatusChip(
                          label: l10n.statusActive,
                          selected: _filter.status == 'active',
                          onTap: () => setState(
                            () => _filter = AdminUsersFilter(
                              query: _filter.query,
                              status: 'active',
                            ),
                          ),
                        ),
                        _StatusChip(
                          label: l10n.statusSuspended,
                          selected: _filter.status == 'suspended',
                          onTap: () => setState(
                            () => _filter = AdminUsersFilter(
                              query: _filter.query,
                              status: 'suspended',
                            ),
                          ),
                        ),
                        AppButton(
                          label: l10n.addUser,
                          icon: AppIcons.userAdd,
                          fullWidth: false,
                          onPressed: _createUser,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: usersAsync.when(
              data: (users) {
                if (users.isEmpty) {
                  return AppEmptyState(
                    title: l10n.adminNoUsers,
                    message: l10n.adminNoUsersMessage,
                    imagePath: null,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.l,
                    AppSpacing.s,
                    AppSpacing.l,
                    AppSpacing.xl,
                  ),
                  itemCount: users.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: _UserAdminTile(
                          profile: user,
                          isSelf: currentUser?.id == user.id,
                          onEdit: () => _editUser(user),
                          onRoles: () => _editRoles(user),
                          onSuspend: user.status == 'suspended'
                              ? () => _unsuspend(user)
                              : () => _suspend(user),
                          onDelete: currentUser?.id == user.id
                              ? null
                              : () => _delete(user),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.l),
                child: SkeletonList(itemCount: 6, hasTrailing: true),
              ),
              error: (e, _) => AppEmptyState(
                title: l10n.errorGeneric,
                message: e.toString(),
                imagePath: null,
                actionLabel: l10n.retry,
                onAction: () => ref.invalidate(adminUsersProvider(_filter)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  AdminRepository get _repo => ref.read(adminRepositoryProvider);

  void _refresh() => ref.invalidate(adminUsersProvider(_filter));

  Future<void> _run(Future<void> Function() action, String success) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await action();
      _refresh();
      if (mounted) {
        AppSnackbar.show(context, message: success, type: AppSnackbarType.success);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(
          context,
          message: '${l10n.errorGeneric}: $e',
          type: AppSnackbarType.error,
        );
      }
    }
  }

  Future<void> _createUser() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await _showForm(
      title: l10n.addUser,
      fields: [
        _Field.email(),
        _Field.password(),
        _Field.name(),
      ],
      roles: const [],
    );
    if (result == null) return;
    await _run(
      () => _repo.createUser(
        email: result.text['email']!,
        password: result.text['password']!,
        displayName: result.text['name'],
        roles: result.roles,
      ),
      l10n.userCreated,
    );
  }

  Future<void> _editUser(UserProfile user) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await _showForm(
      title: l10n.editUser,
      fields: [
        _Field.name(initial: user.displayName),
        _Field.bio(initial: user.bio),
      ],
    );
    if (result == null) return;
    await _run(
      () => _repo.updateUserProfile(
        user.id,
        displayName: result.text['name'],
        bio: result.text['bio'],
      ),
      l10n.userUpdated,
    );
  }

  Future<void> _editRoles(UserProfile user) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await _showForm(
      title: l10n.manageRoles,
      fields: const [],
      roles: user.roles,
    );
    if (result == null) return;
    await _run(() => _repo.setUserRoles(user.id, result.roles), l10n.userUpdated);
  }

  Future<void> _suspend(UserProfile user) async {
    final l10n = AppLocalizations.of(context)!;
    final name = user.displayName ?? user.email ?? user.id;
    final result = await _showForm(
      title: l10n.suspendConfirm(name),
      fields: [_Field.reason()],
    );
    if (result == null) return;
    await _run(
      () => _repo.suspendUser(user.id, reason: result.text['reason']!),
      l10n.userSuspended,
    );
  }

  Future<void> _unsuspend(UserProfile user) async {
    final l10n = AppLocalizations.of(context)!;
    await _run(() => _repo.unsuspendUser(user.id), l10n.userReactivated);
  }

  Future<void> _delete(UserProfile user) async {
    final l10n = AppLocalizations.of(context)!;
    final name = user.displayName ?? user.email ?? user.id;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAccount),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(l10n.deleteAccountConfirm(name)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.deleteAccount),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() => _repo.deleteUser(user.id), l10n.userDeleted);
  }

  Future<_FormResult?> _showForm({
    required String title,
    required List<_Field> fields,
    List<String>? roles,
  }) {
    return showDialog<_FormResult>(
      context: context,
      builder: (context) => _UserFormDialog(
        title: title,
        fields: fields,
        initialRoles: roles,
      ),
    );
  }
}

class _Field {
  const _Field(this.key, this.label, {this.obscure = false, this.initial});

  factory _Field.email() => const _Field('email', 'Email');
  factory _Field.password() => _Field('password', '', obscure: true);
  factory _Field.name({String? initial}) => _Field('name', '', initial: initial);
  factory _Field.bio({String? initial}) => _Field('bio', '', initial: initial);
  factory _Field.reason() => const _Field('reason', '');

  final String key;
  final String label;
  final bool obscure;
  final String? initial;
}

class _FormResult {
  const _FormResult(this.text, this.roles);

  final Map<String, String> text;
  final List<String> roles;
}

class _UserFormDialog extends StatefulWidget {
  const _UserFormDialog({
    required this.title,
    required this.fields,
    this.initialRoles,
  });

  final String title;
  final List<_Field> fields;
  final List<String>? initialRoles;

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  late final Map<String, TextEditingController> _controllers;
  late final Set<String> _roles;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final field in widget.fields)
        field.key: TextEditingController(text: field.initial ?? ''),
    };
    _roles = {...?widget.initialRoles};
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = {
      'email': 'Email',
      'password': l10n.password,
      'name': l10n.displayName,
      'bio': l10n.bio,
      'reason': l10n.suspendReason,
    };
    final roleLabels = {
      AppRole.admin: l10n.adminRole,
      AppRole.teacher: l10n.roleTeacher,
      AppRole.signExpert: l10n.roleExpert,
    };

    return AlertDialog(
      title: Text(widget.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final field in widget.fields) ...[
                TextField(
                  controller: _controllers[field.key],
                  obscureText: field.obscure,
                  decoration: InputDecoration(labelText: labels[field.key]),
                ),
                const SizedBox(height: AppSpacing.m),
              ],
              if (widget.initialRoles != null)
                for (final role in AppRole.all)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _roles.contains(role),
                    title: Text(roleLabels[role]!),
                    onChanged: (checked) => setState(() {
                      if (checked ?? false) {
                        _roles.add(role);
                      } else {
                        _roles.remove(role);
                      }
                    }),
                  ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        AppButton(
          label: l10n.confirm,
          fullWidth: false,
          onPressed: () => Navigator.pop(
            context,
            _FormResult(
              {for (final e in _controllers.entries) e.key: e.value.text.trim()},
              _roles.toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _UserAdminTile extends StatelessWidget {
  const _UserAdminTile({
    required this.profile,
    required this.isSelf,
    required this.onEdit,
    required this.onRoles,
    required this.onSuspend,
    this.onDelete,
  });

  final UserProfile profile;
  final bool isSelf;
  final VoidCallback onEdit;
  final VoidCallback onRoles;
  final VoidCallback onSuspend;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = profile.displayName ?? profile.email ?? l10n.guest;
    final suspended = profile.status == 'suspended';
    final roleLabels = {
      AppRole.admin: l10n.adminRole,
      AppRole.teacher: l10n.roleTeacher,
      AppRole.signExpert: l10n.roleExpert,
    };

    return AppCard(
      child: Row(
        children: [
          AppAvatar(imageUrl: profile.avatarUrl, name: name, radius: 24),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                if (profile.email != null)
                  Text(profile.email!, style: AppTextStyles.bodySmall),
                const SizedBox(height: AppSpacing.s),
                Wrap(
                  spacing: AppSpacing.s,
                  runSpacing: AppSpacing.xs,
                  children: [
                    AppBadge(
                      label: suspended ? l10n.statusSuspended : l10n.statusActive,
                      color: suspended ? AppColors.error : AppColors.success,
                    ),
                    for (final role in profile.roles)
                      AppBadge(
                        label: roleLabels[role] ?? role,
                        color: AppColors.primary,
                      ),
                    if (isSelf) AppBadge(label: l10n.you, color: AppColors.info),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: l10n.manageRoles,
            icon: const Icon(AppIcons.settings),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  onEdit();
                case 'roles':
                  onRoles();
                case 'suspend':
                  onSuspend();
                case 'delete':
                  onDelete?.call();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'edit', child: Text(l10n.editUser)),
              PopupMenuItem(value: 'roles', child: Text(l10n.manageRoles)),
              PopupMenuItem(
                value: 'suspend',
                child: Text(suspended ? l10n.unsuspendAccount : l10n.suspendAccount),
              ),
              if (onDelete != null)
                PopupMenuItem(value: 'delete', child: Text(l10n.deleteAccount)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
