import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/notification.dart' as model;
import '../../../domain/providers/notification_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_snackbar.dart';
import '../settings/settings_screen.dart';

const _typesWithDefaultAction = {'lesson', 'contribution', 'welcome'};

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  Future<void> _markAllRead(
    BuildContext context,
    WidgetRef ref,
    List<model.Notification> unread,
  ) async {
    final repository = ref.read(notificationRepositoryProvider);
    try {
      await Future.wait(unread.map((n) => repository.markAsRead(n.id)));
      ref.invalidate(notificationsProvider);
    } catch (_) {
      if (context.mounted) {
        AppSnackbar.showError(context, AppLocalizations.of(context)!.errorGeneric);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notificationsAsync = ref.watch(notificationsProvider);
    final unread = notificationsAsync.value?.where((n) => !n.isRead).toList() ??
        const <model.Notification>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        actions: [
          if (unread.isNotEmpty)
            IconButton(
              icon: const Icon(PhosphorIconsRegular.checks),
              tooltip: l10n.accountMarkAllRead,
              onPressed: () => _markAllRead(context, ref, unread),
            ),
          const SizedBox(width: AppSpacing.s),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: AppSpacing.l,
          bottom: settingsBottomPadding(context),
        ),
        child: PageContainer.reading(
          child: notificationsAsync.when(
            data: (notifications) {
              if (notifications.isEmpty) {
                return AppEmptyState(
                  icon: AppIcons.notification,
                  title: l10n.noNotifications,
                  message: l10n.accountNotificationsEmptyMessage,
                );
              }
              return SettingsGroup(
                children: [
                  for (final notification in notifications)
                    _NotificationTile(notification: notification),
                ],
              );
            },
            loading: () => const SettingsSkeleton(
              groups: [6],
              lines: 3,
              circle: true,
              showTitles: false,
            ),
            error: (_, _) => AppEmptyState(
              icon: AppIcons.error,
              title: l10n.errorGeneric,
              message: l10n.accountLoadErrorMessage,
              actionLabel: l10n.retry,
              onAction: () => ref.invalidate(notificationsProvider),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final model.Notification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final secondary = AppColors.textSecondary(context);
    final (icon, color) = _visualFor(notification.type);
    final body = notification.body?.trim();
    final hasBody = body != null && body.isNotEmpty;
    final date = _formatDate(context, notification.createdAt);
    final unread = !notification.isRead;

    return Semantics(
      button: true,
      label: [
        if (unread) l10n.accountUnread,
        notification.title,
        if (hasBody) body,
        if (date.isNotEmpty) date,
      ].join(', '),
      excludeSemantics: true,
      child: InkWell(
        onTap: () => _open(context, ref),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinTouchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SettingsIcon(icon, color: color, circle: true),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      if (hasBody) ...[
                        const SizedBox(height: 2),
                        Text(
                          body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium.copyWith(color: secondary),
                        ),
                      ],
                      if (date.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(date, style: AppTextStyles.bodySmall.copyWith(color: secondary)),
                      ],
                    ],
                  ),
                ),
                if (unread) ...[
                  const SizedBox(width: AppSpacing.s),
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 7),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, WidgetRef ref) {
    if (!notification.isRead) {
      ref.read(notificationRepositoryProvider).markAsRead(notification.id).catchError((_) {});
    }
    final body = notification.body?.trim();
    if (body != null && body.isNotEmpty) {
      _showDetail(context);
    } else {
      _navigate(context);
    }
  }

  void _showDetail(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (icon, color) = _visualFor(notification.type);
    final hasAction = notification.payload?['route'] != null ||
        _typesWithDefaultAction.contains(notification.type);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(icon, color: color),
        title: Text(notification.title),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(child: Text(notification.body ?? '')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.accountClose),
          ),
          if (hasAction)
            FilledButton(
              autofocus: true,
              onPressed: () {
                Navigator.pop(dialogContext);
                _navigate(context);
              },
              child: Text(l10n.accountSeeMore),
            ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context) {
    final route = notification.payload?['route'];
    if (route is String) {
      final params = notification.payload?['params'];
      try {
        context.pushNamed(
          route,
          pathParameters: params is Map
              ? params.map((k, v) => MapEntry(k.toString(), v.toString()))
              : const {},
        );
      } catch (_) {
        // Route inconnue dans une notification envoyée par le serveur : on
        // reste sur la liste plutôt que de planter.
      }
      return;
    }

    switch (notification.type) {
      case 'lesson':
        context.goNamed(AppRoutes.learningName);
      case 'contribution':
        context.goNamed(AppRoutes.contributeName);
      case 'welcome':
        context.goNamed(AppRoutes.profileName);
    }
  }

  static (IconData, Color) _visualFor(String type) => switch (type) {
        'system' => (AppIcons.info, AppColors.primary),
        'lesson' => (AppIcons.lesson, AppColors.success),
        'community' => (AppIcons.users, AppColors.warning),
        'contribution' => (AppIcons.upload, AppColors.primary),
        _ => (AppIcons.notification, AppColors.primary),
      };

  static String _formatDate(BuildContext context, DateTime? date) {
    if (date == null) return '';
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).add_Hm().format(date.toLocal());
  }
}
