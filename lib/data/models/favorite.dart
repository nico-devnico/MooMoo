import 'package:freezed_annotation/freezed_annotation.dart';

part 'favorite.freezed.dart';
part 'favorite.g.dart';

@freezed
abstract class Favorite with _$Favorite {
  const factory Favorite({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'sign_id') required String signId,
    String? note,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Favorite;

  factory Favorite.fromJson(Map<String, dynamic> json) => _$FavoriteFromJson(json);
}
