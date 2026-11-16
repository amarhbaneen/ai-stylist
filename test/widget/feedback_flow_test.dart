import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../support/test_app.dart';

void main() {
  const wardrobe = [
    (GarmentCategory.top, ColorFamily.white, 'White tee'),
    (GarmentCategory.bottom, ColorFamily.navy, 'Navy chinos'),
    (GarmentCategory.footwear, ColorFamily.white, 'White sneakers'),
  ];

  Future<TestApp> withOutfit(WidgetTester tester) async {
    final app = await TestApp.create(tester);
    await app.seedItems(tester, wardrobe);
    await app.pump(tester);
    await tapAndSettle(tester, find.text('Stylist').last);
    await tapAndSettle(tester, find.text('Suggest outfits'));
    await pumpUntil(tester, find.byTooltip('Like'));
    return app;
  }

  testWidgets('like, then undo, from the outfit card', (tester) async {
    final app = await withOutfit(tester);

    await tapAndSettle(tester, find.byTooltip('Like'));
    await pumpUntil(tester, find.byTooltip('Remove like'));
    expect(find.textContaining('Future ideas will lean this way'), findsOne);

    await tapAndSettle(tester, find.byTooltip('Remove like'));
    await pumpUntil(tester, find.byTooltip('Like'));
    expect(find.text('Rating removed.'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('dislike asks for an optional reason', (tester) async {
    final app = await withOutfit(tester);

    await tapAndSettle(tester, find.byTooltip('Dislike'));
    expect(find.text('What didn\'t work? (optional)'), findsOneWidget);
    await tapAndSettle(tester, find.text('Wore it recently'));
    await tapAndSettle(tester, find.text('Save'));

    await pumpUntil(tester, find.byTooltip('Remove dislike'));
    expect(find.textContaining('won\'t change your style profile'), findsOne);
    await app.dispose(tester);
  });

  testWidgets('dismissing the reason sheet records nothing', (tester) async {
    final app = await withOutfit(tester);

    await tapAndSettle(tester, find.byTooltip('Dislike'));
    await tester.tapAt(const Offset(10, 10)); // outside the sheet
    await settle(tester);

    expect(find.byTooltip('Dislike'), findsOneWidget);
    expect(find.byTooltip('Remove dislike'), findsNothing);
    await app.dispose(tester);
  });

  testWidgets('saved outfits appear under Favorites; all under History', (
    tester,
  ) async {
    final app = await withOutfit(tester);

    await tapAndSettle(tester, find.byTooltip('Save to Favorites'));
    await pumpUntil(tester, find.byTooltip('Remove from Favorites'));

    await tapAndSettle(tester, find.text('Favorites').last);
    await pumpUntil(tester, find.textContaining('Casual ·'));
    expect(find.text('No favorites yet'), findsNothing);

    await tapAndSettle(tester, find.text('History'));
    await pumpUntil(tester, find.textContaining('Casual ·'));

    // Un-saving from the Saved view empties it.
    await tapAndSettle(tester, find.text('Saved'));
    await pumpUntil(tester, find.byTooltip('Remove from Favorites'));
    await tapAndSettle(tester, find.byTooltip('Remove from Favorites'));
    await pumpUntil(tester, find.text('No favorites yet'));
    await app.dispose(tester);
  });

  testWidgets('learning shows in preferences and can be reset', (tester) async {
    final app = await withOutfit(tester);
    await tapAndSettle(tester, find.byTooltip('Like'));
    await pumpUntil(tester, find.byTooltip('Remove like'));

    await tapAndSettle(tester, find.text('Home').last);
    await tapAndSettle(tester, find.byTooltip('Style preferences'));
    await pumpUntil(tester, find.text('Styles you like'));
    await scrollTo(tester, find.text('You tend to like'));
    expect(find.text('Learned from your feedback'), findsOneWidget);

    await tapAndSettle(tester, find.text('Reset learning'));
    expect(find.text('Reset what was learned?'), findsOneWidget);
    await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Reset'));

    await pumpUntil(tester, find.textContaining('Nothing learned yet'));
    expect(find.text('You tend to like'), findsNothing);
    await app.dispose(tester);
  });
}
