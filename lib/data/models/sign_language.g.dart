// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_language.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SignLanguage _$SignLanguageFromJson(Map<String, dynamic> json) =>
    _SignLanguage(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
      name: json['name'] as String,
      country: json['country'] as String?,
      flagEmoji: json['flag_emoji'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );

Map<String, dynamic> _$SignLanguageToJson(_SignLanguage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'country': instance.country,
      'flag_emoji': instance.flagEmoji,
      'is_active': instance.isActive,
    };
