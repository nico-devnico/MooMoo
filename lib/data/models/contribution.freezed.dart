// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'contribution.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Contribution {

 String get id;@JsonKey(name: 'contributor_id') String? get contributorId;@JsonKey(name: 'sign_language_id') int? get signLanguageId; String get word; String? get description;@JsonKey(name: 'video_url') String get videoUrl;@JsonKey(name: 'thumbnail_url') String? get thumbnailUrl;@JsonKey(name: 'landmark_data') Map<String, dynamic>? get landmarkData; String get status;@JsonKey(name: 'reviewer_id') String? get reviewerId;@JsonKey(name: 'reviewer_note') String? get reviewerNote;@JsonKey(name: 'submitted_at') DateTime? get submittedAt;@JsonKey(name: 'reviewed_at') DateTime? get reviewedAt;
/// Create a copy of Contribution
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContributionCopyWith<Contribution> get copyWith => _$ContributionCopyWithImpl<Contribution>(this as Contribution, _$identity);

  /// Serializes this Contribution to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Contribution&&(identical(other.id, id) || other.id == id)&&(identical(other.contributorId, contributorId) || other.contributorId == contributorId)&&(identical(other.signLanguageId, signLanguageId) || other.signLanguageId == signLanguageId)&&(identical(other.word, word) || other.word == word)&&(identical(other.description, description) || other.description == description)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&const DeepCollectionEquality().equals(other.landmarkData, landmarkData)&&(identical(other.status, status) || other.status == status)&&(identical(other.reviewerId, reviewerId) || other.reviewerId == reviewerId)&&(identical(other.reviewerNote, reviewerNote) || other.reviewerNote == reviewerNote)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,contributorId,signLanguageId,word,description,videoUrl,thumbnailUrl,const DeepCollectionEquality().hash(landmarkData),status,reviewerId,reviewerNote,submittedAt,reviewedAt);

@override
String toString() {
  return 'Contribution(id: $id, contributorId: $contributorId, signLanguageId: $signLanguageId, word: $word, description: $description, videoUrl: $videoUrl, thumbnailUrl: $thumbnailUrl, landmarkData: $landmarkData, status: $status, reviewerId: $reviewerId, reviewerNote: $reviewerNote, submittedAt: $submittedAt, reviewedAt: $reviewedAt)';
}


}

