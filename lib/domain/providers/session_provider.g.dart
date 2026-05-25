// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sessionRepository)
final sessionRepositoryProvider = SessionRepositoryProvider._();

final class SessionRepositoryProvider
    extends
        $FunctionalProvider<
          SessionRepository,
          SessionRepository,
          SessionRepository
        >
    with $Provider<SessionRepository> {
  SessionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionRepositoryHash();

  @$internal
  @override
  $ProviderElement<SessionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SessionRepository create(Ref ref) {
    return sessionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionRepository>(value),
    );
  }
}

String _$sessionRepositoryHash() => r'a5d6220a7b00467f611ba6a45653afd324fe5249';

@ProviderFor(sessionEntries)
final sessionEntriesProvider = SessionEntriesFamily._();

final class SessionEntriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TranslationEntry>>,
          List<TranslationEntry>,
          Stream<List<TranslationEntry>>
        >
    with
        $FutureModifier<List<TranslationEntry>>,
        $StreamProvider<List<TranslationEntry>> {
  SessionEntriesProvider._({
    required SessionEntriesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sessionEntriesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sessionEntriesHash();

  @override
  String toString() {
    return r'sessionEntriesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<TranslationEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<TranslationEntry>> create(Ref ref) {
    final argument = this.argument as String;
    return sessionEntries(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SessionEntriesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sessionEntriesHash() => r'630c46766837fbc99843b7e99522261efeb6af7b';

final class SessionEntriesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<TranslationEntry>>, String> {
  SessionEntriesFamily._()
    : super(
        retry: null,
        name: r'sessionEntriesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SessionEntriesProvider call(String sessionId) =>
      SessionEntriesProvider._(argument: sessionId, from: this);

  @override
  String toString() => r'sessionEntriesProvider';
}

@ProviderFor(userHistory)
final userHistoryProvider = UserHistoryProvider._();

final class UserHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          FutureOr<List<Map<String, dynamic>>>
        >
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $FutureProvider<List<Map<String, dynamic>>> {
  UserHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userHistoryHash();

  @$internal
  @override
  $FutureProviderElement<List<Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Map<String, dynamic>>> create(Ref ref) {
    return userHistory(ref);
  }
}

String _$userHistoryHash() => r'473d34602891699f57e23de18762921aaee15d52';
