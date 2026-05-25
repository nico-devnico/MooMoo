// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'camera_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CameraState)
final cameraStateProvider = CameraStateProvider._();

final class CameraStateProvider
    extends $AsyncNotifierProvider<CameraState, CameraController?> {
  CameraStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cameraStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cameraStateHash();

  @$internal
  @override
  CameraState create() => CameraState();
}

String _$cameraStateHash() => r'0348a1a4b67b5d825725e27fbb18dae38f8bfa5e';

abstract class _$CameraState extends $AsyncNotifier<CameraController?> {
  FutureOr<CameraController?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<CameraController?>, CameraController?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CameraController?>, CameraController?>,
              AsyncValue<CameraController?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(CameraSettings)
final cameraSettingsProvider = CameraSettingsProvider._();

final class CameraSettingsProvider
    extends $NotifierProvider<CameraSettings, Map<String, dynamic>> {
  CameraSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cameraSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cameraSettingsHash();

  @$internal
  @override
  CameraSettings create() => CameraSettings();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, dynamic> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, dynamic>>(value),
    );
  }
}

String _$cameraSettingsHash() => r'd155e57a1bd66f638fa2e05efc7971a0a850ac17';

abstract class _$CameraSettings extends $Notifier<Map<String, dynamic>> {
  Map<String, dynamic> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Map<String, dynamic>, Map<String, dynamic>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, dynamic>, Map<String, dynamic>>,
              Map<String, dynamic>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
