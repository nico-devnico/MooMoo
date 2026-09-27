// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserProfile {

 String get id; String? get email;@JsonKey(name: 'display_name') String? get displayName;@JsonKey(name: 'avatar_url') String? get avatarUrl; String? get bio;@JsonKey(name: 'preferred_sign_language') String get preferredSignLanguage;@JsonKey(name: 'preferred_output') String get preferredOutput;@JsonKey(name: 'preferred_view') String get preferredView;@JsonKey(name: 'is_deaf') bool get isDeaf;@JsonKey(name: 'is_admin') bool get isAdmin;// Colonnes et rôles d'administration : lus mais jamais renvoyés par
// `toJson()`, que `ProfileRepository.updateProfile` utilise pour l'édition
// de son propre profil. Le trigger protect_profile_privileges rejette de
// toute façon ces colonnes pour un non-admin.
@JsonKey(name: 'status', includeToJson: false) String get status;@JsonKey(name: 'suspended_at', includeToJson: false) DateTime? get suspendedAt;@JsonKey(name: 'suspended_reason', includeToJson: false) String? get suspendedReason;// Vient de public.user_roles, pas d'une colonne de profiles.
@JsonKey(includeToJson: false) List<String> get roles;@JsonKey(name: 'three_d_auto_rotate', includeToJson: false) bool get threeDAutoRotate;@JsonKey(name: 'three_d_zoom_enabled', includeToJson: false) bool get threeDZoomEnabled;@JsonKey(name: 'selected_character_id', includeToJson: false) String get selectedCharacterId; String get theme; String get locale;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserProfileCopyWith<UserProfile> get copyWith => _$UserProfileCopyWithImpl<UserProfile>(this as UserProfile, _$identity);

  /// Serializes this UserProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.preferredSignLanguage, preferredSignLanguage) || other.preferredSignLanguage == preferredSignLanguage)&&(identical(other.preferredOutput, preferredOutput) || other.preferredOutput == preferredOutput)&&(identical(other.preferredView, preferredView) || other.preferredView == preferredView)&&(identical(other.isDeaf, isDeaf) || other.isDeaf == isDeaf)&&(identical(other.isAdmin, isAdmin) || other.isAdmin == isAdmin)&&(identical(other.status, status) || other.status == status)&&(identical(other.suspendedAt, suspendedAt) || other.suspendedAt == suspendedAt)&&(identical(other.suspendedReason, suspendedReason) || other.suspendedReason == suspendedReason)&&const DeepCollectionEquality().equals(other.roles, roles)&&(identical(other.threeDAutoRotate, threeDAutoRotate) || other.threeDAutoRotate == threeDAutoRotate)&&(identical(other.threeDZoomEnabled, threeDZoomEnabled) || other.threeDZoomEnabled == threeDZoomEnabled)&&(identical(other.selectedCharacterId, selectedCharacterId) || other.selectedCharacterId == selectedCharacterId)&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,email,displayName,avatarUrl,bio,preferredSignLanguage,preferredOutput,preferredView,isDeaf,isAdmin,status,suspendedAt,suspendedReason,const DeepCollectionEquality().hash(roles),threeDAutoRotate,threeDZoomEnabled,selectedCharacterId,theme,locale,createdAt,updatedAt]);

