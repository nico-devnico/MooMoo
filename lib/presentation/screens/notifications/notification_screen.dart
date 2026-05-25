import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/providers/notification_provider.dart';
import '../../../data/models/notification.dart' as model;
import '../../widgets/app_loader.dart';
import '../../../l10n/app_localizations.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        centerTitle: true,
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: AppColors.neutralDark.withOpacity(0.2)),
                  const SizedBox(height: AppSpacing.m),
                  Text(l10n.noNotifications, style: AppTextStyles.bodyLarge),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.l),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationTile(notification: notification);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final model.Notification notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _getNotificationColor(notification.type).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _getNotificationIcon(notification.type),
          color: _getNotificationColor(notification.type),
          size: 24,
        ),
      ),
      title: Text(
        notification.title,
        style: AppTextStyles.bodyLarge.copyWith(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (notification.body != null)
            Text(
              notification.body!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            _formatDate(notification.createdAt),
            style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
          ),
        ],
      ),
      trailing: !notification.isRead
          ? Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            )
          : null,
      onTap: () {
        if (!notification.isRead) {
          ref.read(notificationRepositoryProvider).markAsRead(notification.id);
        }
        
        // Afficher d'abord le détail de la notification si elle a un corps
        if (notification.body != null && notification.body!.isNotEmpty) {
          _showNotificationDetail(context, notification);
        } else {
          _navigateBasedOnNotification(context, notification);
        }
      },
    );
  }

  void _showNotificationDetail(BuildContext context, model.Notification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getNotificationIcon(notification.type), color: _getNotificationColor(notification.type)),
            const SizedBox(width: AppSpacing.s),
            Expanded(child: Text(notification.title)),
          ],
        ),
        content: Text(notification.body ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          if (notification.payload != null || _hasDefaultAction(notification.type))
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateBasedOnNotification(context, notification);
              },
              child: const Text('Voir plus'),
            ),
        ],
      ),
    );
  }

  bool _hasDefaultAction(String type) {
    return ['lesson', 'contribution', 'welcome'].contains(type);
  }

  void _navigateBasedOnNotification(BuildContext context, model.Notification notification) {
    // Navigation logique basée sur le type de notification
    if (notification.payload != null && notification.payload!['route'] != null) {
      final route = notification.payload!['route'] as String;
      final params = notification.payload!['params'] as Map<String, dynamic>?;
      
      if (params != null) {
        context.pushNamed(route, pathParameters: params.map((k, v) => MapEntry(k, v.toString())));
      } else {
        context.pushNamed(route);
      }
    } else {
      // Actions par défaut selon le type
      switch (notification.type) {
        case 'lesson':
          context.pushNamed(AppRoutes.learningName);
          break;
        case 'contribution':
          context.pushNamed(AppRoutes.contributeName);
          break;
        case 'welcome':
          context.pushNamed(AppRoutes.profileName);
          break;
        default:
          // Pas d'action de navigation spécifique
          break;
      }
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'system':
        return Icons.info_outline;
      case 'lesson':
        return Icons.school_outlined;
      case 'community':
        return Icons.people_outline;
      case 'contribution':
        return Icons.cloud_upload_outlined;
      default:
        return Icons.notifications_none;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'system':
        return Colors.blue;
      case 'lesson':
        return AppColors.secondary;
      case 'community':
        return Colors.orange;
      case 'contribution':
        return AppColors.primary;
      default:
        return AppColors.primary;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat.yMMMd().add_Hm().format(date);
  }
}
