import 'package:ai_stylist/core/media/media_picker.dart';
import 'package:ai_stylist/features/wardrobe/wardrobe_providers.dart';
import 'package:ai_stylist/shared/widgets/chip_selectors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../support/fakes.dart';
import '../support/test_app.dart';

const _src = AnalysisSource(modelId: 'color-tier0', modelVersion: '1.0.0');
final _at = DateTime.utc(2026, 11, 16);

ClothingAnalysis _analysis(
  ColorFamily primary,
  double confidence, {
  List<(ColorFamily, double)> alternatives = const [],
  List<ColorFamily> secondary = const [],
}) => ClothingAnalysis(
  primaryColor: Suggestion(
    value: primary,
    confidence: confidence,
    source: _src,
    analyzedAt: _at,
    alternatives: alternatives,
  ),
  secondaryColors: [
    for (final c in secondary)
      Suggestion(value: c, confidence: 0.3, source: _src, analyzedAt: _at),
  ],
);

void main() {
  /// Imports a photo through the real flow and waits for the review form.
  Future<TestApp> review(
    WidgetTester tester,
    Result<ClothingAnalysis> analysis,
  ) async {
    final app = await TestApp.create(tester);
    app.analyzer.result = analysis;
    late String photo;
    await tester.runAsync(
      () async => photo = await writePhoto(app.tmp, 'tee.jpg'),
    );
    app.picker.results.add(Success(photo));
    await app.pump(tester);
    await tapAndSettle(tester, find.text('Wardrobe').last);
    await tapAndSettle(tester, find.text('Add'));
    await tapAndSettle(tester, find.text('Choose from photos'));
    await pumpUntil(tester, find.text('Review item'));
    expect(app.picker.requested, [MediaSourceKind.gallery]);
    return app;
  }

  Finder mainColourChip(String label) => find.descendant(
    of: find.byType(SingleChipSelector<ColorFamily>),
    matching: find.widgetWithText(ChoiceChip, label),
  );

  bool selected(WidgetTester tester, String label) =>
      tester.widget<ChoiceChip>(mainColourChip(label)).selected;

  Future<List<ClothingItem>> items(WidgetTester tester, TestApp app) async {
    late List<ClothingItem> all;
    await tester.runAsync(() async {
      all = await app.container
          .read(wardrobeRepositoryProvider)
          .watchItems(WardrobeFilter(statuses: ItemStatus.values.toSet()))
          .first;
    });
    return all;
  }

  testWidgets('a confident colour is prefilled, explained and saved with '
      'provenance', (tester) async {
    final app = await review(
      tester,
      Success(
        _analysis(ColorFamily.navy, 0.92, secondary: [ColorFamily.white]),
      ),
    );

    await scrollTo(tester, find.textContaining('Suggested from the photo'));
    expect(find.textContaining('(92%)'), findsOneWidget);
    expect(selected(tester, 'Navy'), isTrue);
    await scrollTo(tester, find.text('Also detected in the photo:'));
    expect(find.text('White 30%'), findsOneWidget);

    await tapAndSettle(tester, find.text('Top').last);
    await tapAndSettle(tester, find.text('Add to wardrobe'));
    await pumpUntil(tester, find.byTooltip('Edit'));

    final saved = (await items(tester, app)).single;
    expect(saved.attributes.primaryColor, ColorFamily.navy);
    expect(
      saved.attributes.secondaryColors,
      isEmpty,
      reason: 'secondary colours are offered, never applied silently',
    );
    late List<bool> confirmed;
    await tester.runAsync(() async {
      final rows = await app.db.select(app.db.clothingAttributes).get();
      confirmed = [
        for (final r in rows)
          if (r.attribute == 'PRIMARY_COLOR') r.userConfirmed,
      ];
    });
    expect(confirmed, [isTrue]);
    expect(app.analyzer.calls, 1);
    await app.dispose(tester);
  });

  testWidgets('a medium-confidence colour asks for confirmation', (
    tester,
  ) async {
    final app = await review(tester, Success(_analysis(ColorFamily.navy, 0.6)));
    await scrollTo(tester, find.textContaining('Please confirm'));
    expect(find.textContaining('(60%)'), findsOneWidget);
    expect(selected(tester, 'Navy'), isTrue);
    await app.dispose(tester);
  });

  testWidgets('a low-confidence colour is only a hint the user can tap', (
    tester,
  ) async {
    final app = await review(
      tester,
      Success(
        _analysis(
          ColorFamily.navy,
          0.35,
          alternatives: [(ColorFamily.blue, 0.3)],
        ),
      ),
    );
    await scrollTo(tester, find.text('Not sure about the colour. Possible:'));
    expect(selected(tester, 'Navy'), isFalse, reason: 'not prefilled');

    await tapAndSettle(tester, find.widgetWithText(ActionChip, 'Blue 30%'));
    expect(selected(tester, 'Blue'), isTrue);
    await app.dispose(tester);
  });

  testWidgets('if analysis fails, manual entry still works', (tester) async {
    final app = await review(
      tester,
      const Failure(UnsupportedImageFailure('not decodable')),
    );
    await scrollTo(tester, find.textContaining('Couldn\'t detect colours'));

    await tapAndSettle(tester, find.text('Top').last);
    await tapAndSettle(tester, mainColourChip('Red'));
    await tapAndSettle(tester, find.text('Add to wardrobe'));
    await pumpUntil(tester, find.byTooltip('Edit'));

    final saved = (await items(tester, app)).single;
    expect(saved.status, ItemStatus.active);
    expect(saved.attributes.primaryColor, ColorFamily.red);
    await app.dispose(tester);
  });
}
