import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/notification.dart';
import '../../data/repositories/notification_repository.dart';
import 'auth_provider.dart';

part 'notification_provider.g.dart';

@riverpod
NotificationRepository notificationRepository(Ref ref) {
  return NotificationRepositoryImpl(ref.watch(supabaseClientProvider));
}

@riverpod
Stream<List<Notification>> notifications(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  return ref.watch(notificationRepositoryProvider).watchNotifications(user.id);
}

@riverpod
Future<int> unreadNotificationsCount(Ref ref) async {
  final notifications = await ref.watch(notificationsProvider.future);
  return notifications.where((n) => !n.isRead).length;
}
