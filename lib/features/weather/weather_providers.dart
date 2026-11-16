import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../core/providers.dart';
import 'data/asset_city_directory.dart';
import 'data/drift_weather_settings_repository.dart';
import 'data/open_meteo_weather_repository.dart';

part 'weather_providers.g.dart';

/// The app's only HTTP client. Overridden in tests (no real network).
@Riverpod(keepAlive: true)
http.Client httpClient(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
}

@Riverpod(keepAlive: true)
CityDirectory cityDirectory(Ref ref) =>
    AssetCityDirectory(() => rootBundle.loadString(AssetCityDirectory.asset));

@Riverpod(keepAlive: true)
WeatherRepository weatherRepository(Ref ref) => OpenMeteoWeatherRepository(
  client: ref.watch(httpClientProvider),
  clock: ref.watch(clockProvider),
);

@Riverpod(keepAlive: true)
WeatherSettingsRepository weatherSettings(Ref ref) =>
    DriftWeatherSettingsRepository(ref.watch(appDatabaseProvider));

@riverpod
FetchLiveWeather fetchLiveWeather(Ref ref) => FetchLiveWeather(
  ref.watch(weatherSettingsProvider),
  ref.watch(weatherRepositoryProvider),
);

/// Consent state and chosen city, for the UI. Mutations go through the
/// notifier so every screen stays in sync.
@riverpod
class LiveWeatherState extends _$LiveWeatherState {
  @override
  Future<({bool enabled, City? city})> build() async {
    final settings = ref.watch(weatherSettingsProvider);
    final enabled = (await settings.isLiveWeatherEnabled()).valueOrNull;
    final id = (await settings.selectedCityId()).valueOrNull;
    final city = id == null
        ? null
        : await ref.watch(cityDirectoryProvider).byId(id);
    return (enabled: enabled ?? false, city: city);
  }

  Future<void> setEnabled({required bool enabled}) async {
    await ref
        .read(weatherSettingsProvider)
        .setLiveWeatherEnabled(enabled: enabled);
    ref.invalidateSelf();
  }

  Future<void> selectCity(City city) async {
    await ref.read(weatherSettingsProvider).selectCity(city.id);
    ref.invalidateSelf();
  }
}
