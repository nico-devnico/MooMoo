// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stt_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SpeechController)
final speechControllerProvider = SpeechControllerProvider._();

final class SpeechControllerProvider
    extends $NotifierProvider<SpeechController, bool> {
  SpeechControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'speechControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$speechControllerHash();

  @$internal
  @override
  SpeechController create() => SpeechController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$speechControllerHash() => r'1e475c261f8b59dc2d6612494a520f3e811fa92c';

abstract class _$SpeechController extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(SttResult)
final sttResultProvider = SttResultProvider._();

final class SttResultProvider extends $NotifierProvider<SttResult, String> {
  SttResultProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sttResultProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sttResultHash();

  @$internal
  @override
  SttResult create() => SttResult();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$sttResultHash() => r'65050d0295a5c051d68b1d4c4ae5f4c35dd725a1';

abstract class _$SttResult extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
