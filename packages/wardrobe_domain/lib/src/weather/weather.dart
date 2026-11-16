import 'package:meta/meta.dart';

import '../core/app_failure.dart';
import '../core/result.dart';

/// A city from the bundled offline list. Coordinates are already rounded to
/// two decimals (~1 km), so nothing more precise can ever be sent (D-36).
@immutable
final class City {
  const City({
    required this.id,
    required this.name,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
    this.population = 0,
  });

  /// GeoNames ID.
  final int id;
  final String name;

  /// ISO 3166-1 alpha-2, e.g. `IL`.
  final String countryCode;
  final double latitude;
  final double longitude;
  final int population;

  String get label => '$name, $countryCode';

  @override
  bool operator ==(Object other) => other is City && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Current conditions for a city, as reported by the live provider.
@immutable
final class WeatherReport {
  const WeatherReport({
    required this.city,
    required this.temperatureC,
    required this.precipitationMm,
    required this.weatherCode,
    required this.observedAt,
    required this.provider,
  });

  final City city;
  final double temperatureC;

  /// Precipitation in the preceding interval.
  final double precipitationMm;

  /// WMO weather interpretation code (0 = clear … 99 = thunderstorm).
  final int weatherCode;

  /// UTC time the provider says the values are for.
  final DateTime observedAt;

  /// Human-readable source, shown with the CC BY attribution.
  final String provider;

  /// Rain, drizzle, snow, showers or thunderstorm (WMO codes), or measured
  /// precipitation.
  bool get isWet =>
      precipitationMm >= 0.1 ||
      (weatherCode >= 51 && weatherCode <= 67) ||
      (weatherCode >= 71 && weatherCode <= 77) ||
      (weatherCode >= 80 && weatherCode <= 86) ||
      weatherCode >= 95;
}

/// Offline city search over the bundled list (no network).
abstract interface class CityDirectory {
  /// Best matches for [query], most populous first.
  Future<List<City>> search(String query, {int limit = 20});

  Future<City?> byId(int id);
}

/// Live weather (REQUIREMENTS §6.6). Implementations must only be called
/// after the user enabled live weather and asked for it.
abstract interface class WeatherRepository {
  Future<Result<WeatherReport>> current(City city);
}

/// The user's live-weather consent and chosen city, stored locally.
abstract interface class WeatherSettingsRepository {
  Future<Result<bool>> isLiveWeatherEnabled();

  Future<Result<void>> setLiveWeatherEnabled({required bool enabled});

  Future<Result<int?>> selectedCityId();

  Future<Result<void>> selectCity(int cityId);
}

/// Fetches live weather only with consent. Without it, nothing is sent and
/// the caller falls back to manual weather.
final class FetchLiveWeather {
  const FetchLiveWeather(this._settings, this._weather);

  final WeatherSettingsRepository _settings;
  final WeatherRepository _weather;

  Future<Result<WeatherReport>> call(City city) async {
    final enabled = await _settings.isLiveWeatherEnabled();
    if (enabled.valueOrNull != true) {
      return const Failure(
        PermissionDeniedFailure('Live weather is turned off'),
      );
    }
    return _weather.current(city);
  }
}
