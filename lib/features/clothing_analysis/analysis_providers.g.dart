// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Thresholds for prefill / confirm / hint (D-09).

@ProviderFor(confidencePolicy)
final confidencePolicyProvider = ConfidencePolicyProvider._();

/// Thresholds for prefill / confirm / hint (D-09).

final class ConfidencePolicyProvider
    extends
        $FunctionalProvider<
          ConfidencePolicy,
          ConfidencePolicy,
          ConfidencePolicy
        >
    with $Provider<ConfidencePolicy> {
  /// Thresholds for prefill / confirm / hint (D-09).
  ConfidencePolicyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'confidencePolicyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$confidencePolicyHash();

  @$internal
  @override
  $ProviderElement<ConfidencePolicy> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ConfidencePolicy create(Ref ref) {
    return confidencePolicy(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConfidencePolicy value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConfidencePolicy>(value),
    );
  }
}

String _$confidencePolicyHash() => r'ddc8208ae4cf1519ce4f4bd796c8af1c141fc505';

/// Optional model downloads (FR-09). Only runs when the user taps Download.

@ProviderFor(modelDownloadManager)
final modelDownloadManagerProvider = ModelDownloadManagerProvider._();

/// Optional model downloads (FR-09). Only runs when the user taps Download.

final class ModelDownloadManagerProvider
    extends
        $FunctionalProvider<
          ModelDownloadManager,
          ModelDownloadManager,
          ModelDownloadManager
        >
    with $Provider<ModelDownloadManager> {
  /// Optional model downloads (FR-09). Only runs when the user taps Download.
  ModelDownloadManagerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'modelDownloadManagerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$modelDownloadManagerHash();

  @$internal
  @override
  $ProviderElement<ModelDownloadManager> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ModelDownloadManager create(Ref ref) {
    return modelDownloadManager(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ModelDownloadManager value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ModelDownloadManager>(value),
    );
  }
}

String _$modelDownloadManagerHash() =>
    r'13e302eb359773a0aba03fdfc6b2041fcdf2d6ad';

/// Bundled and optional models. Loading a model always goes
/// through the SHA-256 check in [ModelRegistry.loadVerified].

@ProviderFor(modelRegistry)
final modelRegistryProvider = ModelRegistryProvider._();

/// Bundled and optional models. Loading a model always goes
/// through the SHA-256 check in [ModelRegistry.loadVerified].

final class ModelRegistryProvider
    extends
        $FunctionalProvider<
          AsyncValue<ModelRegistry>,
          ModelRegistry,
          FutureOr<ModelRegistry>
        >
    with $FutureModifier<ModelRegistry>, $FutureProvider<ModelRegistry> {
  /// Bundled and optional models. Loading a model always goes
  /// through the SHA-256 check in [ModelRegistry.loadVerified].
  ModelRegistryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'modelRegistryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$modelRegistryHash();

  @$internal
  @override
  $FutureProviderElement<ModelRegistry> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ModelRegistry> create(Ref ref) {
    return modelRegistry(ref);
  }
}

String _$modelRegistryHash() => r'00c6421315424e9b3d823292e5d5c8ff13c525e9';

/// The bundled Tier-1 garment classifier (D-08, D-38). The model is
/// opened on first use and released when the provider is disposed.

@ProviderFor(garmentClassifier)
final garmentClassifierProvider = GarmentClassifierProvider._();

/// The bundled Tier-1 garment classifier (D-08, D-38). The model is
/// opened on first use and released when the provider is disposed.

final class GarmentClassifierProvider
    extends
        $FunctionalProvider<
          GarmentClassifier,
          GarmentClassifier,
          GarmentClassifier
        >
    with $Provider<GarmentClassifier> {
  /// The bundled Tier-1 garment classifier (D-08, D-38). The model is
  /// opened on first use and released when the provider is disposed.
  GarmentClassifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'garmentClassifierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$garmentClassifierHash();

  @$internal
  @override
  $ProviderElement<GarmentClassifier> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GarmentClassifier create(Ref ref) {
    return garmentClassifier(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GarmentClassifier value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GarmentClassifier>(value),
    );
  }
}

String _$garmentClassifierHash() => r'786132c016903c38fa66dd73e0259c19d22cb9c9';

/// All analyzers available on this device: Tier 0 (colour) and the Tier-1
/// garment classifier (category, type, pattern). Either can fail without
/// blocking the other or manual entry.

@ProviderFor(clothingAnalyzer)
final clothingAnalyzerProvider = ClothingAnalyzerProvider._();

/// All analyzers available on this device: Tier 0 (colour) and the Tier-1
/// garment classifier (category, type, pattern). Either can fail without
/// blocking the other or manual entry.

