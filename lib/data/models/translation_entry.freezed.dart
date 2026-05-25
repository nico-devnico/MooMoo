// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'translation_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TranslationEntry {

 String get id;@JsonKey(name: 'session_id') String get sessionId;@JsonKey(name: 'user_id') String? get userId; String get direction;@JsonKey(name: 'source_text') String? get sourceText;@JsonKey(name: 'source_video_url') String? get sourceVideoUrl;@JsonKey(name: 'source_audio_url') String? get sourceAudioUrl;@JsonKey(name: 'translated_text') String? get translatedText;@JsonKey(name: 'translated_audio_url') String? get translatedAudioUrl;@JsonKey(name: 'sign_ids') List<String>? get signIds;@JsonKey(name: 'user_rating') int? get userRating; String? get note;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of TranslationEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TranslationEntryCopyWith<TranslationEntry> get copyWith => _$TranslationEntryCopyWithImpl<TranslationEntry>(this as TranslationEntry, _$identity);

  /// Serializes this TranslationEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TranslationEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.sourceText, sourceText) || other.sourceText == sourceText)&&(identical(other.sourceVideoUrl, sourceVideoUrl) || other.sourceVideoUrl == sourceVideoUrl)&&(identical(other.sourceAudioUrl, sourceAudioUrl) || other.sourceAudioUrl == sourceAudioUrl)&&(identical(other.translatedText, translatedText) || other.translatedText == translatedText)&&(identical(other.translatedAudioUrl, translatedAudioUrl) || other.translatedAudioUrl == translatedAudioUrl)&&const DeepCollectionEquality().equals(other.signIds, signIds)&&(identical(other.userRating, userRating) || other.userRating == userRating)&&(identical(other.note, note) || other.note == note)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionId,userId,direction,sourceText,sourceVideoUrl,sourceAudioUrl,translatedText,translatedAudioUrl,const DeepCollectionEquality().hash(signIds),userRating,note,createdAt);

