import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    String? email,
    @JsonKey(name: 'display_name') String? displayName,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    String? bio,
    @JsonKey(name: 'preferred_sign_language') @Default('LSF') String preferredSignLanguage,
    @JsonKey(name: 'preferred_output') @Default('text') String preferredOutput,
    @JsonKey(name: 'preferred_view') @Default('3d') String preferredView,
    @JsonKey(name: 'is_deaf') @Default(false) bool isDeaf,
    @JsonKey(name: 'three_d_auto_rotate', includeToJson: false) @Default(false) bool threeDAutoRotate,
    @JsonKey(name: 'three_d_zoom_enabled', includeToJson: false) @Default(true) bool threeDZoomEnabled,
    @JsonKey(name: 'selected_character_id', includeToJson: false) @Default('alex') String selectedCharacterId,
    @Default('system') String theme,
    @Default('fr') String locale,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
}
