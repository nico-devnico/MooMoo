import 'package:freezed_annotation/freezed_annotation.dart';

part 'contribution.freezed.dart';
part 'contribution.g.dart';

@freezed
abstract class Contribution with _$Contribution {
  const factory Contribution({
    required String id,
    @JsonKey(name: 'contributor_id') String? contributorId,
    @JsonKey(name: 'sign_language_id') int? signLanguageId,
    required String word,
    String? description,
    @JsonKey(name: 'video_url') required String videoUrl,
    @JsonKey(name: 'thumbnail_url') String? thumbnailUrl,
    @JsonKey(name: 'landmark_data') Map<String, dynamic>? landmarkData,
    @Default('pending') String status,
    @JsonKey(name: 'reviewer_id') String? reviewerId,
    @JsonKey(name: 'reviewer_note') String? reviewerNote,
    @JsonKey(name: 'submitted_at') DateTime? submittedAt,
    @JsonKey(name: 'reviewed_at') DateTime? reviewedAt,
  }) = _Contribution;

  factory Contribution.fromJson(Map<String, dynamic> json) => _$ContributionFromJson(json);
}
