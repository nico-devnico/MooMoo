import 'package:freezed_annotation/freezed_annotation.dart';
import 'landmark_point.dart';

part 'sign.freezed.dart';
part 'sign.g.dart';

@freezed
abstract class Sign with _$Sign {
  const factory Sign({
    required String id,
    @JsonKey(name: 'sign_language_id') int? signLanguageId,
    @JsonKey(name: 'category_id') int? categoryId,
    required String word,
    String? description,
    @JsonKey(name: 'difficulty_level') @Default(1) int difficultyLevel,
    @JsonKey(name: 'video_url') String? videoUrl,
    @JsonKey(name: 'thumbnail_url') String? thumbnailUrl,
    @JsonKey(name: 'model_3d_url') String? model3dUrl,
    @JsonKey(name: 'landmark_data') Map<String, dynamic>? landmarkData,
    List<String>? tags,
    @JsonKey(name: 'example_sentence') String? exampleSentence,
    @JsonKey(name: 'is_validated') @Default(false) bool isValidated,
    @JsonKey(name: 'contributor_id') String? contributorId,
    @JsonKey(name: 'view_count') @Default(0) int viewCount,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _Sign;

  factory Sign.fromJson(Map<String, dynamic> json) => _$SignFromJson(json);
}