/// @nodoc
abstract mixin class $ContributionCopyWith<$Res>  {
  factory $ContributionCopyWith(Contribution value, $Res Function(Contribution) _then) = _$ContributionCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'contributor_id') String? contributorId,@JsonKey(name: 'sign_language_id') int? signLanguageId, String word, String? description,@JsonKey(name: 'video_url') String videoUrl,@JsonKey(name: 'thumbnail_url') String? thumbnailUrl,@JsonKey(name: 'landmark_data') Map<String, dynamic>? landmarkData, String status,@JsonKey(name: 'reviewer_id') String? reviewerId,@JsonKey(name: 'reviewer_note') String? reviewerNote,@JsonKey(name: 'submitted_at') DateTime? submittedAt,@JsonKey(name: 'reviewed_at') DateTime? reviewedAt
});




}
/// @nodoc
class _$ContributionCopyWithImpl<$Res>
    implements $ContributionCopyWith<$Res> {
  _$ContributionCopyWithImpl(this._self, this._then);

  final Contribution _self;
  final $Res Function(Contribution) _then;

/// Create a copy of Contribution
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? contributorId = freezed,Object? signLanguageId = freezed,Object? word = null,Object? description = freezed,Object? videoUrl = null,Object? thumbnailUrl = freezed,Object? landmarkData = freezed,Object? status = null,Object? reviewerId = freezed,Object? reviewerNote = freezed,Object? submittedAt = freezed,Object? reviewedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,contributorId: freezed == contributorId ? _self.contributorId : contributorId // ignore: cast_nullable_to_non_nullable
as String?,signLanguageId: freezed == signLanguageId ? _self.signLanguageId : signLanguageId // ignore: cast_nullable_to_non_nullable
as int?,word: null == word ? _self.word : word // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,videoUrl: null == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String,thumbnailUrl: freezed == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,landmarkData: freezed == landmarkData ? _self.landmarkData : landmarkData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,reviewerId: freezed == reviewerId ? _self.reviewerId : reviewerId // ignore: cast_nullable_to_non_nullable
as String?,reviewerNote: freezed == reviewerNote ? _self.reviewerNote : reviewerNote // ignore: cast_nullable_to_non_nullable
as String?,submittedAt: freezed == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Contribution].
extension ContributionPatterns on Contribution {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Contribution value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Contribution() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Contribution value)  $default,){
final _that = this;
switch (_that) {
case _Contribution():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Contribution value)?  $default,){
final _that = this;
switch (_that) {
case _Contribution() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'contributor_id')  String? contributorId, @JsonKey(name: 'sign_language_id')  int? signLanguageId,  String word,  String? description, @JsonKey(name: 'video_url')  String videoUrl, @JsonKey(name: 'thumbnail_url')  String? thumbnailUrl, @JsonKey(name: 'landmark_data')  Map<String, dynamic>? landmarkData,  String status, @JsonKey(name: 'reviewer_id')  String? reviewerId, @JsonKey(name: 'reviewer_note')  String? reviewerNote, @JsonKey(name: 'submitted_at')  DateTime? submittedAt, @JsonKey(name: 'reviewed_at')  DateTime? reviewedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Contribution() when $default != null:
return $default(_that.id,_that.contributorId,_that.signLanguageId,_that.word,_that.description,_that.videoUrl,_that.thumbnailUrl,_that.landmarkData,_that.status,_that.reviewerId,_that.reviewerNote,_that.submittedAt,_that.reviewedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'contributor_id')  String? contributorId, @JsonKey(name: 'sign_language_id')  int? signLanguageId,  String word,  String? description, @JsonKey(name: 'video_url')  String videoUrl, @JsonKey(name: 'thumbnail_url')  String? thumbnailUrl, @JsonKey(name: 'landmark_data')  Map<String, dynamic>? landmarkData,  String status, @JsonKey(name: 'reviewer_id')  String? reviewerId, @JsonKey(name: 'reviewer_note')  String? reviewerNote, @JsonKey(name: 'submitted_at')  DateTime? submittedAt, @JsonKey(name: 'reviewed_at')  DateTime? reviewedAt)  $default,) {final _that = this;
switch (_that) {
case _Contribution():
return $default(_that.id,_that.contributorId,_that.signLanguageId,_that.word,_that.description,_that.videoUrl,_that.thumbnailUrl,_that.landmarkData,_that.status,_that.reviewerId,_that.reviewerNote,_that.submittedAt,_that.reviewedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'contributor_id')  String? contributorId, @JsonKey(name: 'sign_language_id')  int? signLanguageId,  String word,  String? description, @JsonKey(name: 'video_url')  String videoUrl, @JsonKey(name: 'thumbnail_url')  String? thumbnailUrl, @JsonKey(name: 'landmark_data')  Map<String, dynamic>? landmarkData,  String status, @JsonKey(name: 'reviewer_id')  String? reviewerId, @JsonKey(name: 'reviewer_note')  String? reviewerNote, @JsonKey(name: 'submitted_at')  DateTime? submittedAt, @JsonKey(name: 'reviewed_at')  DateTime? reviewedAt)?  $default,) {final _that = this;
switch (_that) {
case _Contribution() when $default != null:
return $default(_that.id,_that.contributorId,_that.signLanguageId,_that.word,_that.description,_that.videoUrl,_that.thumbnailUrl,_that.landmarkData,_that.status,_that.reviewerId,_that.reviewerNote,_that.submittedAt,_that.reviewedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Contribution implements Contribution {
  const _Contribution({required this.id, @JsonKey(name: 'contributor_id') this.contributorId, @JsonKey(name: 'sign_language_id') this.signLanguageId, required this.word, this.description, @JsonKey(name: 'video_url') required this.videoUrl, @JsonKey(name: 'thumbnail_url') this.thumbnailUrl, @JsonKey(name: 'landmark_data') final  Map<String, dynamic>? landmarkData, this.status = 'pending', @JsonKey(name: 'reviewer_id') this.reviewerId, @JsonKey(name: 'reviewer_note') this.reviewerNote, @JsonKey(name: 'submitted_at') this.submittedAt, @JsonKey(name: 'reviewed_at') this.reviewedAt}): _landmarkData = landmarkData;
  factory _Contribution.fromJson(Map<String, dynamic> json) => _$ContributionFromJson(json);

@override final  String id;
@override@JsonKey(name: 'contributor_id') final  String? contributorId;
@override@JsonKey(name: 'sign_language_id') final  int? signLanguageId;
@override final  String word;
@override final  String? description;
@override@JsonKey(name: 'video_url') final  String videoUrl;
@override@JsonKey(name: 'thumbnail_url') final  String? thumbnailUrl;
 final  Map<String, dynamic>? _landmarkData;
@override@JsonKey(name: 'landmark_data') Map<String, dynamic>? get landmarkData {
  final value = _landmarkData;
  if (value == null) return null;
  if (_landmarkData is EqualUnmodifiableMapView) return _landmarkData;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey() final  String status;
@override@JsonKey(name: 'reviewer_id') final  String? reviewerId;
@override@JsonKey(name: 'reviewer_note') final  String? reviewerNote;
@override@JsonKey(name: 'submitted_at') final  DateTime? submittedAt;
@override@JsonKey(name: 'reviewed_at') final  DateTime? reviewedAt;

/// Create a copy of Contribution
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContributionCopyWith<_Contribution> get copyWith => __$ContributionCopyWithImpl<_Contribution>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ContributionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Contribution&&(identical(other.id, id) || other.id == id)&&(identical(other.contributorId, contributorId) || other.contributorId == contributorId)&&(identical(other.signLanguageId, signLanguageId) || other.signLanguageId == signLanguageId)&&(identical(other.word, word) || other.word == word)&&(identical(other.description, description) || other.description == description)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&const DeepCollectionEquality().equals(other._landmarkData, _landmarkData)&&(identical(other.status, status) || other.status == status)&&(identical(other.reviewerId, reviewerId) || other.reviewerId == reviewerId)&&(identical(other.reviewerNote, reviewerNote) || other.reviewerNote == reviewerNote)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,contributorId,signLanguageId,word,description,videoUrl,thumbnailUrl,const DeepCollectionEquality().hash(_landmarkData),status,reviewerId,reviewerNote,submittedAt,reviewedAt);

@override
String toString() {
  return 'Contribution(id: $id, contributorId: $contributorId, signLanguageId: $signLanguageId, word: $word, description: $description, videoUrl: $videoUrl, thumbnailUrl: $thumbnailUrl, landmarkData: $landmarkData, status: $status, reviewerId: $reviewerId, reviewerNote: $reviewerNote, submittedAt: $submittedAt, reviewedAt: $reviewedAt)';
}


}

/// @nodoc
abstract mixin class _$ContributionCopyWith<$Res> implements $ContributionCopyWith<$Res> {
  factory _$ContributionCopyWith(_Contribution value, $Res Function(_Contribution) _then) = __$ContributionCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'contributor_id') String? contributorId,@JsonKey(name: 'sign_language_id') int? signLanguageId, String word, String? description,@JsonKey(name: 'video_url') String videoUrl,@JsonKey(name: 'thumbnail_url') String? thumbnailUrl,@JsonKey(name: 'landmark_data') Map<String, dynamic>? landmarkData, String status,@JsonKey(name: 'reviewer_id') String? reviewerId,@JsonKey(name: 'reviewer_note') String? reviewerNote,@JsonKey(name: 'submitted_at') DateTime? submittedAt,@JsonKey(name: 'reviewed_at') DateTime? reviewedAt
});




}
/// @nodoc
class __$ContributionCopyWithImpl<$Res>
    implements _$ContributionCopyWith<$Res> {
  __$ContributionCopyWithImpl(this._self, this._then);

  final _Contribution _self;
  final $Res Function(_Contribution) _then;

/// Create a copy of Contribution
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? contributorId = freezed,Object? signLanguageId = freezed,Object? word = null,Object? description = freezed,Object? videoUrl = null,Object? thumbnailUrl = freezed,Object? landmarkData = freezed,Object? status = null,Object? reviewerId = freezed,Object? reviewerNote = freezed,Object? submittedAt = freezed,Object? reviewedAt = freezed,}) {
  return _then(_Contribution(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,contributorId: freezed == contributorId ? _self.contributorId : contributorId // ignore: cast_nullable_to_non_nullable
as String?,signLanguageId: freezed == signLanguageId ? _self.signLanguageId : signLanguageId // ignore: cast_nullable_to_non_nullable
as int?,word: null == word ? _self.word : word // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,videoUrl: null == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String,thumbnailUrl: freezed == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,landmarkData: freezed == landmarkData ? _self._landmarkData : landmarkData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,reviewerId: freezed == reviewerId ? _self.reviewerId : reviewerId // ignore: cast_nullable_to_non_nullable
as String?,reviewerNote: freezed == reviewerNote ? _self.reviewerNote : reviewerNote // ignore: cast_nullable_to_non_nullable
as String?,submittedAt: freezed == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
