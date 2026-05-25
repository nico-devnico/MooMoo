// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'translator_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TranslatorState)
final translatorStateProvider = TranslatorStateProvider._();

final class TranslatorStateProvider
    extends $NotifierProvider<TranslatorState, bool> {
  TranslatorStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'translatorStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$translatorStateHash();

  @$internal
  @override
  TranslatorState create() => TranslatorState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$translatorStateHash() => r'0238b59e51286691671431e5101219de7e7bd8a5';

abstract class _$TranslatorState extends $Notifier<bool> {
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
