import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart' as model;

const notificationColumns =
    'id,user_id,type,title,body,is_read,payload,created_at';

abstract class NotificationRepository {
  Future<List<model.Notification>> getNotifications(
    String userId, {
    int limit = 50,
    int offset = 0,
  });
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
  Stream<List<model.Notification>> watchNotifications(String userId);
}

class NotificationRepositoryImpl implements NotificationRepository {
  final SupabaseClient _supabase;

  NotificationRepositoryImpl(this._supabase);

  @override
  Future<List<model.Notification>> getNotifications(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _supabase
        .from('notifications')
        .select(notificationColumns)
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) =>
            model.Notification.fromJson(json as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  @override
  Stream<List<model.Notification>> watchNotifications(String userId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50)
        .map((data) => data
            .map((json) => model.Notification.fromJson(json))
            .toList(growable: false));
  }
}
