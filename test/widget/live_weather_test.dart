import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

import '../support/test_app.dart';

String _weather({num temp = 3.6, num code = 63}) => jsonEncode({
  'current': {
    'time': '2026-11-16T10:00',
    'temperature_2m': temp,
    'precipitation': 1.2,
    'weather_code': code,
  },
});

void main() {
  Future<TestApp> openWeather(WidgetTester tester) async {
    final app = await TestApp.create(tester);
    await app.pump(tester);
    await tapAndSettle(tester, find.text('Stylist').last);
    await tapAndSettle(tester, find.text('Include weather'));
    return app;
  }

  Future<void> allowAndChooseTelAviv(WidgetTester tester) async {
    await tapAndSettle(tester, find.text('Use live weather'));
    expect(find.text('Use live weather?'), findsOneWidget);
    expect(find.textContaining('api.open-meteo.com'), findsOneWidget);
    await tapAndSettle(tester, find.text('Allow'));
    await tapAndSettle(tester, find.text('Choose city'));
    await tester.enterText(find.byType(TextField), 'tel');
    await pumpUntil(tester, find.text('Tel Aviv'));
    await tester.tap(find.text('Tel Aviv'));
    await settle(tester);
  }

  testWidgets('manual weather works and nothing is sent without consent', (
    tester,
  ) async {
    final app = await openWeather(tester);
    expect(find.text('Use live weather'), findsOneWidget);
    await tapAndSettle(tester, find.text('Use live weather'));
    await tapAndSettle(tester, find.text('Not now'));

    expect(find.text('Get current weather'), findsNothing);
    expect(find.byType(Slider), findsOneWidget);
    expect(app.network.requests, isEmpty);
    await app.dispose(tester);
  });

  testWidgets('fetches only on tap and fills the editable controls', (
    tester,
  ) async {
    final app = await openWeather(tester);
    app.network.respond = (_) async => http.Response(_weather(), 200);
    await allowAndChooseTelAviv(tester);
    expect(find.text('Tel Aviv, IL'), findsOneWidget);
    expect(app.network.requests, isEmpty, reason: 'no automatic fetch');

    await tapAndSettle(tester, find.text('Get current weather'));

    await pumpUntil(tester, find.textContaining('Open-Meteo.com'));
    expect(app.network.requests, hasLength(1));
    final q = app.network.requests.single.url.queryParameters;
    expect((q['latitude'], q['longitude']), ('32.08', '34.78'));
    expect(find.text('4 °C'), findsOneWidget);
    final rain = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Rain or snow'),
    );
    expect(rain.value, isTrue);

    // Still editable: a manual change replaces the live values.
    await tester.tap(find.widgetWithText(SwitchListTile, 'Rain or snow'));
    await settle(tester);
    expect(find.textContaining('Open-Meteo.com'), findsNothing);
    await app.dispose(tester);
  });

  testWidgets('a network failure keeps manual weather usable', (tester) async {
    final app = await openWeather(tester);
    await allowAndChooseTelAviv(tester);

    await tapAndSettle(tester, find.text('Get current weather'));

    await pumpUntil(tester, find.textContaining("Couldn't get live weather"));
    expect(find.text('18 °C'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('consent can be withdrawn in preferences', (tester) async {
    final app = await openWeather(tester);
    await allowAndChooseTelAviv(tester);

    await tapAndSettle(tester, find.text('Home').last);
    await tapAndSettle(tester, find.byTooltip('Style preferences'));
    await scrollTo(tester, find.text('Allow live weather'));
    expect(find.textContaining('City list by GeoNames'), findsOneWidget);
    await tapAndSettle(tester, find.text('Allow live weather'));

    await tapAndSettle(tester, find.byType(BackButton));
    await tapAndSettle(tester, find.text('Stylist').last);
    expect(find.text('Get current weather'), findsNothing);
    expect(find.text('Use live weather'), findsOneWidget);
    expect(app.network.requests, isEmpty);
    await app.dispose(tester);
  });
}
