import 'package:freezed_annotation/freezed_annotation.dart';

part 'sign_language.freezed.dart';
part 'sign_language.g.dart';

@freezed
abstract class SignLanguage with _$SignLanguage {
  const factory SignLanguage({
    required int id,
    required String code,
    required String name,
    String? country,
    @JsonKey(name: 'flag_emoji') String? flagEmoji,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
  }) = _SignLanguage;

  factory SignLanguage.fromJson(Map<String, dynamic> json) => _$SignLanguageFromJson(json);
}