final class ClothingAnalyzerProvider
    extends
        $FunctionalProvider<
          ClothingAnalyzer,
          ClothingAnalyzer,
          ClothingAnalyzer
        >
    with $Provider<ClothingAnalyzer> {
  /// All analyzers available on this device: Tier 0 (colour) and the Tier-1
  /// garment classifier (category, type, pattern). Either can fail without
  /// blocking the other or manual entry.
  ClothingAnalyzerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clothingAnalyzerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clothingAnalyzerHash();

  @$internal
  @override
  $ProviderElement<ClothingAnalyzer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ClothingAnalyzer create(Ref ref) {
    return clothingAnalyzer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClothingAnalyzer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClothingAnalyzer>(value),
    );
  }
}

String _$clothingAnalyzerHash() => r'f2302c25e2b8e407c7adcfbc925461127b9a7454';

@ProviderFor(analysisRepository)
final analysisRepositoryProvider = AnalysisRepositoryProvider._();

final class AnalysisRepositoryProvider
    extends
        $FunctionalProvider<
          AnalysisRepository,
          AnalysisRepository,
          AnalysisRepository
        >
    with $Provider<AnalysisRepository> {
  AnalysisRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analysisRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analysisRepositoryHash();

  @$internal
  @override
  $ProviderElement<AnalysisRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AnalysisRepository create(Ref ref) {
    return analysisRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnalysisRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnalysisRepository>(value),
    );
  }
}

String _$analysisRepositoryHash() =>
    r'39c82f5a060cfb18cefb228f83a70348762e6561';

@ProviderFor(confirmAnalysis)
final confirmAnalysisProvider = ConfirmAnalysisProvider._();

final class ConfirmAnalysisProvider
    extends
        $FunctionalProvider<ConfirmAnalysis, ConfirmAnalysis, ConfirmAnalysis>
    with $Provider<ConfirmAnalysis> {
  ConfirmAnalysisProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'confirmAnalysisProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$confirmAnalysisHash();

  @$internal
  @override
  $ProviderElement<ConfirmAnalysis> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ConfirmAnalysis create(Ref ref) {
    return confirmAnalysis(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConfirmAnalysis value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConfirmAnalysis>(value),
    );
  }
}

String _$confirmAnalysisHash() => r'54d3fea21f367878b6a5c40b700224071058248a';

/// Suggestions for one item: cached if analysed before, otherwise computed
/// from its thumbnail off the UI thread. Errors surface as `AsyncError`;
/// the review screen then simply offers manual entry.

@ProviderFor(clothingAnalysis)
final clothingAnalysisProvider = ClothingAnalysisFamily._();

/// Suggestions for one item: cached if analysed before, otherwise computed
/// from its thumbnail off the UI thread. Errors surface as `AsyncError`;
/// the review screen then simply offers manual entry.

final class ClothingAnalysisProvider
    extends
        $FunctionalProvider<
          AsyncValue<ClothingAnalysis>,
          ClothingAnalysis,
          FutureOr<ClothingAnalysis>
        >
    with $FutureModifier<ClothingAnalysis>, $FutureProvider<ClothingAnalysis> {
  /// Suggestions for one item: cached if analysed before, otherwise computed
  /// from its thumbnail off the UI thread. Errors surface as `AsyncError`;
  /// the review screen then simply offers manual entry.
  ClothingAnalysisProvider._({
    required ClothingAnalysisFamily super.from,
    required String super.argument,
  }) : super(
         retry: _noRetry,
         name: r'clothingAnalysisProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$clothingAnalysisHash();

  @override
  String toString() {
    return r'clothingAnalysisProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ClothingAnalysis> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ClothingAnalysis> create(Ref ref) {
    final argument = this.argument as String;
    return clothingAnalysis(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ClothingAnalysisProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$clothingAnalysisHash() => r'7f59f18dfbddc3ef04d15b187240c93f3815d60c';

/// Suggestions for one item: cached if analysed before, otherwise computed
/// from its thumbnail off the UI thread. Errors surface as `AsyncError`;
/// the review screen then simply offers manual entry.

final class ClothingAnalysisFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ClothingAnalysis>, String> {
  ClothingAnalysisFamily._()
    : super(
        retry: _noRetry,
        name: r'clothingAnalysisProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Suggestions for one item: cached if analysed before, otherwise computed
  /// from its thumbnail off the UI thread. Errors surface as `AsyncError`;
  /// the review screen then simply offers manual entry.

  ClothingAnalysisProvider call(String itemId) =>
      ClothingAnalysisProvider._(argument: itemId, from: this);

  @override
  String toString() => r'clothingAnalysisProvider';
}
