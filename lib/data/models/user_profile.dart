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
    @JsonKey(name: 'is_admin') @Default(false) bool isAdmin,
    // Colonnes et rôles d'administration : lus mais jamais renvoyés par
    // `toJson()`, que `ProfileRepository.updateProfile` utilise pour l'édition
    // de son propre profil. Le trigger protect_profile_privileges rejette de
    // toute façon ces colonnes pour un non-admin.
    @JsonKey(name: 'status', includeToJson: false) @Default('active') String status,
    @JsonKey(name: 'suspended_at', includeToJson: false) DateTime? suspendedAt,
    @JsonKey(name: 'suspended_reason', includeToJson: false) String? suspendedReason,
    // Vient de public.user_roles, pas d'une colonne de profiles.
    @JsonKey(includeToJson: false) @Default(<String>[]) List<String> roles,
    @JsonKey(name: 'three_d_auto_rotate', includeToJson: false) @Default(false) bool threeDAutoRotate,
    @JsonKey(name: 'three_d_zoom_enabled', includeToJson: false) @Default(true) bool threeDZoomEnabled,
    @JsonKey(name: 'selected_character_id', includeToJson: false) @Default('alex') String selectedCharacterId,
    @Default('light') String theme,
    @Default('fr') String locale,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
}
