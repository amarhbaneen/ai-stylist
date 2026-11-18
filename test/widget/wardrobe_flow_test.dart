import 'package:ai_stylist/core/media/media_picker.dart';
import 'package:ai_stylist/features/wardrobe/wardrobe_providers.dart';
import 'package:ai_stylist/shared/widgets/chip_selectors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../support/fakes.dart';
import '../support/test_app.dart';

void main() {
  Future<void> openWardrobe(WidgetTester tester) =>
      tapAndSettle(tester, find.text('Wardrobe').last);

  Future<void> pickFromGallery(WidgetTester tester) async {
    await tapAndSettle(tester, find.text('Add'));
    await tapAndSettle(tester, find.text('Choose from photos'));
  }

  Future<List<ClothingItem>> allItems(WidgetTester tester, TestApp app) async {
    late List<ClothingItem> items;
    await tester.runAsync(() async {
      items = await app.container
          .read(wardrobeRepositoryProvider)
          .watchItems(WardrobeFilter(statuses: ItemStatus.values.toSet()))
          .first;
    });
    return items;
  }

  testWidgets('add from gallery, classify manually, item becomes ACTIVE', (
    tester,
  ) async {
    final app = await TestApp.create(tester);
    late String photo;
    await tester.runAsync(
      () async => photo = await writePhoto(app.tmp, 'tee.jpg'),
    );
    app.picker.results.add(Success(photo));
    await app.pump(tester);
    await openWardrobe(tester);

    await pickFromGallery(tester);

    await pumpUntil(tester, find.text('Review item'));
    expect(app.picker.requested, [MediaSourceKind.gallery]);

    // Category is required before the item can join the wardrobe.
    await tapAndSettle(tester, find.text('Add to wardrobe'));
    expect(find.text('Choose a category to add this item.'), findsWidgets);
    expect((await allItems(tester, app)).single.status, ItemStatus.draft);

    // The wardrobe's category bar (underneath) also has a "Top" chip.
    await tapAndSettle(tester, find.text('Top').last);
    await tapAndSettle(tester, find.text('T-shirt'));
    await tester.enterText(find.byType(TextField).first, 'Navy tee');
    // "Navy" is offered as both the main and a secondary colour.
    await tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(SingleChipSelector<ColorFamily>),
        matching: find.text('Navy'),
      ),
    );
    await tapAndSettle(tester, find.text('Add to wardrobe'));

    // Lands on the details screen.
    await pumpUntil(tester, find.byTooltip('Edit'));
    expect(find.text('Navy tee'), findsWidgets);
    final item = (await allItems(tester, app)).single;
    expect(item.status, ItemStatus.active);
    expect(item.attributes.category, GarmentCategory.top);
    expect(item.attributes.subcategory, GarmentSubcategory.tShirt);
    expect(item.attributes.primaryColor, ColorFamily.navy);
    await app.dispose(tester);
  });

  testWidgets('cancelling the picker changes nothing', (tester) async {
    final app = await TestApp.create(tester);
    await app.pump(tester);
    await openWardrobe(tester);

    await pickFromGallery(tester); // FakeMediaPicker cancels by default

    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Your wardrobe is empty'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('permission denial is explained, manual flow still available', (
    tester,
  ) async {
    final app = await TestApp.create(tester);
    app.picker.results.add(
      const Failure(PermissionDeniedFailure('camera_access_denied')),
    );
    await app.pump(tester);
    await openWardrobe(tester);

    await tapAndSettle(tester, find.text('Add'));
    await tapAndSettle(tester, find.text('Take a photo'));

    expect(find.textContaining('Access was turned off'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    expect(await allItems(tester, app), isEmpty);
    await app.dispose(tester);
  });

  testWidgets('an unreadable image shows an error and saves nothing', (
    tester,
  ) async {
    final app = await TestApp.create(tester);
    app.processor.fail = true;
    late String photo;
    await tester.runAsync(
      () async => photo = await writePhoto(app.tmp, 'x.jpg'),
    );
    app.picker.results.add(Success(photo));
    await app.pump(tester);
    await openWardrobe(tester);

    await pickFromGallery(tester);
    await pumpUntil(tester, find.textContaining("couldn't be opened"));
    expect(await allItems(tester, app), isEmpty);
    await app.dispose(tester);
  });

  testWidgets('a duplicate photo offers to open the existing item', (
    tester,
  ) async {
    final app = await TestApp.create(tester);
    late String photo;
    await tester.runAsync(
      () async => photo = await writePhoto(app.tmp, 'a.jpg'),
    );
    app.picker.results
      ..add(Success(photo))
      ..add(Success(photo));
    await app.pump(tester);
    await openWardrobe(tester);

    await pickFromGallery(tester);
    await pumpUntil(tester, find.text('Review item'));
    await tapAndSettle(tester, find.byTooltip('Back'));
    await pickFromGallery(tester);
    await pumpUntil(tester, find.text('Open'));

    expect(
      find.text('This photo is already in your wardrobe.'),
      findsOneWidget,
    );
    expect(find.text('Open'), findsOneWidget);
    expect(await allItems(tester, app), hasLength(1));
    await app.dispose(tester);
  });

  group('existing item', () {
    Future<(TestApp, String)> seeded(WidgetTester tester) async {
      final app = await TestApp.create(tester);
      late String id;
      await tester.runAsync(() async {
        final repo = app.container.read(wardrobeRepositoryProvider);
        final photo = await writePhoto(app.tmp, 'jeans.jpg');
        id = (await repo.importImage(photo)).valueOrNull!.id;
        await repo.saveAttributes(
          id,
          ClothingAttributes(
            category: GarmentCategory.bottom,
            subcategory: GarmentSubcategory.jeans,
            displayName: 'Blue jeans',
          ),
          activate: true,
        );
      });
      await app.pump(tester);
      await openWardrobe(tester);
      return (app, id);
    }

    testWidgets('appears in the grid and can be edited', (tester) async {
      final (app, _) = await seeded(tester);
      expect(find.text('Blue jeans'), findsOneWidget);

      await tapAndSettle(tester, find.text('Blue jeans'));
      await tapAndSettle(tester, find.byTooltip('Edit'));
      expect(find.text('Edit item'), findsOneWidget);
      await tapAndSettle(tester, find.text('Winter'));
      await tapAndSettle(tester, find.text('Save changes'));

      final item = (await allItems(tester, app)).single;
      expect(item.attributes.seasons, {Season.winter});
      expect(item.attributes.displayName, 'Blue jeans');
      await app.dispose(tester);
    });

    testWidgets('archiving hides it from the default view', (tester) async {
      final (app, _) = await seeded(tester);

      await tapAndSettle(tester, find.text('Blue jeans'));
      await tapAndSettle(tester, find.byIcon(Icons.more_vert));
      await tapAndSettle(tester, find.text('Archive'));
      expect((await allItems(tester, app)).single.status, ItemStatus.archived);
      await tapAndSettle(tester, find.byTooltip('Back'));

      await pumpUntil(tester, find.text('Your wardrobe is empty'));
      await settle(tester); // let the details page finish closing
      expect(find.text('Blue jeans'), findsNothing);
      await app.dispose(tester);
    });

    testWidgets('deleting asks for confirmation, then removes it', (
      tester,
    ) async {
      final (app, _) = await seeded(tester);

      await tapAndSettle(tester, find.text('Blue jeans'));
      await tapAndSettle(tester, find.byIcon(Icons.more_vert));
      await tapAndSettle(tester, find.text('Delete'));
      expect(find.text('Delete this item?'), findsOneWidget);

      await tapAndSettle(tester, find.text('Cancel'));
      expect(await allItems(tester, app), hasLength(1));

      await tapAndSettle(tester, find.byIcon(Icons.more_vert));
      await tapAndSettle(tester, find.text('Delete'));
      await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Delete'));

      expect(await allItems(tester, app), isEmpty);
      await pumpUntil(tester, find.text('Your wardrobe is empty'));
      await app.dispose(tester);
    });

    testWidgets('search filters by name', (tester) async {
      final (app, _) = await seeded(tester);

      await tapAndSettle(tester, find.byTooltip('Search'));
      await tester.enterText(find.byType(TextField), 'linen');
      await settle(tester);
      expect(find.text('No matching items'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'JEANS');
      await settle(tester);
      expect(find.text('Blue jeans'), findsOneWidget);
      await app.dispose(tester);
    });
  });
}
