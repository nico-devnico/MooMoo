// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sign.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Sign {

 String get id;@JsonKey(name: 'sign_language_id') int? get signLanguageId;@JsonKey(name: 'category_id') int? get categoryId; String get word; String? get description;@JsonKey(name: 'difficulty_level') int get difficultyLevel;@JsonKey(name: 'video_url') String? get videoUrl;@JsonKey(name: 'thumbnail_url') String? get thumbnailUrl;@JsonKey(name: 'model_3d_url') String? get model3dUrl;@JsonKey(name: 'landmark_data') Map<String, dynamic>? get landmarkData; List<String>? get tags;@JsonKey(name: 'example_sentence') String? get exampleSentence;@JsonKey(name: 'is_validated') bool get isValidated;@JsonKey(name: 'contributor_id') String? get contributorId;@JsonKey(name: 'view_count') int get viewCount;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of Sign
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignCopyWith<Sign> get copyWith => _$SignCopyWithImpl<Sign>(this as Sign, _$identity);

  /// Serializes this Sign to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Sign&&(identical(other.id, id) || other.id == id)&&(identical(other.signLanguageId, signLanguageId) || other.signLanguageId == signLanguageId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.word, word) || other.word == word)&&(identical(other.description, description) || other.description == description)&&(identical(other.difficultyLevel, difficultyLevel) || other.difficultyLevel == difficultyLevel)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.model3dUrl, model3dUrl) || other.model3dUrl == model3dUrl)&&const DeepCollectionEquality().equals(other.landmarkData, landmarkData)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.exampleSentence, exampleSentence) || other.exampleSentence == exampleSentence)&&(identical(other.isValidated, isValidated) || other.isValidated == isValidated)&&(identical(other.contributorId, contributorId) || other.contributorId == contributorId)&&(identical(other.viewCount, viewCount) || other.viewCount == viewCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,signLanguageId,categoryId,word,description,difficultyLevel,videoUrl,thumbnailUrl,model3dUrl,const DeepCollectionEquality().hash(landmarkData),const DeepCollectionEquality().hash(tags),exampleSentence,isValidated,contributorId,viewCount,createdAt,updatedAt);

