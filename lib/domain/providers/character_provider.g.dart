// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(characters)
final charactersProvider = CharactersProvider._();

final class CharactersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Character>>,
          List<Character>,
          FutureOr<List<Character>>
        >
    with $FutureModifier<List<Character>>, $FutureProvider<List<Character>> {
  CharactersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'charactersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$charactersHash();

  @$internal
  @override
  $FutureProviderElement<List<Character>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Character>> create(Ref ref) {
    return characters(ref);
  }
}

String _$charactersHash() => r'039aedbdd553154fb340843b1a014abe80307970';

@ProviderFor(characterById)
final characterByIdProvider = CharacterByIdFamily._();

final class CharacterByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<Character?>,
          Character?,
          FutureOr<Character?>
        >
    with $FutureModifier<Character?>, $FutureProvider<Character?> {
  CharacterByIdProvider._({
    required CharacterByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'characterByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$characterByIdHash();

  @override
  String toString() {
    return r'characterByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Character?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Character?> create(Ref ref) {
    final argument = this.argument as String;
    return characterById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CharacterByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$characterByIdHash() => r'6e9bc2effeed81c7baea366606bbb9f658defafa';

final class CharacterByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Character?>, String> {
  CharacterByIdFamily._()
    : super(
        retry: null,
        name: r'characterByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CharacterByIdProvider call(String id) =>
      CharacterByIdProvider._(argument: id, from: this);

  @override
  String toString() => r'characterByIdProvider';
}
