import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:moomoo/core/constants/character_constants.dart';

part 'three_d_settings_provider.g.dart';

@riverpod
class ThreeDSettings extends _$ThreeDSettings {
  final _storage = const FlutterSecureStorage();
  static const _key = 'three_d_settings_v2';

  @override
  Future<Map<String, dynamic>> build() async {
    final data = await _storage.read(key: _key);
    if (data == null) {
      return {
        'cameraControlsEnabled': true,
        'zoomEnabled': true,
        'selectedCharacterId': CharacterConstants.defaultCharacterId,
      };
    }
    return Map<String, dynamic>.from(json.decode(data));
  }

  Future<void> setCameraControlsEnabled(bool value) async {
    final current = await future;
    final updated = {...current, 'cameraControlsEnabled': value};
    state = AsyncData(updated);
    await _storage.write(key: _key, value: json.encode(updated));
  }

  Future<void> setZoomEnabled(bool value) async {
    final current = await future;
    final updated = {...current, 'zoomEnabled': value};
    state = AsyncData(updated);
    await _storage.write(key: _key, value: json.encode(updated));
  }

  Future<void> setSelectedCharacterId(String id) async {
    final current = await future;
    final updated = {...current, 'selectedCharacterId': id};
    state = AsyncData(updated);
    await _storage.write(key: _key, value: json.encode(updated));
  }
}
