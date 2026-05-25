// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'translation_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TranslationEntry _$TranslationEntryFromJson(Map<String, dynamic> json) =>
    _TranslationEntry(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      userId: json['user_id'] as String?,
      direction: json['direction'] as String,
      sourceText: json['source_text'] as String?,
      sourceVideoUrl: json['source_video_url'] as String?,
      sourceAudioUrl: json['source_audio_url'] as String?,
      translatedText: json['translated_text'] as String?,
      translatedAudioUrl: json['translated_audio_url'] as String?,
      signIds: (json['sign_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      userRating: (json['user_rating'] as num?)?.toInt(),
      note: json['note'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$TranslationEntryToJson(_TranslationEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'session_id': instance.sessionId,
      'user_id': instance.userId,
      'direction': instance.direction,
      'source_text': instance.sourceText,
      'source_video_url': instance.sourceVideoUrl,
      'source_audio_url': instance.sourceAudioUrl,
      'translated_text': instance.translatedText,
      'translated_audio_url': instance.translatedAudioUrl,
      'sign_ids': instance.signIds,
      'user_rating': instance.userRating,
      'note': instance.note,
      'created_at': instance.createdAt?.toIso8601String(),
    };