@override
String toString() {
  return 'Sign(id: $id, signLanguageId: $signLanguageId, categoryId: $categoryId, word: $word, description: $description, difficultyLevel: $difficultyLevel, videoUrl: $videoUrl, thumbnailUrl: $thumbnailUrl, model3dUrl: $model3dUrl, landmarkData: $landmarkData, tags: $tags, exampleSentence: $exampleSentence, isValidated: $isValidated, contributorId: $contributorId, viewCount: $viewCount, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $SignCopyWith<$Res>  {
  factory $SignCopyWith(Sign value, $Res Function(Sign) _then) = _$SignCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'sign_language_id') int? signLanguageId,@JsonKey(name: 'category_id') int? categoryId, String word, String? description,@JsonKey(name: 'difficulty_level') int difficultyLevel,@JsonKey(name: 'video_url') String? videoUrl,@JsonKey(name: 'thumbnail_url') String? thumbnailUrl,@JsonKey(name: 'model_3d_url') String? model3dUrl,@JsonKey(name: 'landmark_data') Map<String, dynamic>? landmarkData, List<String>? tags,@JsonKey(name: 'example_sentence') String? exampleSentence,@JsonKey(name: 'is_validated') bool isValidated,@JsonKey(name: 'contributor_id') String? contributorId,@JsonKey(name: 'view_count') int viewCount,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class _$SignCopyWithImpl<$Res>
    implements $SignCopyWith<$Res> {
  _$SignCopyWithImpl(this._self, this._then);

  final Sign _self;
  final $Res Function(Sign) _then;

/// Create a copy of Sign
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? signLanguageId = freezed,Object? categoryId = freezed,Object? word = null,Object? description = freezed,Object? difficultyLevel = null,Object? videoUrl = freezed,Object? thumbnailUrl = freezed,Object? model3dUrl = freezed,Object? landmarkData = freezed,Object? tags = freezed,Object? exampleSentence = freezed,Object? isValidated = null,Object? contributorId = freezed,Object? viewCount = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,signLanguageId: freezed == signLanguageId ? _self.signLanguageId : signLanguageId // ignore: cast_nullable_to_non_nullable
as int?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int?,word: null == word ? _self.word : word // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,difficultyLevel: null == difficultyLevel ? _self.difficultyLevel : difficultyLevel // ignore: cast_nullable_to_non_nullable
as int,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,thumbnailUrl: freezed == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,model3dUrl: freezed == model3dUrl ? _self.model3dUrl : model3dUrl // ignore: cast_nullable_to_non_nullable
as String?,landmarkData: freezed == landmarkData ? _self.landmarkData : landmarkData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,tags: freezed == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>?,exampleSentence: freezed == exampleSentence ? _self.exampleSentence : exampleSentence // ignore: cast_nullable_to_non_nullable
as String?,isValidated: null == isValidated ? _self.isValidated : isValidated // ignore: cast_nullable_to_non_nullable
as bool,contributorId: freezed == contributorId ? _self.contributorId : contributorId // ignore: cast_nullable_to_non_nullable
as String?,viewCount: null == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Sign].
extension SignPatterns on Sign {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Sign value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Sign() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Sign value)  $default,){
final _that = this;
switch (_that) {
case _Sign():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Sign value)?  $default,){
final _that = this;
switch (_that) {
case _Sign() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'sign_language_id')  int? signLanguageId, @JsonKey(name: 'category_id')  int? categoryId,  String word,  String? description, @JsonKey(name: 'difficulty_level')  int difficultyLevel, @JsonKey(name: 'video_url')  String? videoUrl, @JsonKey(name: 'thumbnail_url')  String? thumbnailUrl, @JsonKey(name: 'model_3d_url')  String? model3dUrl, @JsonKey(name: 'landmark_data')  Map<String, dynamic>? landmarkData,  List<String>? tags, @JsonKey(name: 'example_sentence')  String? exampleSentence, @JsonKey(name: 'is_validated')  bool isValidated, @JsonKey(name: 'contributor_id')  String? contributorId, @JsonKey(name: 'view_count')  int viewCount, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Sign() when $default != null:
return $default(_that.id,_that.signLanguageId,_that.categoryId,_that.word,_that.description,_that.difficultyLevel,_that.videoUrl,_that.thumbnailUrl,_that.model3dUrl,_that.landmarkData,_that.tags,_that.exampleSentence,_that.isValidated,_that.contributorId,_that.viewCount,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'sign_language_id')  int? signLanguageId, @JsonKey(name: 'category_id')  int? categoryId,  String word,  String? description, @JsonKey(name: 'difficulty_level')  int difficultyLevel, @JsonKey(name: 'video_url')  String? videoUrl, @JsonKey(name: 'thumbnail_url')  String? thumbnailUrl, @JsonKey(name: 'model_3d_url')  String? model3dUrl, @JsonKey(name: 'landmark_data')  Map<String, dynamic>? landmarkData,  List<String>? tags, @JsonKey(name: 'example_sentence')  String? exampleSentence, @JsonKey(name: 'is_validated')  bool isValidated, @JsonKey(name: 'contributor_id')  String? contributorId, @JsonKey(name: 'view_count')  int viewCount, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Sign():
return $default(_that.id,_that.signLanguageId,_that.categoryId,_that.word,_that.description,_that.difficultyLevel,_that.videoUrl,_that.thumbnailUrl,_that.model3dUrl,_that.landmarkData,_that.tags,_that.exampleSentence,_that.isValidated,_that.contributorId,_that.viewCount,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'sign_language_id')  int? signLanguageId, @JsonKey(name: 'category_id')  int? categoryId,  String word,  String? description, @JsonKey(name: 'difficulty_level')  int difficultyLevel, @JsonKey(name: 'video_url')  String? videoUrl, @JsonKey(name: 'thumbnail_url')  String? thumbnailUrl, @JsonKey(name: 'model_3d_url')  String? model3dUrl, @JsonKey(name: 'landmark_data')  Map<String, dynamic>? landmarkData,  List<String>? tags, @JsonKey(name: 'example_sentence')  String? exampleSentence, @JsonKey(name: 'is_validated')  bool isValidated, @JsonKey(name: 'contributor_id')  String? contributorId, @JsonKey(name: 'view_count')  int viewCount, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Sign() when $default != null:
return $default(_that.id,_that.signLanguageId,_that.categoryId,_that.word,_that.description,_that.difficultyLevel,_that.videoUrl,_that.thumbnailUrl,_that.model3dUrl,_that.landmarkData,_that.tags,_that.exampleSentence,_that.isValidated,_that.contributorId,_that.viewCount,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Sign implements Sign {
  const _Sign({required this.id, @JsonKey(name: 'sign_language_id') this.signLanguageId, @JsonKey(name: 'category_id') this.categoryId, required this.word, this.description, @JsonKey(name: 'difficulty_level') this.difficultyLevel = 1, @JsonKey(name: 'video_url') this.videoUrl, @JsonKey(name: 'thumbnail_url') this.thumbnailUrl, @JsonKey(name: 'model_3d_url') this.model3dUrl, @JsonKey(name: 'landmark_data') final  Map<String, dynamic>? landmarkData, final  List<String>? tags, @JsonKey(name: 'example_sentence') this.exampleSentence, @JsonKey(name: 'is_validated') this.isValidated = false, @JsonKey(name: 'contributor_id') this.contributorId, @JsonKey(name: 'view_count') this.viewCount = 0, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt}): _landmarkData = landmarkData,_tags = tags;
  factory _Sign.fromJson(Map<String, dynamic> json) => _$SignFromJson(json);

@override final  String id;
@override@JsonKey(name: 'sign_language_id') final  int? signLanguageId;
@override@JsonKey(name: 'category_id') final  int? categoryId;
@override final  String word;
@override final  String? description;
@override@JsonKey(name: 'difficulty_level') final  int difficultyLevel;
@override@JsonKey(name: 'video_url') final  String? videoUrl;
@override@JsonKey(name: 'thumbnail_url') final  String? thumbnailUrl;
@override@JsonKey(name: 'model_3d_url') final  String? model3dUrl;
 final  Map<String, dynamic>? _landmarkData;
@override@JsonKey(name: 'landmark_data') Map<String, dynamic>? get landmarkData {
  final value = _landmarkData;
  if (value == null) return null;
  if (_landmarkData is EqualUnmodifiableMapView) return _landmarkData;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  List<String>? _tags;
@override List<String>? get tags {
  final value = _tags;
  if (value == null) return null;
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(name: 'example_sentence') final  String? exampleSentence;
@override@JsonKey(name: 'is_validated') final  bool isValidated;
@override@JsonKey(name: 'contributor_id') final  String? contributorId;
@override@JsonKey(name: 'view_count') final  int viewCount;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;

/// Create a copy of Sign
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SignCopyWith<_Sign> get copyWith => __$SignCopyWithImpl<_Sign>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SignToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Sign&&(identical(other.id, id) || other.id == id)&&(identical(other.signLanguageId, signLanguageId) || other.signLanguageId == signLanguageId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.word, word) || other.word == word)&&(identical(other.description, description) || other.description == description)&&(identical(other.difficultyLevel, difficultyLevel) || other.difficultyLevel == difficultyLevel)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.model3dUrl, model3dUrl) || other.model3dUrl == model3dUrl)&&const DeepCollectionEquality().equals(other._landmarkData, _landmarkData)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.exampleSentence, exampleSentence) || other.exampleSentence == exampleSentence)&&(identical(other.isValidated, isValidated) || other.isValidated == isValidated)&&(identical(other.contributorId, contributorId) || other.contributorId == contributorId)&&(identical(other.viewCount, viewCount) || other.viewCount == viewCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,signLanguageId,categoryId,word,description,difficultyLevel,videoUrl,thumbnailUrl,model3dUrl,const DeepCollectionEquality().hash(_landmarkData),const DeepCollectionEquality().hash(_tags),exampleSentence,isValidated,contributorId,viewCount,createdAt,updatedAt);

