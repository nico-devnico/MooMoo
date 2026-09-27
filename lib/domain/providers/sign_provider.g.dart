// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(dictionaryRepository)
final dictionaryRepositoryProvider = DictionaryRepositoryProvider._();

final class DictionaryRepositoryProvider
    extends
        $FunctionalProvider<
          DictionaryRepository,
          DictionaryRepository,
          DictionaryRepository
        >
    with $Provider<DictionaryRepository> {
  DictionaryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dictionaryRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dictionaryRepositoryHash();

  @$internal
  @override
  $ProviderElement<DictionaryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DictionaryRepository create(Ref ref) {
    return dictionaryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DictionaryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DictionaryRepository>(value),
    );
  }
}

String _$dictionaryRepositoryHash() =>
    r'f385c7a6988c65ff19ea52fe74c7d36f5010d114';

/// Table de référence quasi immuable : gardée pour toute la session au lieu
/// d'être rechargée à chaque navigation vers l'accueil ou le dictionnaire.

@ProviderFor(signLanguages)
final signLanguagesProvider = SignLanguagesProvider._();

/// Table de référence quasi immuable : gardée pour toute la session au lieu
/// d'être rechargée à chaque navigation vers l'accueil ou le dictionnaire.

final class SignLanguagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SignLanguage>>,
          List<SignLanguage>,
          FutureOr<List<SignLanguage>>
        >
    with
        $FutureModifier<List<SignLanguage>>,
        $FutureProvider<List<SignLanguage>> {
  /// Table de référence quasi immuable : gardée pour toute la session au lieu
  /// d'être rechargée à chaque navigation vers l'accueil ou le dictionnaire.
  SignLanguagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signLanguagesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signLanguagesHash();

  @$internal
  @override
  $FutureProviderElement<List<SignLanguage>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SignLanguage>> create(Ref ref) {
    return signLanguages(ref);
  }
}

String _$signLanguagesHash() => r'8ab521ed9070edbdcfe2871fa25133975872562f';

/// Idem pour les catégories, mises en cache par langue.

@ProviderFor(signCategories)
final signCategoriesProvider = SignCategoriesFamily._();

/// Idem pour les catégories, mises en cache par langue.

final class SignCategoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SignCategory>>,
          List<SignCategory>,
          FutureOr<List<SignCategory>>
        >
    with
        $FutureModifier<List<SignCategory>>,
        $FutureProvider<List<SignCategory>> {
  /// Idem pour les catégories, mises en cache par langue.
  SignCategoriesProvider._({
    required SignCategoriesFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'signCategoriesProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$signCategoriesHash();

  @override
  String toString() {
    return r'signCategoriesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<SignCategory>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SignCategory>> create(Ref ref) {
    final argument = this.argument as int;
    return signCategories(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SignCategoriesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$signCategoriesHash() => r'c63fc6f7af38e71fef420a03293f92b483371f96';

/// Idem pour les catégories, mises en cache par langue.

final class SignCategoriesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<SignCategory>>, int> {
  SignCategoriesFamily._()
    : super(
        retry: null,
        name: r'signCategoriesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Idem pour les catégories, mises en cache par langue.

  SignCategoriesProvider call(int languageId) =>
      SignCategoriesProvider._(argument: languageId, from: this);

  @override
  String toString() => r'signCategoriesProvider';
}

@ProviderFor(SignSearch)
final signSearchProvider = SignSearchFamily._();

final class SignSearchProvider
    extends $AsyncNotifierProvider<SignSearch, List<Sign>> {
  SignSearchProvider._({
    required SignSearchFamily super.from,
    required ({
      String? query,
      int? languageId,
      int? categoryId,
      int? difficultyLevel,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'signSearchProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$signSearchHash();

  @override
  String toString() {
    return r'signSearchProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  SignSearch create() => SignSearch();

  @override
  bool operator ==(Object other) {
    return other is SignSearchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$signSearchHash() => r'cb0f9af31c3185e178dd0216908dd7cd0a9c46ce';

final class SignSearchFamily extends $Family
    with
        $ClassFamilyOverride<
          SignSearch,
          AsyncValue<List<Sign>>,
          List<Sign>,
          FutureOr<List<Sign>>,
          ({
            String? query,
            int? languageId,
            int? categoryId,
            int? difficultyLevel,
          })
        > {
  SignSearchFamily._()
    : super(
        retry: null,
        name: r'signSearchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SignSearchProvider call({
    String? query,
    int? languageId,
    int? categoryId,
    int? difficultyLevel,
  }) => SignSearchProvider._(
    argument: (
      query: query,
      languageId: languageId,
      categoryId: categoryId,
      difficultyLevel: difficultyLevel,
    ),
    from: this,
  );

  @override
  String toString() => r'signSearchProvider';
}

abstract class _$SignSearch extends $AsyncNotifier<List<Sign>> {
  late final _$args =
      ref.$arg
          as ({
            String? query,
            int? languageId,
            int? categoryId,
            int? difficultyLevel,
          });
  String? get query => _$args.query;
  int? get languageId => _$args.languageId;
  int? get categoryId => _$args.categoryId;
  int? get difficultyLevel => _$args.difficultyLevel;

  FutureOr<List<Sign>> build({
    String? query,
    int? languageId,
    int? categoryId,
    int? difficultyLevel,
  });
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Sign>>, List<Sign>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Sign>>, List<Sign>>,
              AsyncValue<List<Sign>>,
              Object?,
              Object?
            >;
    element.handleCreate(
      ref,
      () => build(
        query: _$args.query,
        languageId: _$args.languageId,
        categoryId: _$args.categoryId,
        difficultyLevel: _$args.difficultyLevel,
      ),
    );
  }
}

@ProviderFor(signDetail)
final signDetailProvider = SignDetailFamily._();

final class SignDetailProvider
    extends $FunctionalProvider<AsyncValue<Sign?>, Sign?, FutureOr<Sign?>>
    with $FutureModifier<Sign?>, $FutureProvider<Sign?> {
  SignDetailProvider._({
    required SignDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'signDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$signDetailHash();

  @override
  String toString() {
    return r'signDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Sign?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Sign?> create(Ref ref) {
    final argument = this.argument as String;
    return signDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SignDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$signDetailHash() => r'376478a0f2b57e36d50cdd9e25d20a6385e66e0b';

final class SignDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Sign?>, String> {
  SignDetailFamily._()
    : super(
        retry: null,
        name: r'signDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SignDetailProvider call(String id) =>
      SignDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'signDetailProvider';
}
