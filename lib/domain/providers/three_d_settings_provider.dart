import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:moomoo/core/constants/character_constants.dart';

import 'auth_provider.dart';

part 'three_d_settings_provider.g.dart';

const _profileColumns = {
  'cameraControlsEnabled': 'three_d_camera_controls',
  'zoomEnabled': 'three_d_zoom_enabled',
  'selectedCharacterId': 'selected_character_id',
};

/// 3D viewer settings, stored on the account (profiles) with a device copy
/// for offline use and signed-out visitors.
@riverpod
class ThreeDSettings extends _$ThreeDSettings {
  final _storage = const FlutterSecureStorage();
  static const _key = 'three_d_settings_v2';

  @override
  Future<Map<String, dynamic>> build() async {
    final defaults = <String, dynamic>{
      'cameraControlsEnabled': true,
      'zoomEnabled': true,
      'selectedCharacterId': CharacterConstants.defaultCharacterId,
    };
    final data = await _storage.read(key: _key);
    final local = {
      ...defaults,
      if (data != null) ...Map<String, dynamic>.from(json.decode(data)),
    };

    final userId = ref.watch(currentUserProvider.select((u) => u?.id));
    if (userId == null) return local;
    try {
      final row = await ref
          .read(supabaseClientProvider)
          .from('profiles')
          .select(_profileColumns.values.join(','))
          .eq('id', userId)
          .maybeSingle();
      if (row == null) return local;
      final remote = {
        for (final e in _profileColumns.entries)
          if (row[e.value] != null) e.key: row[e.value],
      };
      final merged = {...local, ...remote};
      await _storage.write(key: _key, value: json.encode(merged));
      return merged;
    } catch (e) {
      debugPrint('[3d_settings] profile unavailable, using local values: $e');
      return local;
    }
  }

  Future<void> _set(String key, Object value) async {
    final current = await future;
    final updated = {...current, key: value};
    state = AsyncData(updated);
    await _storage.write(key: _key, value: json.encode(updated));
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    try {
      await ref
          .read(supabaseClientProvider)
          .from('profiles')
          .update({_profileColumns[key]!: value})
          .eq('id', userId);
    } catch (e) {
      debugPrint('[3d_settings] $key not saved to profile: $e');
    }
  }

  Future<void> setCameraControlsEnabled(bool value) =>
      _set('cameraControlsEnabled', value);

  Future<void> setZoomEnabled(bool value) => _set('zoomEnabled', value);

  Future<void> setSelectedCharacterId(String id) =>
      _set('selectedCharacterId', id);
}
