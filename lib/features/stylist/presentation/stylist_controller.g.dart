// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stylist_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Latest generation on the Stylist tab. `null` until the user generates.

@ProviderFor(StylistResults)
final stylistResultsProvider = StylistResultsProvider._();

/// Latest generation on the Stylist tab. `null` until the user generates.
final class StylistResultsProvider
    extends $NotifierProvider<StylistResults, AsyncValue<GenerationOutcome>?> {
  /// Latest generation on the Stylist tab. `null` until the user generates.
  StylistResultsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stylistResultsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stylistResultsHash();

  @$internal
  @override
  StylistResults create() => StylistResults();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<GenerationOutcome>? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<GenerationOutcome>?>(
        value,
      ),
    );
  }
}

String _$stylistResultsHash() => r'419b77fe77c659e706f686f95f569639094b1c71';

/// Latest generation on the Stylist tab. `null` until the user generates.

abstract class _$StylistResults
    extends $Notifier<AsyncValue<GenerationOutcome>?> {
  AsyncValue<GenerationOutcome>? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<GenerationOutcome>?,
              AsyncValue<GenerationOutcome>?
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<GenerationOutcome>?,
                AsyncValue<GenerationOutcome>?
              >,
              AsyncValue<GenerationOutcome>?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
