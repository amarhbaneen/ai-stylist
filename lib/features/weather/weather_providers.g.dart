// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's only HTTP client. Overridden in tests (no real network).

@ProviderFor(httpClient)
final httpClientProvider = HttpClientProvider._();

/// The app's only HTTP client. Overridden in tests (no real network).

final class HttpClientProvider
    extends $FunctionalProvider<http.Client, http.Client, http.Client>
    with $Provider<http.Client> {
  /// The app's only HTTP client. Overridden in tests (no real network).
  HttpClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'httpClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$httpClientHash();

  @$internal
  @override
  $ProviderElement<http.Client> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  http.Client create(Ref ref) {
    return httpClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(http.Client value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<http.Client>(value),
    );
  }
}

String _$httpClientHash() => r'7ec49beae0f15115de79f9aa98dbd250130e26d8';

@ProviderFor(cityDirectory)
final cityDirectoryProvider = CityDirectoryProvider._();

final class CityDirectoryProvider
    extends $FunctionalProvider<CityDirectory, CityDirectory, CityDirectory>
    with $Provider<CityDirectory> {
  CityDirectoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cityDirectoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cityDirectoryHash();

  @$internal
  @override
  $ProviderElement<CityDirectory> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CityDirectory create(Ref ref) {
    return cityDirectory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CityDirectory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CityDirectory>(value),
    );
  }
}

String _$cityDirectoryHash() => r'3bf703e1766a05e01a655646227dee0f912474e7';

@ProviderFor(weatherRepository)
final weatherRepositoryProvider = WeatherRepositoryProvider._();

final class WeatherRepositoryProvider
    extends
        $FunctionalProvider<
          WeatherRepository,
          WeatherRepository,
          WeatherRepository
        >
    with $Provider<WeatherRepository> {
  WeatherRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weatherRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weatherRepositoryHash();

  @$internal
  @override
  $ProviderElement<WeatherRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WeatherRepository create(Ref ref) {
    return weatherRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WeatherRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WeatherRepository>(value),
    );
  }
}

String _$weatherRepositoryHash() => r'9501a600827405248160ab85359bd955ec5ac4c6';

@ProviderFor(weatherSettings)
final weatherSettingsProvider = WeatherSettingsProvider._();

final class WeatherSettingsProvider
    extends
        $FunctionalProvider<
          WeatherSettingsRepository,
          WeatherSettingsRepository,
          WeatherSettingsRepository
        >
    with $Provider<WeatherSettingsRepository> {
  WeatherSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weatherSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weatherSettingsHash();

  @$internal
  @override
  $ProviderElement<WeatherSettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WeatherSettingsRepository create(Ref ref) {
    return weatherSettings(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WeatherSettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WeatherSettingsRepository>(value),
    );
  }
}

String _$weatherSettingsHash() => r'9878bb43f46f35b65e7a357d6a7ebcf6e165071c';

@ProviderFor(fetchLiveWeather)
final fetchLiveWeatherProvider = FetchLiveWeatherProvider._();

final class FetchLiveWeatherProvider
    extends
        $FunctionalProvider<
          FetchLiveWeather,
          FetchLiveWeather,
          FetchLiveWeather
        >
    with $Provider<FetchLiveWeather> {
  FetchLiveWeatherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fetchLiveWeatherProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fetchLiveWeatherHash();

  @$internal
  @override
  $ProviderElement<FetchLiveWeather> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FetchLiveWeather create(Ref ref) {
    return fetchLiveWeather(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FetchLiveWeather value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FetchLiveWeather>(value),
    );
  }
}

String _$fetchLiveWeatherHash() => r'28d7023ef0484d80fefdb2558642cf2213367bc6';

/// Consent state and chosen city, for the UI. Mutations go through the
/// notifier so every screen stays in sync.

@ProviderFor(LiveWeatherState)
final liveWeatherStateProvider = LiveWeatherStateProvider._();

/// Consent state and chosen city, for the UI. Mutations go through the
/// notifier so every screen stays in sync.
final class LiveWeatherStateProvider
    extends
        $AsyncNotifierProvider<LiveWeatherState, ({City? city, bool enabled})> {
  /// Consent state and chosen city, for the UI. Mutations go through the
  /// notifier so every screen stays in sync.
  LiveWeatherStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'liveWeatherStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$liveWeatherStateHash();

  @$internal
  @override
  LiveWeatherState create() => LiveWeatherState();
}

String _$liveWeatherStateHash() => r'3c70b4e751cc44ab3803acf126976fa2dc6c2ad3';

/// Consent state and chosen city, for the UI. Mutations go through the
/// notifier so every screen stays in sync.

abstract class _$LiveWeatherState
    extends $AsyncNotifier<({City? city, bool enabled})> {
  FutureOr<({City? city, bool enabled})> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<({City? city, bool enabled})>,
              ({City? city, bool enabled})
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<({City? city, bool enabled})>,
                ({City? city, bool enabled})
              >,
              AsyncValue<({City? city, bool enabled})>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
