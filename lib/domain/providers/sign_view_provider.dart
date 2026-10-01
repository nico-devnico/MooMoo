import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_provider.dart';

part 'sign_view_provider.g.dart';

enum SignViewModeEnum { model3d, landmarks, video }

/// `profiles.preferred_view` values ('3d' is kept for existing accounts).
String signViewToProfile(SignViewModeEnum mode) => switch (mode) {
      SignViewModeEnum.model3d => '3d',
      SignViewModeEnum.landmarks => 'landmarks',
      SignViewModeEnum.video => 'video',
    };

SignViewModeEnum? signViewFromProfile(String? value) => switch (value) {
      '3d' || 'model3d' => SignViewModeEnum.model3d,
      'landmarks' => SignViewModeEnum.landmarks,
      'video' => SignViewModeEnum.video,
      _ => null,
    };

/// The account's preference (profiles.preferred_view) wins; the device keeps
/// a copy for offline use and signed-out visitors.
@riverpod
class SignViewMode extends _$SignViewMode {
  final _storage = const FlutterSecureStorage();
  static const _key = 'sign_view_mode';

  @override
  Future<SignViewModeEnum> build() async {
    final userId = ref.watch(currentUserProvider.select((u) => u?.id));
    if (userId != null) {
      try {
        final row = await ref
            .read(supabaseClientProvider)
            .from('profiles')
            .select('preferred_view')
            .eq('id', userId)
            .maybeSingle();
        final remote = signViewFromProfile(row?['preferred_view'] as String?);
        if (remote != null) {
          await _storage.write(key: _key, value: remote.name);
          return remote;
        }
      } catch (e) {
        debugPrint('[sign_view] profile unavailable, using local value: $e');
      }
    }
    final data = await _storage.read(key: _key);
    return SignViewModeEnum.values.firstWhere(
      (e) => e.name == data,
      orElse: () => SignViewModeEnum.model3d,
    );
  }

  Future<void> setMode(SignViewModeEnum mode) async {
    state = AsyncData(mode);
    await _storage.write(key: _key, value: mode.name);
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    try {
      await ref
          .read(supabaseClientProvider)
          .from('profiles')
          .update({'preferred_view': signViewToProfile(mode)})
          .eq('id', userId);
    } catch (e) {
      debugPrint('[sign_view] preference not saved to profile: $e');
    }
  }
}