@override
String toString() {
  return 'UserProfile(id: $id, email: $email, displayName: $displayName, avatarUrl: $avatarUrl, bio: $bio, preferredSignLanguage: $preferredSignLanguage, preferredOutput: $preferredOutput, preferredView: $preferredView, isDeaf: $isDeaf, isAdmin: $isAdmin, status: $status, suspendedAt: $suspendedAt, suspendedReason: $suspendedReason, roles: $roles, threeDAutoRotate: $threeDAutoRotate, threeDZoomEnabled: $threeDZoomEnabled, selectedCharacterId: $selectedCharacterId, theme: $theme, locale: $locale, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $UserProfileCopyWith<$Res>  {
  factory $UserProfileCopyWith(UserProfile value, $Res Function(UserProfile) _then) = _$UserProfileCopyWithImpl;
@useResult
$Res call({
 String id, String? email,@JsonKey(name: 'display_name') String? displayName,@JsonKey(name: 'avatar_url') String? avatarUrl, String? bio,@JsonKey(name: 'preferred_sign_language') String preferredSignLanguage,@JsonKey(name: 'preferred_output') String preferredOutput,@JsonKey(name: 'preferred_view') String preferredView,@JsonKey(name: 'is_deaf') bool isDeaf,@JsonKey(name: 'is_admin') bool isAdmin,@JsonKey(name: 'status', includeToJson: false) String status,@JsonKey(name: 'suspended_at', includeToJson: false) DateTime? suspendedAt,@JsonKey(name: 'suspended_reason', includeToJson: false) String? suspendedReason,@JsonKey(includeToJson: false) List<String> roles,@JsonKey(name: 'three_d_auto_rotate', includeToJson: false) bool threeDAutoRotate,@JsonKey(name: 'three_d_zoom_enabled', includeToJson: false) bool threeDZoomEnabled,@JsonKey(name: 'selected_character_id', includeToJson: false) String selectedCharacterId, String theme, String locale,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class _$UserProfileCopyWithImpl<$Res>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._self, this._then);

  final UserProfile _self;
  final $Res Function(UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? email = freezed,Object? displayName = freezed,Object? avatarUrl = freezed,Object? bio = freezed,Object? preferredSignLanguage = null,Object? preferredOutput = null,Object? preferredView = null,Object? isDeaf = null,Object? isAdmin = null,Object? status = null,Object? suspendedAt = freezed,Object? suspendedReason = freezed,Object? roles = null,Object? threeDAutoRotate = null,Object? threeDZoomEnabled = null,Object? selectedCharacterId = null,Object? theme = null,Object? locale = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,preferredSignLanguage: null == preferredSignLanguage ? _self.preferredSignLanguage : preferredSignLanguage // ignore: cast_nullable_to_non_nullable
as String,preferredOutput: null == preferredOutput ? _self.preferredOutput : preferredOutput // ignore: cast_nullable_to_non_nullable
as String,preferredView: null == preferredView ? _self.preferredView : preferredView // ignore: cast_nullable_to_non_nullable
as String,isDeaf: null == isDeaf ? _self.isDeaf : isDeaf // ignore: cast_nullable_to_non_nullable
as bool,isAdmin: null == isAdmin ? _self.isAdmin : isAdmin // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,suspendedAt: freezed == suspendedAt ? _self.suspendedAt : suspendedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,suspendedReason: freezed == suspendedReason ? _self.suspendedReason : suspendedReason // ignore: cast_nullable_to_non_nullable
as String?,roles: null == roles ? _self.roles : roles // ignore: cast_nullable_to_non_nullable
as List<String>,threeDAutoRotate: null == threeDAutoRotate ? _self.threeDAutoRotate : threeDAutoRotate // ignore: cast_nullable_to_non_nullable
as bool,threeDZoomEnabled: null == threeDZoomEnabled ? _self.threeDZoomEnabled : threeDZoomEnabled // ignore: cast_nullable_to_non_nullable
as bool,selectedCharacterId: null == selectedCharacterId ? _self.selectedCharacterId : selectedCharacterId // ignore: cast_nullable_to_non_nullable
as String,theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as String,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserProfile].
extension UserProfilePatterns on UserProfile {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserProfile value)  $default,){
final _that = this;
switch (_that) {
case _UserProfile():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserProfile value)?  $default,){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? email, @JsonKey(name: 'display_name')  String? displayName, @JsonKey(name: 'avatar_url')  String? avatarUrl,  String? bio, @JsonKey(name: 'preferred_sign_language')  String preferredSignLanguage, @JsonKey(name: 'preferred_output')  String preferredOutput, @JsonKey(name: 'preferred_view')  String preferredView, @JsonKey(name: 'is_deaf')  bool isDeaf, @JsonKey(name: 'is_admin')  bool isAdmin, @JsonKey(name: 'status', includeToJson: false)  String status, @JsonKey(name: 'suspended_at', includeToJson: false)  DateTime? suspendedAt, @JsonKey(name: 'suspended_reason', includeToJson: false)  String? suspendedReason, @JsonKey(includeToJson: false)  List<String> roles, @JsonKey(name: 'three_d_auto_rotate', includeToJson: false)  bool threeDAutoRotate, @JsonKey(name: 'three_d_zoom_enabled', includeToJson: false)  bool threeDZoomEnabled, @JsonKey(name: 'selected_character_id', includeToJson: false)  String selectedCharacterId,  String theme,  String locale, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.id,_that.email,_that.displayName,_that.avatarUrl,_that.bio,_that.preferredSignLanguage,_that.preferredOutput,_that.preferredView,_that.isDeaf,_that.isAdmin,_that.status,_that.suspendedAt,_that.suspendedReason,_that.roles,_that.threeDAutoRotate,_that.threeDZoomEnabled,_that.selectedCharacterId,_that.theme,_that.locale,_that.createdAt,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? email, @JsonKey(name: 'display_name')  String? displayName, @JsonKey(name: 'avatar_url')  String? avatarUrl,  String? bio, @JsonKey(name: 'preferred_sign_language')  String preferredSignLanguage, @JsonKey(name: 'preferred_output')  String preferredOutput, @JsonKey(name: 'preferred_view')  String preferredView, @JsonKey(name: 'is_deaf')  bool isDeaf, @JsonKey(name: 'is_admin')  bool isAdmin, @JsonKey(name: 'status', includeToJson: false)  String status, @JsonKey(name: 'suspended_at', includeToJson: false)  DateTime? suspendedAt, @JsonKey(name: 'suspended_reason', includeToJson: false)  String? suspendedReason, @JsonKey(includeToJson: false)  List<String> roles, @JsonKey(name: 'three_d_auto_rotate', includeToJson: false)  bool threeDAutoRotate, @JsonKey(name: 'three_d_zoom_enabled', includeToJson: false)  bool threeDZoomEnabled, @JsonKey(name: 'selected_character_id', includeToJson: false)  String selectedCharacterId,  String theme,  String locale, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _UserProfile():
return $default(_that.id,_that.email,_that.displayName,_that.avatarUrl,_that.bio,_that.preferredSignLanguage,_that.preferredOutput,_that.preferredView,_that.isDeaf,_that.isAdmin,_that.status,_that.suspendedAt,_that.suspendedReason,_that.roles,_that.threeDAutoRotate,_that.threeDZoomEnabled,_that.selectedCharacterId,_that.theme,_that.locale,_that.createdAt,_that.updatedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? email, @JsonKey(name: 'display_name')  String? displayName, @JsonKey(name: 'avatar_url')  String? avatarUrl,  String? bio, @JsonKey(name: 'preferred_sign_language')  String preferredSignLanguage, @JsonKey(name: 'preferred_output')  String preferredOutput, @JsonKey(name: 'preferred_view')  String preferredView, @JsonKey(name: 'is_deaf')  bool isDeaf, @JsonKey(name: 'is_admin')  bool isAdmin, @JsonKey(name: 'status', includeToJson: false)  String status, @JsonKey(name: 'suspended_at', includeToJson: false)  DateTime? suspendedAt, @JsonKey(name: 'suspended_reason', includeToJson: false)  String? suspendedReason, @JsonKey(includeToJson: false)  List<String> roles, @JsonKey(name: 'three_d_auto_rotate', includeToJson: false)  bool threeDAutoRotate, @JsonKey(name: 'three_d_zoom_enabled', includeToJson: false)  bool threeDZoomEnabled, @JsonKey(name: 'selected_character_id', includeToJson: false)  String selectedCharacterId,  String theme,  String locale, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.id,_that.email,_that.displayName,_that.avatarUrl,_that.bio,_that.preferredSignLanguage,_that.preferredOutput,_that.preferredView,_that.isDeaf,_that.isAdmin,_that.status,_that.suspendedAt,_that.suspendedReason,_that.roles,_that.threeDAutoRotate,_that.threeDZoomEnabled,_that.selectedCharacterId,_that.theme,_that.locale,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserProfile implements UserProfile {
  const _UserProfile({required this.id, this.email, @JsonKey(name: 'display_name') this.displayName, @JsonKey(name: 'avatar_url') this.avatarUrl, this.bio, @JsonKey(name: 'preferred_sign_language') this.preferredSignLanguage = 'LSF', @JsonKey(name: 'preferred_output') this.preferredOutput = 'text', @JsonKey(name: 'preferred_view') this.preferredView = '3d', @JsonKey(name: 'is_deaf') this.isDeaf = false, @JsonKey(name: 'is_admin') this.isAdmin = false, @JsonKey(name: 'status', includeToJson: false) this.status = 'active', @JsonKey(name: 'suspended_at', includeToJson: false) this.suspendedAt, @JsonKey(name: 'suspended_reason', includeToJson: false) this.suspendedReason, @JsonKey(includeToJson: false) final  List<String> roles = const <String>[], @JsonKey(name: 'three_d_auto_rotate', includeToJson: false) this.threeDAutoRotate = false, @JsonKey(name: 'three_d_zoom_enabled', includeToJson: false) this.threeDZoomEnabled = true, @JsonKey(name: 'selected_character_id', includeToJson: false) this.selectedCharacterId = 'alex', this.theme = 'light', this.locale = 'fr', @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt}): _roles = roles;
  factory _UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);

@override final  String id;
@override final  String? email;
@override@JsonKey(name: 'display_name') final  String? displayName;
@override@JsonKey(name: 'avatar_url') final  String? avatarUrl;
@override final  String? bio;
@override@JsonKey(name: 'preferred_sign_language') final  String preferredSignLanguage;
@override@JsonKey(name: 'preferred_output') final  String preferredOutput;
@override@JsonKey(name: 'preferred_view') final  String preferredView;
@override@JsonKey(name: 'is_deaf') final  bool isDeaf;
@override@JsonKey(name: 'is_admin') final  bool isAdmin;
// Colonnes et rôles d'administration : lus mais jamais renvoyés par
// `toJson()`, que `ProfileRepository.updateProfile` utilise pour l'édition
// de son propre profil. Le trigger protect_profile_privileges rejette de
// toute façon ces colonnes pour un non-admin.
@override@JsonKey(name: 'status', includeToJson: false) final  String status;
@override@JsonKey(name: 'suspended_at', includeToJson: false) final  DateTime? suspendedAt;
@override@JsonKey(name: 'suspended_reason', includeToJson: false) final  String? suspendedReason;
// Vient de public.user_roles, pas d'une colonne de profiles.
 final  List<String> _roles;
// Vient de public.user_roles, pas d'une colonne de profiles.
@override@JsonKey(includeToJson: false) List<String> get roles {
  if (_roles is EqualUnmodifiableListView) return _roles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_roles);
}

@override@JsonKey(name: 'three_d_auto_rotate', includeToJson: false) final  bool threeDAutoRotate;
@override@JsonKey(name: 'three_d_zoom_enabled', includeToJson: false) final  bool threeDZoomEnabled;
@override@JsonKey(name: 'selected_character_id', includeToJson: false) final  String selectedCharacterId;
@override@JsonKey() final  String theme;
@override@JsonKey() final  String locale;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserProfileCopyWith<_UserProfile> get copyWith => __$UserProfileCopyWithImpl<_UserProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.preferredSignLanguage, preferredSignLanguage) || other.preferredSignLanguage == preferredSignLanguage)&&(identical(other.preferredOutput, preferredOutput) || other.preferredOutput == preferredOutput)&&(identical(other.preferredView, preferredView) || other.preferredView == preferredView)&&(identical(other.isDeaf, isDeaf) || other.isDeaf == isDeaf)&&(identical(other.isAdmin, isAdmin) || other.isAdmin == isAdmin)&&(identical(other.status, status) || other.status == status)&&(identical(other.suspendedAt, suspendedAt) || other.suspendedAt == suspendedAt)&&(identical(other.suspendedReason, suspendedReason) || other.suspendedReason == suspendedReason)&&const DeepCollectionEquality().equals(other._roles, _roles)&&(identical(other.threeDAutoRotate, threeDAutoRotate) || other.threeDAutoRotate == threeDAutoRotate)&&(identical(other.threeDZoomEnabled, threeDZoomEnabled) || other.threeDZoomEnabled == threeDZoomEnabled)&&(identical(other.selectedCharacterId, selectedCharacterId) || other.selectedCharacterId == selectedCharacterId)&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,email,displayName,avatarUrl,bio,preferredSignLanguage,preferredOutput,preferredView,isDeaf,isAdmin,status,suspendedAt,suspendedReason,const DeepCollectionEquality().hash(_roles),threeDAutoRotate,threeDZoomEnabled,selectedCharacterId,theme,locale,createdAt,updatedAt]);

