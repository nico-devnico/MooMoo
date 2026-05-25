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

String _$speechControllerHash() => r'b6c69e509bd39756cd375b66bfb1e2872a4fca57';

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
