import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:wardrobe_domain/wardrobe_domain.dart';

/// Live weather from Open-Meteo (https://open-meteo.com), chosen by the
/// product owner (DECISIONS D-35).
///
/// Exactly one request per explicit "Get current weather" tap (cached for
/// [cacheFor]), sending only:
/// - the city's latitude/longitude, already rounded to 2 decimals;
/// - the fixed list of variables below; `timezone=UTC`;
/// - a generic User-Agent naming the app (no device, user or account data).
/// No cookies, no API key, no wardrobe data. See docs/NETWORK.md.
///
/// Data licence: CC BY 4.0 (attribution shown in the app). Terms: free for
/// non-commercial use only.
final class OpenMeteoWeatherRepository implements WeatherRepository {
  OpenMeteoWeatherRepository({
    required this._client,
    required this._clock,
    this.timeout = const Duration(seconds: 10),
    this.cacheFor = const Duration(minutes: 15),
  });

  final http.Client _client;
  final Clock _clock;
  final Duration timeout;

  /// Open-Meteo's "current" values update every 15 minutes.
  final Duration cacheFor;

  static const provider = 'Open-Meteo';
  static const userAgent = 'AIStylist/0.1 (Flutter app)';
  static const host = 'api.open-meteo.com';

  final _cache = <int, (DateTime, WeatherReport)>{};

  /// The exact request URL for [city] (also used by tests and the docs).
  static Uri requestUri(City city) => Uri.https(host, '/v1/forecast', {
    'latitude': city.latitude.toStringAsFixed(2),
    'longitude': city.longitude.toStringAsFixed(2),
    'current': 'temperature_2m,precipitation,weather_code',
    'timezone': 'UTC',
  });

  @override
  Future<Result<WeatherReport>> current(City city) async {
    final now = _clock.nowUtc();
    final cached = _cache[city.id];
    if (cached != null && now.difference(cached.$1) < cacheFor) {
      return Success(cached.$2);
    }
    final http.Response response;
    try {
      response = await _client
          .get(requestUri(city), headers: {'User-Agent': userAgent})
          .timeout(timeout);
    } on TimeoutException catch (e) {
      return Failure(NetworkFailure('Weather request timed out', cause: e));
    } on SocketException catch (e) {
      return Failure(NetworkFailure('No connection', cause: e));
    } on http.ClientException catch (e) {
      return Failure(NetworkFailure('Weather request failed', cause: e));
    }
    if (response.statusCode != 200) {
      return Failure(
        NetworkFailure('Weather service returned ${response.statusCode}'),
      );
    }
    final report = _parse(response.body, city);
    if (report == null) {
      return const Failure(NetworkFailure('Unexpected weather response'));
    }
    _cache[city.id] = (now, report);
    return Success(report);
  }

  /// Strictly validates the response; anything odd is rejected rather than
  /// shown as weather.
  static WeatherReport? _parse(String body, City city) {
    final Object? json;
    try {
      json = jsonDecode(body);
    } on FormatException {
      return null;
    }
    if (json is! Map<String, Object?>) return null;
    final current = json['current'];
    if (current is! Map<String, Object?>) return null;
    final temp = current['temperature_2m'];
    final precip = current['precipitation'];
    final code = current['weather_code'];
    final time = current['time'];
    if (temp is! num || precip is! num || code is! num || time is! String) {
      return null;
    }
    if (temp < -90 || temp > 60 || precip < 0 || code < 0 || code > 99) {
      return null;
    }
    final observed = DateTime.tryParse('${time}Z');
    if (observed == null) return null;
    return WeatherReport(
      city: city,
      temperatureC: temp.toDouble(),
      precipitationMm: precip.toDouble(),
      weatherCode: code.toInt(),
      observedAt: observed,
      provider: provider,
    );
  }
}