@override
String toString() {
  return 'TranslationEntry(id: $id, sessionId: $sessionId, userId: $userId, direction: $direction, sourceText: $sourceText, sourceVideoUrl: $sourceVideoUrl, sourceAudioUrl: $sourceAudioUrl, translatedText: $translatedText, translatedAudioUrl: $translatedAudioUrl, signIds: $signIds, userRating: $userRating, note: $note, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $TranslationEntryCopyWith<$Res>  {
  factory $TranslationEntryCopyWith(TranslationEntry value, $Res Function(TranslationEntry) _then) = _$TranslationEntryCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'session_id') String sessionId,@JsonKey(name: 'user_id') String? userId, String direction,@JsonKey(name: 'source_text') String? sourceText,@JsonKey(name: 'source_video_url') String? sourceVideoUrl,@JsonKey(name: 'source_audio_url') String? sourceAudioUrl,@JsonKey(name: 'translated_text') String? translatedText,@JsonKey(name: 'translated_audio_url') String? translatedAudioUrl,@JsonKey(name: 'sign_ids') List<String>? signIds,@JsonKey(name: 'user_rating') int? userRating, String? note,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class _$TranslationEntryCopyWithImpl<$Res>
    implements $TranslationEntryCopyWith<$Res> {
  _$TranslationEntryCopyWithImpl(this._self, this._then);

  final TranslationEntry _self;
  final $Res Function(TranslationEntry) _then;

/// Create a copy of TranslationEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sessionId = null,Object? userId = freezed,Object? direction = null,Object? sourceText = freezed,Object? sourceVideoUrl = freezed,Object? sourceAudioUrl = freezed,Object? translatedText = freezed,Object? translatedAudioUrl = freezed,Object? signIds = freezed,Object? userRating = freezed,Object? note = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String,sourceText: freezed == sourceText ? _self.sourceText : sourceText // ignore: cast_nullable_to_non_nullable
as String?,sourceVideoUrl: freezed == sourceVideoUrl ? _self.sourceVideoUrl : sourceVideoUrl // ignore: cast_nullable_to_non_nullable
as String?,sourceAudioUrl: freezed == sourceAudioUrl ? _self.sourceAudioUrl : sourceAudioUrl // ignore: cast_nullable_to_non_nullable
as String?,translatedText: freezed == translatedText ? _self.translatedText : translatedText // ignore: cast_nullable_to_non_nullable
as String?,translatedAudioUrl: freezed == translatedAudioUrl ? _self.translatedAudioUrl : translatedAudioUrl // ignore: cast_nullable_to_non_nullable
as String?,signIds: freezed == signIds ? _self.signIds : signIds // ignore: cast_nullable_to_non_nullable
as List<String>?,userRating: freezed == userRating ? _self.userRating : userRating // ignore: cast_nullable_to_non_nullable
as int?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [TranslationEntry].
extension TranslationEntryPatterns on TranslationEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TranslationEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TranslationEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TranslationEntry value)  $default,){
final _that = this;
switch (_that) {
case _TranslationEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TranslationEntry value)?  $default,){
final _that = this;
switch (_that) {
case _TranslationEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'session_id')  String sessionId, @JsonKey(name: 'user_id')  String? userId,  String direction, @JsonKey(name: 'source_text')  String? sourceText, @JsonKey(name: 'source_video_url')  String? sourceVideoUrl, @JsonKey(name: 'source_audio_url')  String? sourceAudioUrl, @JsonKey(name: 'translated_text')  String? translatedText, @JsonKey(name: 'translated_audio_url')  String? translatedAudioUrl, @JsonKey(name: 'sign_ids')  List<String>? signIds, @JsonKey(name: 'user_rating')  int? userRating,  String? note, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TranslationEntry() when $default != null:
return $default(_that.id,_that.sessionId,_that.userId,_that.direction,_that.sourceText,_that.sourceVideoUrl,_that.sourceAudioUrl,_that.translatedText,_that.translatedAudioUrl,_that.signIds,_that.userRating,_that.note,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'session_id')  String sessionId, @JsonKey(name: 'user_id')  String? userId,  String direction, @JsonKey(name: 'source_text')  String? sourceText, @JsonKey(name: 'source_video_url')  String? sourceVideoUrl, @JsonKey(name: 'source_audio_url')  String? sourceAudioUrl, @JsonKey(name: 'translated_text')  String? translatedText, @JsonKey(name: 'translated_audio_url')  String? translatedAudioUrl, @JsonKey(name: 'sign_ids')  List<String>? signIds, @JsonKey(name: 'user_rating')  int? userRating,  String? note, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _TranslationEntry():
return $default(_that.id,_that.sessionId,_that.userId,_that.direction,_that.sourceText,_that.sourceVideoUrl,_that.sourceAudioUrl,_that.translatedText,_that.translatedAudioUrl,_that.signIds,_that.userRating,_that.note,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'session_id')  String sessionId, @JsonKey(name: 'user_id')  String? userId,  String direction, @JsonKey(name: 'source_text')  String? sourceText, @JsonKey(name: 'source_video_url')  String? sourceVideoUrl, @JsonKey(name: 'source_audio_url')  String? sourceAudioUrl, @JsonKey(name: 'translated_text')  String? translatedText, @JsonKey(name: 'translated_audio_url')  String? translatedAudioUrl, @JsonKey(name: 'sign_ids')  List<String>? signIds, @JsonKey(name: 'user_rating')  int? userRating,  String? note, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _TranslationEntry() when $default != null:
return $default(_that.id,_that.sessionId,_that.userId,_that.direction,_that.sourceText,_that.sourceVideoUrl,_that.sourceAudioUrl,_that.translatedText,_that.translatedAudioUrl,_that.signIds,_that.userRating,_that.note,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TranslationEntry implements TranslationEntry {
  const _TranslationEntry({required this.id, @JsonKey(name: 'session_id') required this.sessionId, @JsonKey(name: 'user_id') this.userId, required this.direction, @JsonKey(name: 'source_text') this.sourceText, @JsonKey(name: 'source_video_url') this.sourceVideoUrl, @JsonKey(name: 'source_audio_url') this.sourceAudioUrl, @JsonKey(name: 'translated_text') this.translatedText, @JsonKey(name: 'translated_audio_url') this.translatedAudioUrl, @JsonKey(name: 'sign_ids') final  List<String>? signIds, @JsonKey(name: 'user_rating') this.userRating, this.note, @JsonKey(name: 'created_at') this.createdAt}): _signIds = signIds;
  factory _TranslationEntry.fromJson(Map<String, dynamic> json) => _$TranslationEntryFromJson(json);

@override final  String id;
@override@JsonKey(name: 'session_id') final  String sessionId;
@override@JsonKey(name: 'user_id') final  String? userId;
@override final  String direction;
@override@JsonKey(name: 'source_text') final  String? sourceText;
@override@JsonKey(name: 'source_video_url') final  String? sourceVideoUrl;
@override@JsonKey(name: 'source_audio_url') final  String? sourceAudioUrl;
@override@JsonKey(name: 'translated_text') final  String? translatedText;
@override@JsonKey(name: 'translated_audio_url') final  String? translatedAudioUrl;
 final  List<String>? _signIds;
@override@JsonKey(name: 'sign_ids') List<String>? get signIds {
  final value = _signIds;
  if (value == null) return null;
  if (_signIds is EqualUnmodifiableListView) return _signIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(name: 'user_rating') final  int? userRating;
@override final  String? note;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of TranslationEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TranslationEntryCopyWith<_TranslationEntry> get copyWith => __$TranslationEntryCopyWithImpl<_TranslationEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TranslationEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TranslationEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.sourceText, sourceText) || other.sourceText == sourceText)&&(identical(other.sourceVideoUrl, sourceVideoUrl) || other.sourceVideoUrl == sourceVideoUrl)&&(identical(other.sourceAudioUrl, sourceAudioUrl) || other.sourceAudioUrl == sourceAudioUrl)&&(identical(other.translatedText, translatedText) || other.translatedText == translatedText)&&(identical(other.translatedAudioUrl, translatedAudioUrl) || other.translatedAudioUrl == translatedAudioUrl)&&const DeepCollectionEquality().equals(other._signIds, _signIds)&&(identical(other.userRating, userRating) || other.userRating == userRating)&&(identical(other.note, note) || other.note == note)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionId,userId,direction,sourceText,sourceVideoUrl,sourceAudioUrl,translatedText,translatedAudioUrl,const DeepCollectionEquality().hash(_signIds),userRating,note,createdAt);

@override
String toString() {
  return 'TranslationEntry(id: $id, sessionId: $sessionId, userId: $userId, direction: $direction, sourceText: $sourceText, sourceVideoUrl: $sourceVideoUrl, sourceAudioUrl: $sourceAudioUrl, translatedText: $translatedText, translatedAudioUrl: $translatedAudioUrl, signIds: $signIds, userRating: $userRating, note: $note, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$TranslationEntryCopyWith<$Res> implements $TranslationEntryCopyWith<$Res> {
  factory _$TranslationEntryCopyWith(_TranslationEntry value, $Res Function(_TranslationEntry) _then) = __$TranslationEntryCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'session_id') String sessionId,@JsonKey(name: 'user_id') String? userId, String direction,@JsonKey(name: 'source_text') String? sourceText,@JsonKey(name: 'source_video_url') String? sourceVideoUrl,@JsonKey(name: 'source_audio_url') String? sourceAudioUrl,@JsonKey(name: 'translated_text') String? translatedText,@JsonKey(name: 'translated_audio_url') String? translatedAudioUrl,@JsonKey(name: 'sign_ids') List<String>? signIds,@JsonKey(name: 'user_rating') int? userRating, String? note,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class __$TranslationEntryCopyWithImpl<$Res>
    implements _$TranslationEntryCopyWith<$Res> {
  __$TranslationEntryCopyWithImpl(this._self, this._then);

  final _TranslationEntry _self;
  final $Res Function(_TranslationEntry) _then;

/// Create a copy of TranslationEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sessionId = null,Object? userId = freezed,Object? direction = null,Object? sourceText = freezed,Object? sourceVideoUrl = freezed,Object? sourceAudioUrl = freezed,Object? translatedText = freezed,Object? translatedAudioUrl = freezed,Object? signIds = freezed,Object? userRating = freezed,Object? note = freezed,Object? createdAt = freezed,}) {
  return _then(_TranslationEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String,sourceText: freezed == sourceText ? _self.sourceText : sourceText // ignore: cast_nullable_to_non_nullable
as String?,sourceVideoUrl: freezed == sourceVideoUrl ? _self.sourceVideoUrl : sourceVideoUrl // ignore: cast_nullable_to_non_nullable
as String?,sourceAudioUrl: freezed == sourceAudioUrl ? _self.sourceAudioUrl : sourceAudioUrl // ignore: cast_nullable_to_non_nullable
as String?,translatedText: freezed == translatedText ? _self.translatedText : translatedText // ignore: cast_nullable_to_non_nullable
as String?,translatedAudioUrl: freezed == translatedAudioUrl ? _self.translatedAudioUrl : translatedAudioUrl // ignore: cast_nullable_to_non_nullable
as String?,signIds: freezed == signIds ? _self._signIds : signIds // ignore: cast_nullable_to_non_nullable
as List<String>?,userRating: freezed == userRating ? _self.userRating : userRating // ignore: cast_nullable_to_non_nullable
as int?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
