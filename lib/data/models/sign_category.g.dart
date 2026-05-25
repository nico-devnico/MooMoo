// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SignCategory _$SignCategoryFromJson(Map<String, dynamic> json) =>
    _SignCategory(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      slug: json['slug'] as String,
      iconName: json['icon_name'] as String?,
      colorHex: json['color_hex'] as String?,
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
      signLanguageId: (json['sign_language_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SignCategoryToJson(_SignCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'icon_name': instance.iconName,
      'color_hex': instance.colorHex,
      'order_index': instance.orderIndex,
      'sign_language_id': instance.signLanguageId,
    };
