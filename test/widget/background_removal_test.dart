import 'dart:typed_data';

import 'package:ai_stylist/ai/segmentation/garment_segmenter.dart';
import 'package:ai_stylist/core/media/media_picker.dart';
import 'package:ai_stylist/features/wardrobe/wardrobe_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../support/fakes.dart';
import '../support/test_app.dart';

FoundGarment _garment(GarmentCategory category, double share, int shade) {
  final png = img.encodePng(
    img.Image(width: 4, height: 4, numChannels: 4)
      ..clear(img.ColorRgba8(shade, shade, shade, 255)),
  );
  return FoundGarment(
    category: category,
    areaShare: share,
    cutout: CutoutImages(
      image: png,
      thumbnail: Uint8List.fromList(png),
      width: 4,
      height: 4,
    ),
  );
}

void main() {
  Future<TestApp> start(
    WidgetTester tester,
    Result<List<FoundGarment>> found,
  ) async {
    final app = await TestApp.create(tester);
    late String photo;
    await tester.runAsync(
      () async => photo = await writePhoto(app.tmp, 'outfit.jpg'),
    );
    app.picker.results.add(Success(photo));
    app.garments.result = found;
    await app.pump(tester);
    await tapAndSettle(tester, find.text('Wardrobe').last);
    await tapAndSettle(tester, find.text('Add'));
    await tapAndSettle(tester, find.text('Choose from photos'));
    return app;
  }

  Future<List<ClothingItem>> items(WidgetTester tester, TestApp app) async {
    late List<ClothingItem> all;
    await tester.runAsync(() async {
      all = await app.container
          .read(wardrobeRepositoryProvider)
          .watchItems(WardrobeFilter())
          .first;
    });
    return all;
  }

  testWidgets('one garment is cut out directly and can be switched back', (
    tester,
  ) async {
    final app = await start(
      tester,
      Success([_garment(GarmentCategory.top, 0.3, 120)]),
    );

    await pumpUntil(tester, find.text('Review item'));
    expect(find.text('Choose items'), findsNothing);
    expect(app.garments.paths.single, endsWith('.jpg'));
    var item = (await items(tester, app)).single;
    expect(item.images!.shown, ItemView.cutout);
    expect(find.text('Cut-out'), findsOneWidget);

    await tapAndSettle(tester, find.text('Original'));
    item = (await items(tester, app)).single;
    expect(item.images!.shown, ItemView.photo);
    expect(item.images!.cutout, isNotNull);

    await app.dispose(tester);
  });

  testWidgets('several garments: the chosen ones become items', (tester) async {
    final app = await start(
      tester,
      Success([
        _garment(GarmentCategory.onePiece, 0.4, 50),
        _garment(GarmentCategory.footwear, 0.05, 90),
        _garment(GarmentCategory.accessory, 0.02, 200),
      ]),
    );

    await pumpUntil(tester, find.text('Choose items'));
    // Small finds start unticked.
    expect(find.text('Add 2 items'), findsOneWidget);
    await tapAndSettle(tester, find.text('Accessory'));
    expect(find.text('Add 3 items'), findsOneWidget);
    await tapAndSettle(tester, find.text('Footwear'));
    await tapAndSettle(tester, find.text('Add 2 items'));

    await pumpUntil(tester, find.text('Review item'));
    expect(find.textContaining('1 more item from this photo'), findsOneWidget);
    final all = await items(tester, app);
    expect(all, hasLength(2));
    expect(all.every((i) => i.status == ItemStatus.draft), isTrue);
    expect(all.every((i) => i.images!.shown == ItemView.cutout), isTrue);
    // Each item has its own copy of the photo and its own cut-out.
    expect(all.map((i) => i.images!.original).toSet(), hasLength(2));
    expect(all.map((i) => i.images!.cutout!.image).toSet(), hasLength(2));

    await app.dispose(tester);
  });

  testWidgets('keeping the whole photo makes one item without a cut-out', (
    tester,
  ) async {
    final app = await start(
      tester,
      Success([
        _garment(GarmentCategory.top, 0.3, 50),
        _garment(GarmentCategory.bottom, 0.2, 90),
      ]),
    );

    await pumpUntil(tester, find.text('Choose items'));
    await tapAndSettle(tester, find.text('Keep the whole photo as one item'));

    await pumpUntil(tester, find.text('Review item'));
    final item = (await items(tester, app)).single;
    expect(item.images!.cutout, isNull);
    expect(find.text('Cut-out'), findsNothing);

    await app.dispose(tester);
  });

  testWidgets('if background removal fails, the photo is added as is', (
    tester,
  ) async {
    final app = await start(
      tester,
      const Failure(ModelUnavailableFailure('no model')),
    );

    await pumpUntil(tester, find.text('Review item'));
    final item = (await items(tester, app)).single;
    expect(item.images!.cutout, isNull);

    await app.dispose(tester);
  });

  testWidgets('flip mirrors the cut-out', (tester) async {
    final app = await start(
      tester,
      Success([_garment(GarmentCategory.top, 0.3, 120)]),
    );
    await pumpUntil(tester, find.text('Review item'));
    final before = (await items(tester, app)).single.images!.cutout!.image;

    await tapAndSettle(tester, find.text('Flip'));
    // Flipping decodes the PNGs on an isolate, which runs on real time.
    var after = (await items(tester, app)).single.images!;
    for (var i = 0; i < 100 && after.cutout!.image == before; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      after = (await items(tester, app)).single.images!;
    }
    expect(after.cutout!.image, isNot(before));
    expect(after.shown, ItemView.cutout);

    await app.dispose(tester);
  });

  testWidgets('find official photo hands the cut-out to a search app', (
    tester,
  ) async {
    final app = await start(
      tester,
      Success([_garment(GarmentCategory.top, 0.3, 120)]),
    );
    await pumpUntil(tester, find.text('Review item'));

    await tapAndSettle(tester, find.text('Find official photo'));

    final cutout = (await items(tester, app)).single.images!.cutout!.image;
    expect(app.search.paths.single, endsWith(cutout.split('/').last));
    expect(find.textContaining('Use official photo'), findsWidgets);

    await app.dispose(tester);
  });

  testWidgets('use official photo stores it and offers the switch', (
    tester,
  ) async {
    final app = await start(
      tester,
      Success([_garment(GarmentCategory.top, 0.3, 120)]),
    );
    await pumpUntil(tester, find.text('Review item'));
    late String official;
    await tester.runAsync(
      () async => official = await writePhoto(app.tmp, 'official.jpg'),
    );
    app.picker.results.add(Success(official));

    await tapAndSettle(tester, find.text('Use official photo'));
    await pumpUntil(tester, find.text('Official'));

    var images = (await items(tester, app)).single.images!;
    expect(images.shown, ItemView.product);
    expect(images.product, isNotNull);
    expect(app.picker.requested.last, MediaSourceKind.gallery);

    await tapAndSettle(tester, find.text('Original'));
    images = (await items(tester, app)).single.images!;
    expect(images.shown, ItemView.photo);

    await tapAndSettle(tester, find.text('Remove official photo'));
    await pumpUntil(tester, find.text('Use official photo'));
    images = (await items(tester, app)).single.images!;
    expect(images.product, isNull);

    await app.dispose(tester);
  });

  testWidgets('cancelling the gallery changes nothing', (tester) async {
    final app = await start(
      tester,
      Success([_garment(GarmentCategory.top, 0.3, 120)]),
    );
    await pumpUntil(tester, find.text('Review item'));
    app.picker.results.add(const Failure(CancelledFailure()));

    await tapAndSettle(tester, find.text('Use official photo'));

    expect((await items(tester, app)).single.images!.product, isNull);
    expect(find.byType(SnackBar), findsNothing);

    await app.dispose(tester);
  });
}
