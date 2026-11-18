import 'dart:io';
import 'dart:typed_data';

import 'package:ai_stylist/ai/segmentation/garment_segmenter.dart';
import 'package:ai_stylist/features/official_photo/data/official_photo_settings_store.dart';
import 'package:ai_stylist/features/official_photo/domain/official_photo.dart';
import 'package:ai_stylist/features/official_photo/official_photo_providers.dart';
import 'package:ai_stylist/features/wardrobe/wardrobe_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../support/fakes.dart';
import '../support/test_app.dart';

Uint8List _png(int shade) => img.encodePng(
  img.Image(width: 8, height: 8, numChannels: 4)
    ..clear(img.ColorRgba8(shade, shade, shade, 255)),
);

FoundGarment _garment() => FoundGarment(
  category: GarmentCategory.top,
  areaShare: 0.3,
  cutout: CutoutImages(
    image: _png(120),
    thumbnail: _png(120),
    width: 8,
    height: 8,
  ),
);

/// Scripted web search: no network in tests.
final class _Search implements ProductImageSearch {
  _Search(this.result);

  Result<List<OfficialPhotoCandidate>> result;
  var calls = 0;

  @override
  Future<Result<List<OfficialPhotoCandidate>>> search(Uint8List jpeg) async {
    calls++;
    return result;
  }
}

/// Writes a small real image for each candidate.
final class _Downloader implements CandidateDownloader {
  @override
  Future<Result<DownloadedCandidate>> download(
    OfficialPhotoCandidate c,
    Directory dir,
  ) async {
    await dir.create(recursive: true);
    final file = File('${dir.path}/${c.image.pathSegments.last}');
    await file.writeAsBytes(_png(40));
    return Success(DownloadedCandidate(candidate: c, path: file.path));
  }
}

void main() {
  Future<TestApp> start(
    WidgetTester tester,
    _Search search, {
    bool enabled = true,
    String? key = 'test-key',
  }) async {
    final app = await TestApp.create(
      tester,
      extraOverrides: [
        productImageSearchProvider.overrideWithValue(search),
        candidateDownloaderProvider.overrideWithValue(_Downloader()),
      ],
    );
    await tester.runAsync(() async {
      await app.container
          .read(officialPhotoSettingsProvider)
          .setEnabled(enabled: enabled);
      if (key != null) {
        await app.container
            .read(secretStoreProvider)
            .write(StoredOfficialPhotoSettings.apiKeyName, key);
      }
    });
    late String photo;
    await tester.runAsync(
      () async => photo = await writePhoto(app.tmp, 'shirt.jpg'),
    );
    app.picker.results.add(Success(photo));
    app.garments.result = Success([_garment()]);
    await app.pump(tester);
    await tapAndSettle(tester, find.text('Wardrobe').last);
    await tapAndSettle(tester, find.text('Add'));
    await tapAndSettle(tester, find.text('Choose from photos'));
    await pumpUntil(tester, find.text('Review item'));
    return app;
  }

  Future<ClothingItem> item(WidgetTester tester, TestApp app) async {
    late List<ClothingItem> all;
    await tester.runAsync(() async {
      all = await app.container
          .read(wardrobeRepositoryProvider)
          .watchItems(WardrobeFilter())
          .first;
    });
    return all.single;
  }

  OfficialPhotoCandidate c(String name) => OfficialPhotoCandidate(
    image: Uri.parse('https://shop.example/$name'),
    page: Uri.parse('https://shop.example/kit'),
    match: CandidateMatch.exact,
  );

  testWidgets('after the cut-out, the official photo is found and offered', (
    tester,
  ) async {
    final search = _Search(Success([c('a.png'), c('b.png')]));
    final app = await start(tester, search);

    await pumpUntil(tester, find.text('Official photo found'));
    expect(search.calls, 1);
    expect(find.textContaining('From shop.example'), findsOneWidget);
    // Lens is not offered when the search is automatic.
    expect(find.text('Find official photo'), findsNothing);

    await tapAndSettle(tester, find.text('Use this photo'));
    await pumpUntil(tester, find.text('Official'));
    final images = (await item(tester, app)).images!;
    expect(images.shown, ItemView.product);
    expect(images.cutout, isNotNull);
    expect(find.text('Official photo found'), findsNothing);

    await app.dispose(tester);
  });

  testWidgets('keeping the cut-out hides the suggestion', (tester) async {
    final app = await start(tester, _Search(Success([c('a.png')])));
    await pumpUntil(tester, find.text('Official photo found'));

    await tapAndSettle(tester, find.text('Keep my cut-out'));

    expect(find.text('Official photo found'), findsNothing);
    final images = (await item(tester, app)).images!;
    expect(images.product, isNull);
    expect(images.shown, ItemView.cutout);
    await app.dispose(tester);
  });

  testWidgets('nothing found and errors are explained', (tester) async {
    final search = _Search(const Success([]));
    final app = await start(tester, search);
    await pumpUntil(tester, find.textContaining('No official photo found'));

    search.result = const Failure(NetworkFailure('offline'));
    await tapAndSettle(tester, find.text('Search again'));
    await pumpUntil(tester, find.text('Official photo search failed'));
    expect(find.textContaining("Couldn't reach the internet"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('turned off: nothing is searched', (tester) async {
    final search = _Search(Success([c('a.png')]));
    final app = await start(tester, search, enabled: false);
    await settle(tester);
    expect(search.calls, 0);
    expect(find.text('Official photo found'), findsNothing);
    await app.dispose(tester);
  });

  testWidgets('no key yet: asks for one, searches nothing', (tester) async {
    final search = _Search(Success([c('a.png')]));
    final app = await start(tester, search, key: null);
    await pumpUntil(tester, find.textContaining('Add your Google Cloud API'));
    expect(search.calls, 0);
    await app.dispose(tester);
  });
}
