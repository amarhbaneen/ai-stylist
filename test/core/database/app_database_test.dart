import 'package:ai_stylist/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  const t = 1763200000000; // fixed UTC epoch millis for determinism

  Future<void> insertItem(String id, {int? formality}) => db
      .into(db.clothingItems)
      .insert(
        ClothingItemsCompanion.insert(
          id: id,
          category: 'TOP',
          status: 'ACTIVE',
          createdAt: t,
          updatedAt: t,
          formality: Value(formality),
        ),
      );

  Future<void> insertOutfitWith(String outfitId, String itemId) async {
    await db
        .into(db.outfits)
        .insert(
          OutfitsCompanion.insert(
            id: outfitId,
            signature: 'sig-$outfitId',
            occasion: 'CASUAL',
            requestJson: '{}',
            totalScore: 0.8,
            breakdownJson: '{}',
            reasonsJson: '[]',
            weatherConsidered: false,
            createdAt: t,
          ),
        );
    await db
        .into(db.outfitItems)
        .insert(
          OutfitItemsCompanion.insert(
            outfitId: outfitId,
            itemId: itemId,
            slot: 'TOP',
          ),
        );
  }

  test('schema v1 creates every required table', () async {
    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%'",
        )
        .get();
    final names = rows.map((r) => r.read<String>('name')).toSet();
    expect(
      names,
      containsAll(<String>[
        'user_profile',
        'clothing_items',
        'clothing_item_colors',
        'clothing_item_seasons',
        'clothing_images',
        'clothing_attributes',
        'outfits',
        'outfit_items',
        'outfit_feedback',
        'learned_preferences',
        'model_installations',
        'app_settings',
      ]),
    );
    expect(db.schemaVersion, 1);
  });

  test('foreign keys are enforced on open', () async {
    final row = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(row.read<int>('foreign_keys'), 1);
  });

  test('rejects an image that references a missing item', () async {
    await expectLater(
      db
          .into(db.clothingImages)
          .insert(
            ClothingImagesCompanion.insert(
              id: 'img-1',
              itemId: 'missing',
              kind: 'ORIGINAL',
              relativePath: 'images/originals/x.jpg',
              createdAt: t,
            ),
          ),
      throwsA(isA<Exception>()),
    );
  });

  test('deleting an item cascades to its images', () async {
    await insertItem('item-1');
    await db
        .into(db.clothingImages)
        .insert(
          ClothingImagesCompanion.insert(
            id: 'img-1',
            itemId: 'item-1',
            kind: 'ORIGINAL',
            relativePath: 'images/originals/item-1.jpg',
            createdAt: t,
          ),
        );

    await (db.delete(
      db.clothingItems,
    )..where((i) => i.id.equals('item-1'))).go();

    expect(await db.select(db.clothingImages).get(), isEmpty);
  });

  test('an item used in outfit history cannot be hard-deleted', () async {
    await insertItem('item-1');
    await insertOutfitWith('outfit-1', 'item-1');

    await expectLater(
      (db.delete(db.clothingItems)..where((i) => i.id.equals('item-1'))).go(),
      throwsA(isA<Exception>()),
    );
    expect(await db.select(db.outfitItems).get(), hasLength(1));
  });

  test('formality outside 1..5 is rejected; null is allowed', () async {
    await insertItem('ok', formality: 5);
    await insertItem('unknown');
    await expectLater(
      insertItem('bad', formality: 6),
      throwsA(isA<Exception>()),
    );
  });

  test('a failed transaction rolls back every write', () async {
    await expectLater(
      db.transaction(() async {
        await insertItem('item-1');
        await insertItem('item-1'); // duplicate primary key
      }),
      throwsA(isA<Exception>()),
    );
    expect(await db.select(db.clothingItems).get(), isEmpty);
  });

  test('learned preference weights are bounded', () async {
    await expectLater(
      db
          .into(db.learnedPreferences)
          .insert(
            LearnedPreferencesCompanion.insert(
              key: 'color:navy',
              weight: 0.5,
              updatedAt: t,
            ),
          ),
      throwsA(isA<Exception>()),
    );
  });
}
