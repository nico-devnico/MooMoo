// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sign_language.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SignLanguage {

 int get id; String get code; String get name; String? get country;@JsonKey(name: 'flag_emoji') String? get flagEmoji;@JsonKey(name: 'is_active') bool get isActive;
/// Create a copy of SignLanguage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignLanguageCopyWith<SignLanguage> get copyWith => _$SignLanguageCopyWithImpl<SignLanguage>(this as SignLanguage, _$identity);

  /// Serializes this SignLanguage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignLanguage&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.country, country) || other.country == country)&&(identical(other.flagEmoji, flagEmoji) || other.flagEmoji == flagEmoji)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name,country,flagEmoji,isActive);

@override
String toString() {
  return 'SignLanguage(id: $id, code: $code, name: $name, country: $country, flagEmoji: $flagEmoji, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class $SignLanguageCopyWith<$Res>  {
  factory $SignLanguageCopyWith(SignLanguage value, $Res Function(SignLanguage) _then) = _$SignLanguageCopyWithImpl;
@useResult
$Res call({
 int id, String code, String name, String? country,@JsonKey(name: 'flag_emoji') String? flagEmoji,@JsonKey(name: 'is_active') bool isActive
});




}
/// @nodoc
class _$SignLanguageCopyWithImpl<$Res>
    implements $SignLanguageCopyWith<$Res> {
  _$SignLanguageCopyWithImpl(this._self, this._then);

  final SignLanguage _self;
  final $Res Function(SignLanguage) _then;

/// Create a copy of SignLanguage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? name = null,Object? country = freezed,Object? flagEmoji = freezed,Object? isActive = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,country: freezed == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String?,flagEmoji: freezed == flagEmoji ? _self.flagEmoji : flagEmoji // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SignLanguage].
extension SignLanguagePatterns on SignLanguage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SignLanguage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SignLanguage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SignLanguage value)  $default,){
final _that = this;
switch (_that) {
case _SignLanguage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SignLanguage value)?  $default,){
final _that = this;
switch (_that) {
case _SignLanguage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String code,  String name,  String? country, @JsonKey(name: 'flag_emoji')  String? flagEmoji, @JsonKey(name: 'is_active')  bool isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SignLanguage() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.country,_that.flagEmoji,_that.isActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String code,  String name,  String? country, @JsonKey(name: 'flag_emoji')  String? flagEmoji, @JsonKey(name: 'is_active')  bool isActive)  $default,) {final _that = this;
switch (_that) {
case _SignLanguage():
return $default(_that.id,_that.code,_that.name,_that.country,_that.flagEmoji,_that.isActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String code,  String name,  String? country, @JsonKey(name: 'flag_emoji')  String? flagEmoji, @JsonKey(name: 'is_active')  bool isActive)?  $default,) {final _that = this;
switch (_that) {
case _SignLanguage() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.country,_that.flagEmoji,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SignLanguage implements SignLanguage {
  const _SignLanguage({required this.id, required this.code, required this.name, this.country, @JsonKey(name: 'flag_emoji') this.flagEmoji, @JsonKey(name: 'is_active') this.isActive = true});
  factory _SignLanguage.fromJson(Map<String, dynamic> json) => _$SignLanguageFromJson(json);

@override final  int id;
@override final  String code;
@override final  String name;
@override final  String? country;
@override@JsonKey(name: 'flag_emoji') final  String? flagEmoji;
@override@JsonKey(name: 'is_active') final  bool isActive;

/// Create a copy of SignLanguage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SignLanguageCopyWith<_SignLanguage> get copyWith => __$SignLanguageCopyWithImpl<_SignLanguage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SignLanguageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SignLanguage&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.country, country) || other.country == country)&&(identical(other.flagEmoji, flagEmoji) || other.flagEmoji == flagEmoji)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name,country,flagEmoji,isActive);

@override
String toString() {
  return 'SignLanguage(id: $id, code: $code, name: $name, country: $country, flagEmoji: $flagEmoji, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$SignLanguageCopyWith<$Res> implements $SignLanguageCopyWith<$Res> {
  factory _$SignLanguageCopyWith(_SignLanguage value, $Res Function(_SignLanguage) _then) = __$SignLanguageCopyWithImpl;
@override @useResult
$Res call({
 int id, String code, String name, String? country,@JsonKey(name: 'flag_emoji') String? flagEmoji,@JsonKey(name: 'is_active') bool isActive
});




}
/// @nodoc
class __$SignLanguageCopyWithImpl<$Res>
    implements _$SignLanguageCopyWith<$Res> {
  __$SignLanguageCopyWithImpl(this._self, this._then);

  final _SignLanguage _self;
  final $Res Function(_SignLanguage) _then;

/// Create a copy of SignLanguage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? name = null,Object? country = freezed,Object? flagEmoji = freezed,Object? isActive = null,}) {
  return _then(_SignLanguage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,country: freezed == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String?,flagEmoji: freezed == flagEmoji ? _self.flagEmoji : flagEmoji // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
