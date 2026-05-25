// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contribution.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Contribution _$ContributionFromJson(Map<String, dynamic> json) =>
    _Contribution(
      id: json['id'] as String,
      contributorId: json['contributor_id'] as String?,
      signLanguageId: (json['sign_language_id'] as num?)?.toInt(),
      word: json['word'] as String,
      description: json['description'] as String?,
      videoUrl: json['video_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      landmarkData: json['landmark_data'] as Map<String, dynamic>?,
      status: json['status'] as String? ?? 'pending',
      reviewerId: json['reviewer_id'] as String?,
      reviewerNote: json['reviewer_note'] as String?,
      submittedAt: json['submitted_at'] == null
          ? null
          : DateTime.parse(json['submitted_at'] as String),
      reviewedAt: json['reviewed_at'] == null
          ? null
          : DateTime.parse(json['reviewed_at'] as String),
    );

Map<String, dynamic> _$ContributionToJson(_Contribution instance) =>
    <String, dynamic>{
      'id': instance.id,
      'contributor_id': instance.contributorId,
      'sign_language_id': instance.signLanguageId,
      'word': instance.word,
      'description': instance.description,
      'video_url': instance.videoUrl,
      'thumbnail_url': instance.thumbnailUrl,
      'landmark_data': instance.landmarkData,
      'status': instance.status,
      'reviewer_id': instance.reviewerId,
      'reviewer_note': instance.reviewerNote,
      'submitted_at': instance.submittedAt?.toIso8601String(),
      'reviewed_at': instance.reviewedAt?.toIso8601String(),
    };
