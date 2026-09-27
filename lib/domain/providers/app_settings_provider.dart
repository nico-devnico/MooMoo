import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_settings.dart';
import '../../data/repositories/app_settings_repository.dart';
import 'auth_provider.dart';

final appSettingsRepositoryProvider = Provider<AppSettingsRepository>((ref) {
  return AppSettingsRepository(ref.watch(supabaseClientProvider));
});

/// Global configuration, kept in sync through Supabase Realtime.
final appSettingsProvider = StreamProvider<AppSettings>((ref) async* {
  final repository = ref.watch(appSettingsRepositoryProvider);
  // Re-subscribes on sign-in/out so the channel uses the current JWT.
  ref.watch(currentUserProvider.select((u) => u?.id));
  yield await repository.fetch();
  yield* repository.watch();
});

/// Name shown everywhere; the default while settings load or are unreachable.
final appNameProvider = Provider<String>((ref) {
  return ref.watch(appSettingsProvider).value?.appName ?? AppSettings.defaultName;
});
