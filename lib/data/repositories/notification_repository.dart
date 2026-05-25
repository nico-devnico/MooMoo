import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart' as model;

abstract class NotificationRepository {
  Future<List<model.Notification>> getNotifications(String userId);
  Future<void> markAsRead(String notificationId);
  Stream<List<model.Notification>> watchNotifications(String userId);
}

class NotificationRepositoryImpl implements NotificationRepository {
  final SupabaseClient _supabase;

  NotificationRepositoryImpl(this._supabase);

  @override
  Future<List<model.Notification>> getNotifications(String userId) async {
    final response = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => model.Notification.fromJson(json)).toList();
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  @override
  Stream<List<model.Notification>> watchNotifications(String userId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => model.Notification.fromJson(json)).toList());
  }
}
