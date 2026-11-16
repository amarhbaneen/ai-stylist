import 'package:ai_stylist/core/database/app_database.dart';
import 'package:ai_stylist/features/clothing_analysis/data/drift_analysis_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../support/fakes.dart';

const _src = AnalysisSource(modelId: 'color-tier0', modelVersion: '1.0.0');
final _at = DateTime.utc(2026, 11, 16, 10);

Suggestion<T> _s<T>(T v, double c, {List<(T, double)> alts = const []}) =>
    Suggestion(
      value: v,
      confidence: c,
      source: _src,
      analyzedAt: _at,
      alternatives: alts,
    );

void main() {
  late AppDatabase db;
  late DriftAnalysisRepository repo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftAnalysisRepository(database: db, ids: SequentialIds());
    await db
        .into(db.clothingItems)
        .insert(
          ClothingItemsCompanion.insert(
            id: 'item',
            category: 'UNKNOWN',
            status: 'DRAFT',
            createdAt: 0,
            updatedAt: 0,
          ),
        );
  });
  tearDown(() => db.close());

  final analysis = ClothingAnalysis(
    primaryColor: _s(
      ColorFamily.navy,
      0.82,
      alts: [(ColorFamily.blue, 0.1), (ColorFamily.black, 0.05)],
    ),
    secondaryColors: [_s(ColorFamily.white, 0.3)],
    category: _s(GarmentCategory.top, 0.7),
  );

  test('nothing stored reads as "never analysed"', () async {
    expect((await repo.load('item')).valueOrNull, isNull);
  });

  test('round-trips suggestions with provenance', () async {
    await repo.save('item', analysis);
    final loaded = (await repo.load('item')).valueOrNull!;

    expect(loaded.primaryColor!.value, ColorFamily.navy);
    expect(loaded.primaryColor!.confidence, closeTo(0.82, 1e-9));
    expect(loaded.primaryColor!.source, _src);
    expect(loaded.primaryColor!.analyzedAt, _at);
    expect(loaded.primaryColor!.alternatives.map((a) => a.$1), [
      ColorFamily.blue,
      ColorFamily.black,
    ]);
    expect(loaded.secondaryColors.single.value, ColorFamily.white);
    expect(loaded.category!.value, GarmentCategory.top);
  });

  test('saving again replaces earlier suggestions', () async {
    await repo.save('item', analysis);
    await repo.save(
      'item',
      ClothingAnalysis(primaryColor: _s(ColorFamily.red, 0.9)),
    );
    final loaded = (await repo.load('item')).valueOrNull!;
    expect(loaded.primaryColor!.value, ColorFamily.red);
    expect(loaded.secondaryColors, isEmpty);
    expect(loaded.category, isNull);
  });

  test('records which suggestions the user kept', () async {
    await repo.save('item', analysis);
    await ConfirmAnalysis(repo)(
      'item',
      ClothingAttributes(
        category: GarmentCategory.bottom, // user changed it
        primaryColor: ColorFamily.navy, // kept
        secondaryColors: {ColorFamily.white}, // kept
      ),
    );
    final rows = await db.select(db.clothingAttributes).get();
    bool confirmed(String attr, String value) => rows
        .singleWhere((r) => r.attribute == attr && r.value == value)
        .userConfirmed;
    expect(confirmed('PRIMARY_COLOR', 'NAVY'), isTrue);
    expect(confirmed('SECONDARY_COLOR', 'WHITE'), isTrue);
    expect(confirmed('CATEGORY', 'TOP'), isFalse);
    expect(confirmed('PRIMARY_COLOR_ALT', 'BLUE'), isFalse);
  });

  test('suggestions are deleted with their item', () async {
    await repo.save('item', analysis);
    await (db.delete(db.clothingItems)..where((t) => t.id.equals('item'))).go();
    expect(await db.select(db.clothingAttributes).get(), isEmpty);
  });
}
