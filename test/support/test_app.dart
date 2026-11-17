import 'dart:io';

import 'package:ai_stylist/app/app.dart';
import 'package:ai_stylist/core/database/app_database.dart';
import 'package:ai_stylist/core/providers.dart';
import 'package:ai_stylist/features/clothing_analysis/analysis_providers.dart';
import 'package:ai_stylist/features/profile/profile_providers.dart';
import 'package:ai_stylist/features/stylist/stylist_providers.dart';
import 'package:ai_stylist/features/wardrobe/wardrobe_providers.dart';
import 'package:ai_stylist/features/weather/data/asset_city_directory.dart';
import 'package:ai_stylist/features/weather/weather_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:outfit_engine/outfit_engine.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import 'fakes.dart';

/// A fully wired app over an in-memory database and a temp folder, with a
/// scripted photo picker and image processor.
final class TestApp {
  TestApp._(
    this.tmp,
    this.db,
    this.picker,
    this.processor,
    this.analyzer,
    this.garments,
    this.network,
    this.container,
  );

  final Directory tmp;
  final AppDatabase db;
  final FakeMediaPicker picker;
  final FakeImageProcessor processor;

  /// Scripted on-device analysis (the fake thumbnails are not decodable).
  final FakeClothingAnalyzer analyzer;

  /// Scripted background removal (the real model needs isolates).
  final FakeGarmentFinder garments;

  /// Every HTTP request the app makes. Tests never reach the real network.
  final FakeNetwork network;
  final ProviderContainer container;

  /// Real file I/O never completes on the widget tester's fake clock, so the
  /// temp folder is created inside [WidgetTester.runAsync].
  static Future<TestApp> create(
    WidgetTester tester, {
    bool onboardingComplete = true,
  }) async {
    final tmp = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('ai_stylist_widget'),
    ))!;
    final db = AppDatabase(NativeDatabase.memory());
    final picker = FakeMediaPicker();
    final processor = FakeImageProcessor();
    final analyzer = FakeClothingAnalyzer();
    final garments = FakeGarmentFinder();
    final network = FakeNetwork();
    final container = ProviderContainer(
      overrides: [
        appSupportDirectoryProvider.overrideWithValue(tmp),
        appDatabaseProvider.overrideWithValue(db),
        mediaPickerProvider.overrideWithValue(picker),
        imageProcessorProvider.overrideWithValue(processor),
        clockProvider.overrideWithValue(FixedClock()),
        onboardingCompleteAtLaunchProvider.overrideWithValue(
          onboardingComplete,
        ),
        // Same engine, run inline: isolates do not advance on the fake clock.
        engineRunnerProvider.overrideWithValue(runEngineInline),
        clothingAnalyzerProvider.overrideWithValue(analyzer),
        garmentFinderProvider.overrideWithValue(garments),
        httpClientProvider.overrideWithValue(MockClient(network.handle)),
        // A tiny list instead of the 700 KB bundled asset.
        cityDirectoryProvider.overrideWithValue(
          AssetCityDirectory(() async => testCitiesJson),
        ),
      ],
    );
    return TestApp._(
      tmp,
      db,
      picker,
      processor,
      analyzer,
      garments,
      network,
      container,
    );
  }

  Future<void> pump(WidgetTester tester) async {
    // A typical phone (360 x 800 logical pixels) rather than the 800 x 600
    // default, so layouts are tested at a realistic size.
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AiStylistApp(),
      ),
    );
    await settle(tester);
  }

  /// Adds ACTIVE items (category, colour, name) through the real repository.
  Future<void> seedItems(
    WidgetTester tester,
    List<(GarmentCategory, ColorFamily, String)> items,
  ) async {
    await tester.runAsync(() async {
      final repo = container.read(wardrobeRepositoryProvider);
      for (final (i, (category, color, name)) in items.indexed) {
        final photo = await writePhoto(tmp, '$name.jpg', seed: i + 1);
        final id = (await repo.importImage(photo)).valueOrNull!.id;
        await repo.saveAttributes(
          id,
          ClothingAttributes(
            category: category,
            primaryColor: color,
            displayName: name,
          ),
          activate: true,
        );
      }
    });
  }

  /// Unmounts the app so stream subscriptions close, then frees resources.
  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      container.dispose();
      await db.close();
      // Windows keeps a file locked briefly after an image decode; retry,
      // and leave the OS temp folder to the OS if it is still busy.
      for (var attempt = 0; attempt < 5; attempt++) {
        try {
          await tmp.delete(recursive: true);
          return;
        } on FileSystemException {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      }
    });
  }
}

/// Lets real asynchronous work (file I/O, isolates, SQLite) finish between
/// frames. `pumpAndSettle` alone cannot, because widget tests run on a fake
/// clock and spinners never settle.
Future<void> settle(WidgetTester tester, {int rounds = 8}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Keeps letting real async work run until [finder] matches (for imports,
/// which hash on an isolate and copy files), failing after [timeout].
Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final watch = Stopwatch()..start();
  while (watch.elapsed < timeout) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for $finder');
}

/// Scrolls the nearest vertical list until [finder] is built, taps it and
/// settles. Lazily built lists do not create off-screen chips until scrolled.
Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await scrollTo(tester, finder);
  // Centre it: at the very top edge of a list, under the app bar, a tap can
  // miss the chip.
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pump();
  await tester.tap(finder);
  await settle(tester);
}

/// Scrolls the topmost route's vertical list until [finder] is built.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    // The topmost route's vertical list is the last ListView in the tree.
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
}

/// A few cities in the bundled list's row format.
const testCitiesJson =
    '[[2643743,"London","London","GB",51.51,-0.13,8961989],'
    '[293397,"Tel Aviv","Tel Aviv","IL",32.08,34.78,432892]]';

/// Records requests and answers with [respond]; offline by default.
final class FakeNetwork {
  final requests = <http.Request>[];

  Future<http.Response> Function(http.Request) respond = (_) async =>
      throw http.ClientException('offline (test)');

  Future<http.Response> handle(http.Request request) {
    requests.add(request);
    return respond(request);
  }
}
