import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ai_stylist/core/database/app_database.dart';
import 'package:ai_stylist/features/weather/data/asset_city_directory.dart';
import 'package:ai_stylist/features/weather/data/drift_weather_settings_repository.dart';
import 'package:ai_stylist/features/weather/data/open_meteo_weather_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../support/fakes.dart';

const _telAviv = City(
  id: 293397,
  name: 'Tel Aviv',
  countryCode: 'IL',
  latitude: 32.08,
  longitude: 34.78,
);

String _body({
  num temp = 21.4,
  num precip = 0,
  num code = 1,
  String time = '2026-11-16T10:15',
}) => jsonEncode({
  'latitude': 32.08,
  'longitude': 34.78,
  'current': {
    'time': time,
    'temperature_2m': temp,
    'precipitation': precip,
    'weather_code': code,
  },
});

void main() {
  group('OpenMeteoWeatherRepository', () {
    late List<http.Request> requests;
    late FixedClock clock;

    OpenMeteoWeatherRepository repo(
      Future<http.Response> Function(http.Request) handler,
    ) {
      requests = [];
      clock = FixedClock();
      return OpenMeteoWeatherRepository(
        client: MockClient((r) {
          requests.add(r);
          return handler(r);
        }),
        clock: clock,
        timeout: const Duration(milliseconds: 200),
      );
    }

    test('sends only rounded coordinates and fixed fields', () async {
      final r = repo((_) async => http.Response(_body(), 200));
      await r.current(_telAviv);

      final req = requests.single;
      expect(req.method, 'GET');
      expect(req.url.scheme, 'https');
      expect(req.url.host, 'api.open-meteo.com');
      expect(req.url.path, '/v1/forecast');
      expect(req.url.queryParameters, {
        'latitude': '32.08',
        'longitude': '34.78',
        'current': 'temperature_2m,precipitation,weather_code',
        'timezone': 'UTC',
      });
      expect(req.headers['User-Agent'], OpenMeteoWeatherRepository.userAgent);
      expect(
        req.headers.keys.map((k) => k.toLowerCase()),
        isNot(contains('cookie')),
      );
      expect(req.body, isEmpty);
    });

    test('coordinates are never sent with more than 2 decimals', () {
      const precise = City(
        id: 1,
        name: 'X',
        countryCode: 'XX',
        latitude: 32.0853219,
        longitude: 34.7817676,
      );
      final q = OpenMeteoWeatherRepository.requestUri(precise).queryParameters;
      expect(q['latitude'], '32.09');
      expect(q['longitude'], '34.78');
    });

    test('parses current conditions', () async {
      final r = repo((_) async => http.Response(_body(), 200));
      final report = (await r.current(_telAviv)).valueOrNull!;
      expect(report.temperatureC, 21.4);
      expect(report.isWet, isFalse);
      expect(report.observedAt, DateTime.utc(2026, 11, 16, 10, 15));
      expect(report.provider, 'Open-Meteo');
    });

    test('rain is detected from code or measured precipitation', () async {
      final drizzle = repo((_) async => http.Response(_body(code: 61), 200));
      expect((await drizzle.current(_telAviv)).valueOrNull!.isWet, isTrue);
      final wet = repo((_) async => http.Response(_body(precip: 0.4), 200));
      expect((await wet.current(_telAviv)).valueOrNull!.isWet, isTrue);
    });

    test('errors become NetworkFailure, never exceptions', () async {
      final cases = <Future<http.Response> Function(http.Request)>[
        (_) async => http.Response('oops', 500),
        (_) async => http.Response('{not json', 200),
        (_) async =>
            http.Response(jsonEncode({'current': <String, Object?>{}}), 200),
        (_) async => http.Response(_body(temp: 400), 200),
        (_) async => http.Response(_body(code: 150), 200),
        (_) async => throw const SocketException('offline'),
        (_) async => throw http.ClientException('reset'),
        (_) => Completer<http.Response>().future, // never answers → timeout
      ];
      for (final handler in cases) {
        final result = await repo(handler).current(_telAviv);
        expect((result as Failure).failure, isA<NetworkFailure>());
      }
    });

    test('repeat requests within 15 minutes are served from cache', () async {
      final r = repo((_) async => http.Response(_body(), 200));
      await r.current(_telAviv);
      clock.now = clock.now.add(const Duration(minutes: 10));
      await r.current(_telAviv);
      expect(requests, hasLength(1));
      clock.now = clock.now.add(const Duration(minutes: 6));
      await r.current(_telAviv);
      expect(requests, hasLength(2));
    });
  });

  group('consent', () {
    late AppDatabase db;
    late DriftWeatherSettingsRepository settings;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      settings = DriftWeatherSettingsRepository(db);
    });
    tearDown(() => db.close());

    test('live weather is off by default and nothing is sent', () async {
      var sent = 0;
      final weather = OpenMeteoWeatherRepository(
        client: MockClient((_) async {
          sent++;
          return http.Response(_body(), 200);
        }),
        clock: FixedClock(),
      );
      expect((await settings.isLiveWeatherEnabled()).valueOrNull, isFalse);

      final result = await FetchLiveWeather(settings, weather)(_telAviv);

      expect((result as Failure).failure, isA<PermissionDeniedFailure>());
      expect(sent, 0);

      await settings.setLiveWeatherEnabled(enabled: true);
      expect(
        (await FetchLiveWeather(settings, weather)(_telAviv)).isSuccess,
        isTrue,
      );
      expect(sent, 1);
    });

    test('remembers the chosen city', () async {
      expect((await settings.selectedCityId()).valueOrNull, isNull);
      await settings.selectCity(293397);
      expect((await settings.selectedCityId()).valueOrNull, 293397);
    });
  });

  group('AssetCityDirectory (real bundled list)', () {
    final directory = AssetCityDirectory(
      () => File('assets/cities/cities.json').readAsString(),
    );

    test('finds cities by prefix, most populous first', () async {
      final london = await directory.search('london');
      expect(london.first.label, 'London, GB');
      expect(london.map((c) => c.countryCode), contains('CA'));
    });

    test('ignores accents and case', () async {
      final zurich = await directory.search('ZURICH');
      expect(zurich.first.name, 'Zürich');
      expect(zurich.first.countryCode, 'CH');
    });

    test(
      'coordinates in the asset are already rounded to 2 decimals',
      () async {
        final cities = await directory.search('a', limit: 200);
        for (final c in cities) {
          expect((c.latitude * 100).roundToDouble() / 100, c.latitude);
          expect((c.longitude * 100).roundToDouble() / 100, c.longitude);
        }
      },
    );

    test('empty query and lookup by id', () async {
      expect(await directory.search('   '), isEmpty);
      final tlv = (await directory.search('tel aviv')).first;
      expect((await directory.byId(tlv.id))!.name, 'Tel Aviv');
      expect(await directory.byId(-1), isNull);
    });
  });
}
