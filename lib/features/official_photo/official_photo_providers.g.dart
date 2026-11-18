// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'official_photo_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(secretStore)
final secretStoreProvider = SecretStoreProvider._();

final class SecretStoreProvider
    extends $FunctionalProvider<SecretStore, SecretStore, SecretStore>
    with $Provider<SecretStore> {
  SecretStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'secretStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$secretStoreHash();

  @$internal
  @override
  $ProviderElement<SecretStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SecretStore create(Ref ref) {
    return secretStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SecretStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SecretStore>(value),
    );
  }
}

String _$secretStoreHash() => r'eb0b7784f35ec0fb86eda263d033d31ef3ae7d59';

@ProviderFor(officialPhotoSettings)
final officialPhotoSettingsProvider = OfficialPhotoSettingsProvider._();

final class OfficialPhotoSettingsProvider
    extends
        $FunctionalProvider<
          OfficialPhotoSettings,
          OfficialPhotoSettings,
          OfficialPhotoSettings
        >
    with $Provider<OfficialPhotoSettings> {
  OfficialPhotoSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'officialPhotoSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$officialPhotoSettingsHash();

  @$internal
  @override
  $ProviderElement<OfficialPhotoSettings> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  OfficialPhotoSettings create(Ref ref) {
    return officialPhotoSettings(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OfficialPhotoSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OfficialPhotoSettings>(value),
    );
  }
}

String _$officialPhotoSettingsHash() =>
    r'cfa95bc25147352fc08c213bcb52ffa3d1841362';

@ProviderFor(productImageSearch)
final productImageSearchProvider = ProductImageSearchProvider._();

final class ProductImageSearchProvider
    extends
        $FunctionalProvider<
          ProductImageSearch,
          ProductImageSearch,
          ProductImageSearch
        >
    with $Provider<ProductImageSearch> {
  ProductImageSearchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'productImageSearchProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$productImageSearchHash();

  @$internal
  @override
  $ProviderElement<ProductImageSearch> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProductImageSearch create(Ref ref) {
    return productImageSearch(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProductImageSearch value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProductImageSearch>(value),
    );
  }
}

String _$productImageSearchHash() =>
    r'c527a2db68dfe65430471ed1fe8961e800ef1a98';

@ProviderFor(candidateDownloader)
final candidateDownloaderProvider = CandidateDownloaderProvider._();

final class CandidateDownloaderProvider
    extends
        $FunctionalProvider<
          CandidateDownloader,
          CandidateDownloader,
          CandidateDownloader
        >
    with $Provider<CandidateDownloader> {
  CandidateDownloaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'candidateDownloaderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$candidateDownloaderHash();

  @$internal
  @override
  $ProviderElement<CandidateDownloader> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CandidateDownloader create(Ref ref) {
    return candidateDownloader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CandidateDownloader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CandidateDownloader>(value),
    );
  }
}

String _$candidateDownloaderHash() =>
    r'1f5dc74938a43ea03e438db27db335e94ab1f31d';

/// Official-photo suggestions for the cut-out at [imagePath] of item
/// [itemId]. Computed once while the item is on screen; "search again"
/// invalidates it.

@ProviderFor(officialPhotoSuggestions)
final officialPhotoSuggestionsProvider = OfficialPhotoSuggestionsFamily._();

/// Official-photo suggestions for the cut-out at [imagePath] of item
/// [itemId]. Computed once while the item is on screen; "search again"
/// invalidates it.

final class OfficialPhotoSuggestionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Result<List<DownloadedCandidate>>>,
          Result<List<DownloadedCandidate>>,
          FutureOr<Result<List<DownloadedCandidate>>>
        >
    with
        $FutureModifier<Result<List<DownloadedCandidate>>>,
        $FutureProvider<Result<List<DownloadedCandidate>>> {
  /// Official-photo suggestions for the cut-out at [imagePath] of item
  /// [itemId]. Computed once while the item is on screen; "search again"
  /// invalidates it.
  OfficialPhotoSuggestionsProvider._({
    required OfficialPhotoSuggestionsFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'officialPhotoSuggestionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$officialPhotoSuggestionsHash();

  @override
  String toString() {
    return r'officialPhotoSuggestionsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<Result<List<DownloadedCandidate>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Result<List<DownloadedCandidate>>> create(Ref ref) {
    final argument = this.argument as (String, String);
    return officialPhotoSuggestions(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is OfficialPhotoSuggestionsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$officialPhotoSuggestionsHash() =>
    r'b8f99d44bb66e3a4555818213d263074ee3fe3fb';

/// Official-photo suggestions for the cut-out at [imagePath] of item
/// [itemId]. Computed once while the item is on screen; "search again"
/// invalidates it.

final class OfficialPhotoSuggestionsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<Result<List<DownloadedCandidate>>>,
          (String, String)
        > {
  OfficialPhotoSuggestionsFamily._()
    : super(
        retry: null,
        name: r'officialPhotoSuggestionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Official-photo suggestions for the cut-out at [imagePath] of item
  /// [itemId]. Computed once while the item is on screen; "search again"
  /// invalidates it.

  OfficialPhotoSuggestionsProvider call(String itemId, String imagePath) =>
      OfficialPhotoSuggestionsProvider._(
        argument: (itemId, imagePath),
        from: this,
      );

  @override
  String toString() => r'officialPhotoSuggestionsProvider';
}

/// The feature's switch and whether a key is saved, for the settings UI.

@ProviderFor(OfficialPhotoState)
final officialPhotoStateProvider = OfficialPhotoStateProvider._();

/// The feature's switch and whether a key is saved, for the settings UI.
final class OfficialPhotoStateProvider
    extends
        $AsyncNotifierProvider<
          OfficialPhotoState,
          ({bool enabled, bool hasKey})
        > {
  /// The feature's switch and whether a key is saved, for the settings UI.
  OfficialPhotoStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'officialPhotoStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$officialPhotoStateHash();

  @$internal
  @override
  OfficialPhotoState create() => OfficialPhotoState();
}

String _$officialPhotoStateHash() =>
    r'52ed289e0786a9a311c0aef78cc0b0be773efa5b';

/// The feature's switch and whether a key is saved, for the settings UI.

abstract class _$OfficialPhotoState
    extends $AsyncNotifier<({bool enabled, bool hasKey})> {
  FutureOr<({bool enabled, bool hasKey})> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<({bool enabled, bool hasKey})>,
              ({bool enabled, bool hasKey})
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<({bool enabled, bool hasKey})>,
                ({bool enabled, bool hasKey})
              >,
              AsyncValue<({bool enabled, bool hasKey})>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
