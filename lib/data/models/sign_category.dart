import 'package:freezed_annotation/freezed_annotation.dart';

part 'sign_category.freezed.dart';
part 'sign_category.g.dart';

@freezed
abstract class SignCategory with _$SignCategory {
  const factory SignCategory({
    required int id,
    required String name,
    required String slug,
    @JsonKey(name: 'icon_name') String? iconName,
    @JsonKey(name: 'color_hex') String? colorHex,
    @JsonKey(name: 'order_index') @Default(0) int orderIndex,
    @JsonKey(name: 'sign_language_id') int? signLanguageId,
  }) = _SignCategory;

  factory SignCategory.fromJson(Map<String, dynamic> json) => _$SignCategoryFromJson(json);
}
