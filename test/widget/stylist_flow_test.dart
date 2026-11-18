import 'package:ai_stylist/features/wardrobe/wardrobe_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../support/fakes.dart';
import '../support/test_app.dart';

void main() {
  /// Adds ACTIVE items (category, colour, name) through the real repository.
  Future<void> seed(
    WidgetTester tester,
    TestApp app,
    List<(GarmentCategory, ColorFamily, String)> items,
  ) async {
    await tester.runAsync(() async {
      final repo = app.container.read(wardrobeRepositoryProvider);
      for (final (i, (category, color, name)) in items.indexed) {
        final photo = await writePhoto(app.tmp, '$name.jpg', seed: i + 1);
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

  Future<void> openStylist(WidgetTester tester) =>
      tapAndSettle(tester, find.text('Stylist').last);

  Future<void> suggest(WidgetTester tester) =>
      tapAndSettle(tester, find.text('Suggest outfits'));

  testWidgets('an empty wardrobe explains that clothes are needed', (
    tester,
  ) async {
    final app = await TestApp.create(tester);
    await app.pump(tester);
    await openStylist(tester);

    await suggest(tester);

    await pumpUntil(tester, find.text('Your wardrobe is empty'));
    expect(find.text('Go to Wardrobe'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('suggests an outfit and opens its explanation', (tester) async {
    final app = await TestApp.create(tester);
    await seed(tester, app, [
      (GarmentCategory.top, ColorFamily.white, 'White tee'),
      (GarmentCategory.bottom, ColorFamily.navy, 'Navy chinos'),
      (GarmentCategory.footwear, ColorFamily.white, 'White sneakers'),
    ]);
    await app.pump(tester);
    await openStylist(tester);

    await suggest(tester);

    await pumpUntil(tester, find.text('Idea 1'));
    expect(find.textContaining('Only 1 complete outfit'), findsOneWidget);
    expect(find.text('Built on a neutral base'), findsOneWidget);

    await tapAndSettle(tester, find.text('Idea 1'));
    await pumpUntil(tester, find.text('Score breakdown'));
    await settle(tester); // let the page transition finish
    expect(find.text('White tee'), findsOneWidget);
    expect(find.text('Navy chinos'), findsOneWidget);
    expect(find.text('White sneakers'), findsOneWidget);
    await scrollTo(tester, find.textContaining('Weather was not included'));
    expect(find.textContaining('Weather was not included'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('a missing category is explained, nothing is invented', (
    tester,
  ) async {
    final app = await TestApp.create(tester);
    await seed(tester, app, [
      (GarmentCategory.top, ColorFamily.white, 'White tee'),
      (GarmentCategory.bottom, ColorFamily.navy, 'Navy chinos'),
    ]);
    await app.pump(tester);
    await openStylist(tester);

    await suggest(tester);

    await pumpUntil(tester, find.text('No complete outfit yet'));
    expect(find.textContaining('Add shoes'), findsOneWidget);
    expect(find.text('Idea 1'), findsNothing);
    await app.dispose(tester);
  });

  testWidgets('cold weather asks for a layer', (tester) async {
    final app = await TestApp.create(tester);
    await seed(tester, app, [
      (GarmentCategory.top, ColorFamily.white, 'White tee'),
      (GarmentCategory.bottom, ColorFamily.navy, 'Navy chinos'),
      (GarmentCategory.footwear, ColorFamily.white, 'White sneakers'),
    ]);
    await app.pump(tester);
    await openStylist(tester);

    await tapAndSettle(tester, find.text('Include weather'));
    // Drag the temperature slider to the far left (-10 °C).
    await tester.drag(find.byType(Slider), const Offset(-600, 0));
    await settle(tester);
    expect(find.text('-10 °C'), findsOneWidget);
    await suggest(tester);

    await pumpUntil(tester, find.text('No complete outfit yet'));
    expect(find.textContaining('Add a jacket or coat'), findsOneWidget);
    await app.dispose(tester);
  });
}
