// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stylist_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(outfitRepository)
final outfitRepositoryProvider = OutfitRepositoryProvider._();

final class OutfitRepositoryProvider
    extends
        $FunctionalProvider<
          OutfitRepository,
          OutfitRepository,
          OutfitRepository
        >
    with $Provider<OutfitRepository> {
  OutfitRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'outfitRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$outfitRepositoryHash();

  @$internal
  @override
  $ProviderElement<OutfitRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OutfitRepository create(Ref ref) {
    return outfitRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OutfitRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OutfitRepository>(value),
    );
  }
}

String _$outfitRepositoryHash() => r'22535524d293f1b56eb8868860337ffc9f82dd0d';

/// Overridden in widget tests, where isolates cannot run on the fake clock.

@ProviderFor(engineRunner)
final engineRunnerProvider = EngineRunnerProvider._();

/// Overridden in widget tests, where isolates cannot run on the fake clock.

final class EngineRunnerProvider
    extends $FunctionalProvider<EngineRunner, EngineRunner, EngineRunner>
    with $Provider<EngineRunner> {
  /// Overridden in widget tests, where isolates cannot run on the fake clock.
  EngineRunnerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'engineRunnerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$engineRunnerHash();

  @$internal
  @override
  $ProviderElement<EngineRunner> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EngineRunner create(Ref ref) {
    return engineRunner(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EngineRunner value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EngineRunner>(value),
    );
  }
}

String _$engineRunnerHash() => r'7fa95c8b4558d3c5a450048347752d54d3fa4109';

@ProviderFor(generateOutfits)
final generateOutfitsProvider = GenerateOutfitsProvider._();

final class GenerateOutfitsProvider
    extends
        $FunctionalProvider<GenerateOutfits, GenerateOutfits, GenerateOutfits>
    with $Provider<GenerateOutfits> {
  GenerateOutfitsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'generateOutfitsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$generateOutfitsHash();

  @$internal
  @override
  $ProviderElement<GenerateOutfits> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GenerateOutfits create(Ref ref) {
    return generateOutfits(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GenerateOutfits value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GenerateOutfits>(value),
    );
  }
}

String _$generateOutfitsHash() => r'4dab6532db8aef87a180c5e0521ee8cf56836710';

/// One stored outfit, live.

@ProviderFor(savedOutfit)
final savedOutfitProvider = SavedOutfitFamily._();

/// One stored outfit, live.

final class SavedOutfitProvider
    extends
        $FunctionalProvider<
          AsyncValue<SavedOutfit?>,
          SavedOutfit?,
          Stream<SavedOutfit?>
        >
    with $FutureModifier<SavedOutfit?>, $StreamProvider<SavedOutfit?> {
  /// One stored outfit, live.
  SavedOutfitProvider._({
    required SavedOutfitFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'savedOutfitProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$savedOutfitHash();

  @override
  String toString() {
    return r'savedOutfitProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<SavedOutfit?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<SavedOutfit?> create(Ref ref) {
    final argument = this.argument as String;
    return savedOutfit(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SavedOutfitProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$savedOutfitHash() => r'd67a5da3d0897c1aafbafb7973f433dd9407e259';

/// One stored outfit, live.

final class SavedOutfitFamily extends $Family
    with $FunctionalFamilyOverride<Stream<SavedOutfit?>, String> {
  SavedOutfitFamily._()
    : super(
        retry: null,
        name: r'savedOutfitProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One stored outfit, live.

  SavedOutfitProvider call(String id) =>
      SavedOutfitProvider._(argument: id, from: this);

  @override
  String toString() => r'savedOutfitProvider';
}