@override
String toString() {
  return 'UserProfile(id: $id, email: $email, displayName: $displayName, avatarUrl: $avatarUrl, bio: $bio, preferredSignLanguage: $preferredSignLanguage, preferredOutput: $preferredOutput, preferredView: $preferredView, isDeaf: $isDeaf, isAdmin: $isAdmin, status: $status, suspendedAt: $suspendedAt, suspendedReason: $suspendedReason, roles: $roles, threeDAutoRotate: $threeDAutoRotate, threeDZoomEnabled: $threeDZoomEnabled, selectedCharacterId: $selectedCharacterId, theme: $theme, locale: $locale, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$UserProfileCopyWith<$Res> implements $UserProfileCopyWith<$Res> {
  factory _$UserProfileCopyWith(_UserProfile value, $Res Function(_UserProfile) _then) = __$UserProfileCopyWithImpl;
@override @useResult
$Res call({
 String id, String? email,@JsonKey(name: 'display_name') String? displayName,@JsonKey(name: 'avatar_url') String? avatarUrl, String? bio,@JsonKey(name: 'preferred_sign_language') String preferredSignLanguage,@JsonKey(name: 'preferred_output') String preferredOutput,@JsonKey(name: 'preferred_view') String preferredView,@JsonKey(name: 'is_deaf') bool isDeaf,@JsonKey(name: 'is_admin') bool isAdmin,@JsonKey(name: 'status', includeToJson: false) String status,@JsonKey(name: 'suspended_at', includeToJson: false) DateTime? suspendedAt,@JsonKey(name: 'suspended_reason', includeToJson: false) String? suspendedReason,@JsonKey(includeToJson: false) List<String> roles,@JsonKey(name: 'three_d_auto_rotate', includeToJson: false) bool threeDAutoRotate,@JsonKey(name: 'three_d_zoom_enabled', includeToJson: false) bool threeDZoomEnabled,@JsonKey(name: 'selected_character_id', includeToJson: false) String selectedCharacterId, String theme, String locale,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class __$UserProfileCopyWithImpl<$Res>
    implements _$UserProfileCopyWith<$Res> {
  __$UserProfileCopyWithImpl(this._self, this._then);

  final _UserProfile _self;
  final $Res Function(_UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? email = freezed,Object? displayName = freezed,Object? avatarUrl = freezed,Object? bio = freezed,Object? preferredSignLanguage = null,Object? preferredOutput = null,Object? preferredView = null,Object? isDeaf = null,Object? isAdmin = null,Object? status = null,Object? suspendedAt = freezed,Object? suspendedReason = freezed,Object? roles = null,Object? threeDAutoRotate = null,Object? threeDZoomEnabled = null,Object? selectedCharacterId = null,Object? theme = null,Object? locale = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_UserProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,preferredSignLanguage: null == preferredSignLanguage ? _self.preferredSignLanguage : preferredSignLanguage // ignore: cast_nullable_to_non_nullable
as String,preferredOutput: null == preferredOutput ? _self.preferredOutput : preferredOutput // ignore: cast_nullable_to_non_nullable
as String,preferredView: null == preferredView ? _self.preferredView : preferredView // ignore: cast_nullable_to_non_nullable
as String,isDeaf: null == isDeaf ? _self.isDeaf : isDeaf // ignore: cast_nullable_to_non_nullable
as bool,isAdmin: null == isAdmin ? _self.isAdmin : isAdmin // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,suspendedAt: freezed == suspendedAt ? _self.suspendedAt : suspendedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,suspendedReason: freezed == suspendedReason ? _self.suspendedReason : suspendedReason // ignore: cast_nullable_to_non_nullable
as String?,roles: null == roles ? _self._roles : roles // ignore: cast_nullable_to_non_nullable
as List<String>,threeDAutoRotate: null == threeDAutoRotate ? _self.threeDAutoRotate : threeDAutoRotate // ignore: cast_nullable_to_non_nullable
as bool,threeDZoomEnabled: null == threeDZoomEnabled ? _self.threeDZoomEnabled : threeDZoomEnabled // ignore: cast_nullable_to_non_nullable
as bool,selectedCharacterId: null == selectedCharacterId ? _self.selectedCharacterId : selectedCharacterId // ignore: cast_nullable_to_non_nullable
as String,theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as String,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
