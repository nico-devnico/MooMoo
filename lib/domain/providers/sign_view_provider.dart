import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

part 'sign_view_provider.g.dart';

enum SignViewModeEnum { model3d, landmarks, video }

@riverpod
class SignViewMode extends _$SignViewMode {
  final _storage = const FlutterSecureStorage();
  static const _key = 'sign_view_mode';

  @override
  Future<SignViewModeEnum> build() async {
    final data = await _storage.read(key: _key);
    if (data == null) return SignViewModeEnum.model3d;
    return SignViewModeEnum.values.firstWhere(
      (e) => e.name == data,
      orElse: () => SignViewModeEnum.model3d,
    );
  }

  Future<void> setMode(SignViewModeEnum mode) async {
    state = AsyncData(mode);
    await _storage.write(key: _key, value: mode.name);
  }
}
