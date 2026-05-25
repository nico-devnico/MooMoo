// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_view_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SignViewMode)
final signViewModeProvider = SignViewModeProvider._();

final class SignViewModeProvider
    extends $AsyncNotifierProvider<SignViewMode, SignViewModeEnum> {
  SignViewModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signViewModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signViewModeHash();

  @$internal
  @override
  SignViewMode create() => SignViewMode();
}

String _$signViewModeHash() => r'5647c2c93c41d91dda7def88d6b8e283430d8398';

abstract class _$SignViewMode extends $AsyncNotifier<SignViewModeEnum> {
  FutureOr<SignViewModeEnum> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<SignViewModeEnum>, SignViewModeEnum>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SignViewModeEnum>, SignViewModeEnum>,
              AsyncValue<SignViewModeEnum>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
