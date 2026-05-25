// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Sign _$SignFromJson(Map<String, dynamic> json) => _Sign(
  id: json['id'] as String,
  signLanguageId: (json['sign_language_id'] as num?)?.toInt(),
  categoryId: (json['category_id'] as num?)?.toInt(),
  word: json['word'] as String,
  description: json['description'] as String?,
  difficultyLevel: (json['difficulty_level'] as num?)?.toInt() ?? 1,
  videoUrl: json['video_url'] as String?,
  thumbnailUrl: json['thumbnail_url'] as String?,
  model3dUrl: json['model_3d_url'] as String?,
  landmarkData: json['landmark_data'] as Map<String, dynamic>?,
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
  exampleSentence: json['example_sentence'] as String?,
  isValidated: json['is_validated'] as bool? ?? false,
  contributorId: json['contributor_id'] as String?,
  viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$SignToJson(_Sign instance) => <String, dynamic>{
  'id': instance.id,
  'sign_language_id': instance.signLanguageId,
  'category_id': instance.categoryId,
  'word': instance.word,
  'description': instance.description,
  'difficulty_level': instance.difficultyLevel,
  'video_url': instance.videoUrl,
  'thumbnail_url': instance.thumbnailUrl,
  'model_3d_url': instance.model3dUrl,
  'landmark_data': instance.landmarkData,
  'tags': instance.tags,
  'example_sentence': instance.exampleSentence,
  'is_validated': instance.isValidated,
  'contributor_id': instance.contributorId,
  'view_count': instance.viewCount,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};
