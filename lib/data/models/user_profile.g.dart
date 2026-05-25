// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => _UserProfile(
  id: json['id'] as String,
  email: json['email'] as String?,
  displayName: json['display_name'] as String?,
  avatarUrl: json['avatar_url'] as String?,
  bio: json['bio'] as String?,
  preferredSignLanguage: json['preferred_sign_language'] as String? ?? 'LSF',
  preferredOutput: json['preferred_output'] as String? ?? 'text',
  preferredView: json['preferred_view'] as String? ?? '3d',
  isDeaf: json['is_deaf'] as bool? ?? false,
  threeDAutoRotate: json['three_d_auto_rotate'] as bool? ?? false,
  threeDZoomEnabled: json['three_d_zoom_enabled'] as bool? ?? true,
  selectedCharacterId: json['selected_character_id'] as String? ?? 'alex',
  theme: json['theme'] as String? ?? 'system',
  locale: json['locale'] as String? ?? 'fr',
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$UserProfileToJson(_UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'display_name': instance.displayName,
      'avatar_url': instance.avatarUrl,
      'bio': instance.bio,
      'preferred_sign_language': instance.preferredSignLanguage,
      'preferred_output': instance.preferredOutput,
      'preferred_view': instance.preferredView,
      'is_deaf': instance.isDeaf,
      'theme': instance.theme,
      'locale': instance.locale,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
