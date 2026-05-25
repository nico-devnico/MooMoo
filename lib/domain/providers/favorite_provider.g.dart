// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(favoriteRepository)
final favoriteRepositoryProvider = FavoriteRepositoryProvider._();

final class FavoriteRepositoryProvider
    extends
        $FunctionalProvider<
          FavoriteRepository,
          FavoriteRepository,
          FavoriteRepository
        >
    with $Provider<FavoriteRepository> {
  FavoriteRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoriteRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoriteRepositoryHash();

  @$internal
  @override
  $ProviderElement<FavoriteRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FavoriteRepository create(Ref ref) {
    return favoriteRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FavoriteRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FavoriteRepository>(value),
    );
  }
}

String _$favoriteRepositoryHash() =>
    r'a0b81568ba1db771608f4ce7870992b0286cb998';

@ProviderFor(userFavorites)
final userFavoritesProvider = UserFavoritesProvider._();

final class UserFavoritesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Sign>>,
          List<Sign>,
          FutureOr<List<Sign>>
        >
    with $FutureModifier<List<Sign>>, $FutureProvider<List<Sign>> {
  UserFavoritesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userFavoritesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userFavoritesHash();

  @$internal
  @override
  $FutureProviderElement<List<Sign>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Sign>> create(Ref ref) {
    return userFavorites(ref);
  }
}

String _$userFavoritesHash() => r'7b567dd3b89464d458b25c9f08df7550da4c0c5f';

@ProviderFor(isSignFavorite)
final isSignFavoriteProvider = IsSignFavoriteFamily._();

final class IsSignFavoriteProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  IsSignFavoriteProvider._({
    required IsSignFavoriteFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'isSignFavoriteProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isSignFavoriteHash();

  @override
  String toString() {
    return r'isSignFavoriteProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as String;
    return isSignFavorite(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is IsSignFavoriteProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isSignFavoriteHash() => r'a39821aed7a26a69035defd33338e7f36b2c4ed7';

final class IsSignFavoriteFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, String> {
  IsSignFavoriteFamily._()
    : super(
        retry: null,
        name: r'isSignFavoriteProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  IsSignFavoriteProvider call(String signId) =>
      IsSignFavoriteProvider._(argument: signId, from: this);

  @override
  String toString() => r'isSignFavoriteProvider';
}
