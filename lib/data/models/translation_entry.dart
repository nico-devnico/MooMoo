import 'package:freezed_annotation/freezed_annotation.dart';

part 'translation_entry.freezed.dart';
part 'translation_entry.g.dart';

@freezed
abstract class TranslationEntry with _$TranslationEntry {
  const factory TranslationEntry({
    required String id,
    @JsonKey(name: 'session_id') required String sessionId,
    @JsonKey(name: 'user_id') String? userId,
    required String direction,
    @JsonKey(name: 'source_text') String? sourceText,
    @JsonKey(name: 'source_video_url') String? sourceVideoUrl,
    @JsonKey(name: 'source_audio_url') String? sourceAudioUrl,
    @JsonKey(name: 'translated_text') String? translatedText,
    @JsonKey(name: 'translated_audio_url') String? translatedAudioUrl,
    @JsonKey(name: 'sign_ids') List<String>? signIds,
    @JsonKey(name: 'user_rating') int? userRating,
    String? note,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _TranslationEntry;

  factory TranslationEntry.fromJson(Map<String, dynamic> json) => _$TranslationEntryFromJson(json);
}
