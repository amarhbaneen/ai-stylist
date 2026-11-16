// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_downloads.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Install state of one optional model, by ID.

@ProviderFor(modelInstallState)
final modelInstallStateProvider = ModelInstallStateFamily._();

/// Install state of one optional model, by ID.

final class ModelInstallStateProvider
    extends
        $FunctionalProvider<
          AsyncValue<ModelInstallState>,
          ModelInstallState,
          FutureOr<ModelInstallState>
        >
    with
        $FutureModifier<ModelInstallState>,
        $FutureProvider<ModelInstallState> {
  /// Install state of one optional model, by ID.
  ModelInstallStateProvider._({
    required ModelInstallStateFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'modelInstallStateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$modelInstallStateHash();

  @override
  String toString() {
    return r'modelInstallStateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ModelInstallState> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ModelInstallState> create(Ref ref) {
    final argument = this.argument as String;
    return modelInstallState(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ModelInstallStateProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$modelInstallStateHash() => r'f8b74c016a6f381baa221f5ed2b88e51752c45cb';

/// Install state of one optional model, by ID.

final class ModelInstallStateFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ModelInstallState>, String> {
  ModelInstallStateFamily._()
    : super(
        retry: null,
        name: r'modelInstallStateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Install state of one optional model, by ID.

  ModelInstallStateProvider call(String modelId) =>
      ModelInstallStateProvider._(argument: modelId, from: this);

  @override
  String toString() => r'modelInstallStateProvider';
}

/// Running downloads (model ID → progress 0..1). Kept alive so a download
/// continues if the user leaves the model screen.

@ProviderFor(ModelDownloads)
final modelDownloadsProvider = ModelDownloadsProvider._();

/// Running downloads (model ID → progress 0..1). Kept alive so a download
/// continues if the user leaves the model screen.
final class ModelDownloadsProvider
    extends $NotifierProvider<ModelDownloads, Map<String, double>> {
  /// Running downloads (model ID → progress 0..1). Kept alive so a download
  /// continues if the user leaves the model screen.
  ModelDownloadsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'modelDownloadsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$modelDownloadsHash();

  @$internal
  @override
  ModelDownloads create() => ModelDownloads();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, double> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, double>>(value),
    );
  }
}

String _$modelDownloadsHash() => r'13e0abdd93bce002a1c65b28e747a6b6c5a0f7eb';

/// Running downloads (model ID → progress 0..1). Kept alive so a download
/// continues if the user leaves the model screen.

abstract class _$ModelDownloads extends $Notifier<Map<String, double>> {
  Map<String, double> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Map<String, double>, Map<String, double>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, double>, Map<String, double>>,
              Map<String, double>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
