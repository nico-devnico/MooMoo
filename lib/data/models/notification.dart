import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification.freezed.dart';
part 'notification.g.dart';

@freezed
abstract class Notification with _$Notification {
  const factory Notification({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required String type,
    required String title,
    String? body,
    @JsonKey(name: 'is_read') @Default(false) bool isRead,
    Map<String, dynamic>? payload,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Notification;

  factory Notification.fromJson(Map<String, dynamic> json) => _$NotificationFromJson(json);
}