@override
String toString() {
  return 'Sign(id: $id, signLanguageId: $signLanguageId, categoryId: $categoryId, word: $word, description: $description, difficultyLevel: $difficultyLevel, videoUrl: $videoUrl, thumbnailUrl: $thumbnailUrl, model3dUrl: $model3dUrl, landmarkData: $landmarkData, tags: $tags, exampleSentence: $exampleSentence, isValidated: $isValidated, contributorId: $contributorId, viewCount: $viewCount, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$SignCopyWith<$Res> implements $SignCopyWith<$Res> {
  factory _$SignCopyWith(_Sign value, $Res Function(_Sign) _then) = __$SignCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'sign_language_id') int? signLanguageId,@JsonKey(name: 'category_id') int? categoryId, String word, String? description,@JsonKey(name: 'difficulty_level') int difficultyLevel,@JsonKey(name: 'video_url') String? videoUrl,@JsonKey(name: 'thumbnail_url') String? thumbnailUrl,@JsonKey(name: 'model_3d_url') String? model3dUrl,@JsonKey(name: 'landmark_data') Map<String, dynamic>? landmarkData, List<String>? tags,@JsonKey(name: 'example_sentence') String? exampleSentence,@JsonKey(name: 'is_validated') bool isValidated,@JsonKey(name: 'contributor_id') String? contributorId,@JsonKey(name: 'view_count') int viewCount,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class __$SignCopyWithImpl<$Res>
    implements _$SignCopyWith<$Res> {
  __$SignCopyWithImpl(this._self, this._then);

  final _Sign _self;
  final $Res Function(_Sign) _then;

/// Create a copy of Sign
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? signLanguageId = freezed,Object? categoryId = freezed,Object? word = null,Object? description = freezed,Object? difficultyLevel = null,Object? videoUrl = freezed,Object? thumbnailUrl = freezed,Object? model3dUrl = freezed,Object? landmarkData = freezed,Object? tags = freezed,Object? exampleSentence = freezed,Object? isValidated = null,Object? contributorId = freezed,Object? viewCount = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Sign(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,signLanguageId: freezed == signLanguageId ? _self.signLanguageId : signLanguageId // ignore: cast_nullable_to_non_nullable
as int?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int?,word: null == word ? _self.word : word // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,difficultyLevel: null == difficultyLevel ? _self.difficultyLevel : difficultyLevel // ignore: cast_nullable_to_non_nullable
as int,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,thumbnailUrl: freezed == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,model3dUrl: freezed == model3dUrl ? _self.model3dUrl : model3dUrl // ignore: cast_nullable_to_non_nullable
as String?,landmarkData: freezed == landmarkData ? _self._landmarkData : landmarkData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,tags: freezed == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>?,exampleSentence: freezed == exampleSentence ? _self.exampleSentence : exampleSentence // ignore: cast_nullable_to_non_nullable
as String?,isValidated: null == isValidated ? _self.isValidated : isValidated // ignore: cast_nullable_to_non_nullable
as bool,contributorId: freezed == contributorId ? _self.contributorId : contributorId // ignore: cast_nullable_to_non_nullable
as String?,viewCount: null == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
