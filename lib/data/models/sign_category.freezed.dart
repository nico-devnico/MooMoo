// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sign_category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SignCategory {

 int get id; String get name; String get slug;@JsonKey(name: 'icon_name') String? get iconName;@JsonKey(name: 'color_hex') String? get colorHex;@JsonKey(name: 'order_index') int get orderIndex;@JsonKey(name: 'sign_language_id') int? get signLanguageId;
/// Create a copy of SignCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignCategoryCopyWith<SignCategory> get copyWith => _$SignCategoryCopyWithImpl<SignCategory>(this as SignCategory, _$identity);

  /// Serializes this SignCategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.iconName, iconName) || other.iconName == iconName)&&(identical(other.colorHex, colorHex) || other.colorHex == colorHex)&&(identical(other.orderIndex, orderIndex) || other.orderIndex == orderIndex)&&(identical(other.signLanguageId, signLanguageId) || other.signLanguageId == signLanguageId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,slug,iconName,colorHex,orderIndex,signLanguageId);

@override
String toString() {
  return 'SignCategory(id: $id, name: $name, slug: $slug, iconName: $iconName, colorHex: $colorHex, orderIndex: $orderIndex, signLanguageId: $signLanguageId)';
}


}

/// @nodoc
abstract mixin class $SignCategoryCopyWith<$Res>  {
  factory $SignCategoryCopyWith(SignCategory value, $Res Function(SignCategory) _then) = _$SignCategoryCopyWithImpl;
@useResult
$Res call({
 int id, String name, String slug,@JsonKey(name: 'icon_name') String? iconName,@JsonKey(name: 'color_hex') String? colorHex,@JsonKey(name: 'order_index') int orderIndex,@JsonKey(name: 'sign_language_id') int? signLanguageId
});




}
/// @nodoc
class _$SignCategoryCopyWithImpl<$Res>
    implements $SignCategoryCopyWith<$Res> {
  _$SignCategoryCopyWithImpl(this._self, this._then);

  final SignCategory _self;
  final $Res Function(SignCategory) _then;

/// Create a copy of SignCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? slug = null,Object? iconName = freezed,Object? colorHex = freezed,Object? orderIndex = null,Object? signLanguageId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,colorHex: freezed == colorHex ? _self.colorHex : colorHex // ignore: cast_nullable_to_non_nullable
as String?,orderIndex: null == orderIndex ? _self.orderIndex : orderIndex // ignore: cast_nullable_to_non_nullable
as int,signLanguageId: freezed == signLanguageId ? _self.signLanguageId : signLanguageId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [SignCategory].
extension SignCategoryPatterns on SignCategory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SignCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SignCategory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SignCategory value)  $default,){
final _that = this;
switch (_that) {
case _SignCategory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SignCategory value)?  $default,){
final _that = this;
switch (_that) {
case _SignCategory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String slug, @JsonKey(name: 'icon_name')  String? iconName, @JsonKey(name: 'color_hex')  String? colorHex, @JsonKey(name: 'order_index')  int orderIndex, @JsonKey(name: 'sign_language_id')  int? signLanguageId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SignCategory() when $default != null:
return $default(_that.id,_that.name,_that.slug,_that.iconName,_that.colorHex,_that.orderIndex,_that.signLanguageId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String slug, @JsonKey(name: 'icon_name')  String? iconName, @JsonKey(name: 'color_hex')  String? colorHex, @JsonKey(name: 'order_index')  int orderIndex, @JsonKey(name: 'sign_language_id')  int? signLanguageId)  $default,) {final _that = this;
switch (_that) {
case _SignCategory():
return $default(_that.id,_that.name,_that.slug,_that.iconName,_that.colorHex,_that.orderIndex,_that.signLanguageId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String slug, @JsonKey(name: 'icon_name')  String? iconName, @JsonKey(name: 'color_hex')  String? colorHex, @JsonKey(name: 'order_index')  int orderIndex, @JsonKey(name: 'sign_language_id')  int? signLanguageId)?  $default,) {final _that = this;
switch (_that) {
case _SignCategory() when $default != null:
return $default(_that.id,_that.name,_that.slug,_that.iconName,_that.colorHex,_that.orderIndex,_that.signLanguageId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SignCategory implements SignCategory {
  const _SignCategory({required this.id, required this.name, required this.slug, @JsonKey(name: 'icon_name') this.iconName, @JsonKey(name: 'color_hex') this.colorHex, @JsonKey(name: 'order_index') this.orderIndex = 0, @JsonKey(name: 'sign_language_id') this.signLanguageId});
  factory _SignCategory.fromJson(Map<String, dynamic> json) => _$SignCategoryFromJson(json);

@override final  int id;
@override final  String name;
@override final  String slug;
@override@JsonKey(name: 'icon_name') final  String? iconName;
@override@JsonKey(name: 'color_hex') final  String? colorHex;
@override@JsonKey(name: 'order_index') final  int orderIndex;
@override@JsonKey(name: 'sign_language_id') final  int? signLanguageId;

/// Create a copy of SignCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SignCategoryCopyWith<_SignCategory> get copyWith => __$SignCategoryCopyWithImpl<_SignCategory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SignCategoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SignCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.iconName, iconName) || other.iconName == iconName)&&(identical(other.colorHex, colorHex) || other.colorHex == colorHex)&&(identical(other.orderIndex, orderIndex) || other.orderIndex == orderIndex)&&(identical(other.signLanguageId, signLanguageId) || other.signLanguageId == signLanguageId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,slug,iconName,colorHex,orderIndex,signLanguageId);

@override
String toString() {
  return 'SignCategory(id: $id, name: $name, slug: $slug, iconName: $iconName, colorHex: $colorHex, orderIndex: $orderIndex, signLanguageId: $signLanguageId)';
}


}

/// @nodoc
abstract mixin class _$SignCategoryCopyWith<$Res> implements $SignCategoryCopyWith<$Res> {
  factory _$SignCategoryCopyWith(_SignCategory value, $Res Function(_SignCategory) _then) = __$SignCategoryCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String slug,@JsonKey(name: 'icon_name') String? iconName,@JsonKey(name: 'color_hex') String? colorHex,@JsonKey(name: 'order_index') int orderIndex,@JsonKey(name: 'sign_language_id') int? signLanguageId
});




}
/// @nodoc
class __$SignCategoryCopyWithImpl<$Res>
    implements _$SignCategoryCopyWith<$Res> {
  __$SignCategoryCopyWithImpl(this._self, this._then);

  final _SignCategory _self;
  final $Res Function(_SignCategory) _then;

/// Create a copy of SignCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? slug = null,Object? iconName = freezed,Object? colorHex = freezed,Object? orderIndex = null,Object? signLanguageId = freezed,}) {
  return _then(_SignCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,colorHex: freezed == colorHex ? _self.colorHex : colorHex // ignore: cast_nullable_to_non_nullable
as String?,orderIndex: null == orderIndex ? _self.orderIndex : orderIndex // ignore: cast_nullable_to_non_nullable
as int,signLanguageId: freezed == signLanguageId ? _self.signLanguageId : signLanguageId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
