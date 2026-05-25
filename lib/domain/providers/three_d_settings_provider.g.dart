// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'three_d_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ThreeDSettings)
final threeDSettingsProvider = ThreeDSettingsProvider._();

final class ThreeDSettingsProvider
    extends $AsyncNotifierProvider<ThreeDSettings, Map<String, dynamic>> {
  ThreeDSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'threeDSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$threeDSettingsHash();

  @$internal
  @override
  ThreeDSettings create() => ThreeDSettings();
}

String _$threeDSettingsHash() => r'c2cbc27afa7e09a553677febe564e24065b750c8';

abstract class _$ThreeDSettings extends $AsyncNotifier<Map<String, dynamic>> {
  FutureOr<Map<String, dynamic>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<Map<String, dynamic>>, Map<String, dynamic>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Map<String, dynamic>>,
                Map<String, dynamic>
              >,
              AsyncValue<Map<String, dynamic>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
