// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorites_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(feedbackRepository)
final feedbackRepositoryProvider = FeedbackRepositoryProvider._();

final class FeedbackRepositoryProvider
    extends
        $FunctionalProvider<
          FeedbackRepository,
          FeedbackRepository,
          FeedbackRepository
        >
    with $Provider<FeedbackRepository> {
  FeedbackRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feedbackRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedbackRepositoryHash();

  @$internal
  @override
  $ProviderElement<FeedbackRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FeedbackRepository create(Ref ref) {
    return feedbackRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FeedbackRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FeedbackRepository>(value),
    );
  }
}

String _$feedbackRepositoryHash() =>
    r'3d49f1750fdb2f015c0fec33830ba6dac8dfecbc';

@ProviderFor(personalizationRepository)
final personalizationRepositoryProvider = PersonalizationRepositoryProvider._();

final class PersonalizationRepositoryProvider
    extends
        $FunctionalProvider<
          PersonalizationRepository,
          PersonalizationRepository,
          PersonalizationRepository
        >
    with $Provider<PersonalizationRepository> {
  PersonalizationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'personalizationRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$personalizationRepositoryHash();

  @$internal
  @override
  $ProviderElement<PersonalizationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PersonalizationRepository create(Ref ref) {
    return personalizationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PersonalizationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PersonalizationRepository>(value),
    );
  }
}

String _$personalizationRepositoryHash() =>
    r'68bb8fade2fd84bbdea10309875328b3d2fa32c1';

@ProviderFor(recordFeedback)
final recordFeedbackProvider = RecordFeedbackProvider._();

final class RecordFeedbackProvider
    extends $FunctionalProvider<RecordFeedback, RecordFeedback, RecordFeedback>
    with $Provider<RecordFeedback> {
  RecordFeedbackProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recordFeedbackProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recordFeedbackHash();

  @$internal
  @override
  $ProviderElement<RecordFeedback> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RecordFeedback create(Ref ref) {
    return recordFeedback(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecordFeedback value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecordFeedback>(value),
    );
  }
}

String _$recordFeedbackHash() => r'7d9af811becf81ea89706d59847b13628a630cd4';

@ProviderFor(setFavorite)
final setFavoriteProvider = SetFavoriteProvider._();

final class SetFavoriteProvider
    extends $FunctionalProvider<SetFavorite, SetFavorite, SetFavorite>
    with $Provider<SetFavorite> {
  SetFavoriteProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'setFavoriteProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$setFavoriteHash();

  @$internal
  @override
  $ProviderElement<SetFavorite> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SetFavorite create(Ref ref) {
    return setFavorite(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SetFavorite value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SetFavorite>(value),
    );
  }
}

String _$setFavoriteHash() => r'2c69dc72f98f9760369263d3879c600d4cd801d8';

@ProviderFor(resetPersonalization)
final resetPersonalizationProvider = ResetPersonalizationProvider._();

final class ResetPersonalizationProvider
    extends
        $FunctionalProvider<
          ResetPersonalization,
          ResetPersonalization,
          ResetPersonalization
        >
    with $Provider<ResetPersonalization> {
  ResetPersonalizationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'resetPersonalizationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$resetPersonalizationHash();

  @$internal
  @override
  $ProviderElement<ResetPersonalization> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ResetPersonalization create(Ref ref) {
    return resetPersonalization(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ResetPersonalization value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ResetPersonalization>(value),
    );
  }
}

String _$resetPersonalizationHash() =>
    r'0aabd3261d1d057de1be09cc5282be50398dd292';

/// Outfit history (newest first) or only favourites.

@ProviderFor(outfitHistory)
final outfitHistoryProvider = OutfitHistoryFamily._();

/// Outfit history (newest first) or only favourites.

final class OutfitHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OutfitHistoryEntry>>,
          List<OutfitHistoryEntry>,
          Stream<List<OutfitHistoryEntry>>
        >
    with
        $FutureModifier<List<OutfitHistoryEntry>>,
        $StreamProvider<List<OutfitHistoryEntry>> {
  /// Outfit history (newest first) or only favourites.
  OutfitHistoryProvider._({
    required OutfitHistoryFamily super.from,
    required bool super.argument,
  }) : super(
         retry: null,
         name: r'outfitHistoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$outfitHistoryHash();

  @override
  String toString() {
    return r'outfitHistoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<OutfitHistoryEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<OutfitHistoryEntry>> create(Ref ref) {
    final argument = this.argument as bool;
    return outfitHistory(ref, favoritesOnly: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OutfitHistoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$outfitHistoryHash() => r'880a68d7556ea573749fd8ee3be3e0edcc95e94d';

/// Outfit history (newest first) or only favourites.

final class OutfitHistoryFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<OutfitHistoryEntry>>, bool> {
  OutfitHistoryFamily._()
    : super(
        retry: null,
        name: r'outfitHistoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Outfit history (newest first) or only favourites.

  OutfitHistoryProvider call({required bool favoritesOnly}) =>
      OutfitHistoryProvider._(argument: favoritesOnly, from: this);

  @override
  String toString() => r'outfitHistoryProvider';
}

/// One outfit with its current rating and favourite state.

@ProviderFor(outfitEntry)
final outfitEntryProvider = OutfitEntryFamily._();

/// One outfit with its current rating and favourite state.

final class OutfitEntryProvider
    extends
        $FunctionalProvider<
          AsyncValue<OutfitHistoryEntry?>,
          OutfitHistoryEntry?,
          Stream<OutfitHistoryEntry?>
        >
    with
        $FutureModifier<OutfitHistoryEntry?>,
        $StreamProvider<OutfitHistoryEntry?> {
  /// One outfit with its current rating and favourite state.
  OutfitEntryProvider._({
    required OutfitEntryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'outfitEntryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$outfitEntryHash();

  @override
  String toString() {
    return r'outfitEntryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<OutfitHistoryEntry?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<OutfitHistoryEntry?> create(Ref ref) {
    final argument = this.argument as String;
    return outfitEntry(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OutfitEntryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$outfitEntryHash() => r'6980c6125f782c14c8bed4e4bd2ae818dade14ce';

/// One outfit with its current rating and favourite state.

final class OutfitEntryFamily extends $Family
    with $FunctionalFamilyOverride<Stream<OutfitHistoryEntry?>, String> {
  OutfitEntryFamily._()
    : super(
        retry: null,
        name: r'outfitEntryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One outfit with its current rating and favourite state.

  OutfitEntryProvider call(String outfitId) =>
      OutfitEntryProvider._(argument: outfitId, from: this);

  @override
  String toString() => r'outfitEntryProvider';
}

@ProviderFor(learnedPreferences)
final learnedPreferencesProvider = LearnedPreferencesProvider._();

final class LearnedPreferencesProvider
    extends
        $FunctionalProvider<
          AsyncValue<LearnedPreferences>,
          LearnedPreferences,
          Stream<LearnedPreferences>
        >
    with
        $FutureModifier<LearnedPreferences>,
        $StreamProvider<LearnedPreferences> {
  LearnedPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'learnedPreferencesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$learnedPreferencesHash();

  @$internal
  @override
  $StreamProviderElement<LearnedPreferences> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<LearnedPreferences> create(Ref ref) {
    return learnedPreferences(ref);
  }
}

String _$learnedPreferencesHash() =>
    r'989a50616e15ea469e7c46bc5abac995ab8e578c';
