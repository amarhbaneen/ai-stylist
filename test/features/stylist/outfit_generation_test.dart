import 'dart:io';

import 'package:ai_stylist/core/database/app_database.dart';
import 'package:ai_stylist/core/media/file_hasher.dart';
import 'package:ai_stylist/core/storage/file_store.dart';
import 'package:ai_stylist/features/profile/data/drift_profile_repository.dart';
import 'package:ai_stylist/features/stylist/data/drift_outfit_repository.dart';
import 'package:ai_stylist/features/wardrobe/data/drift_wardrobe_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outfit_engine/outfit_engine.dart';
import 'package:path/path.dart' as p;
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../support/fakes.dart';

/// End-to-end over the real database: wardrobe → engine → stored outfits.
void main() {
  late Directory tmp;
  late AppDatabase db;
  late FixedClock clock;
  late DriftWardrobeRepository wardrobe;
  late DriftOutfitRepository outfits;
  late GenerateOutfits generate;
  var seed = 0;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('outfit_gen');
    db = AppDatabase(NativeDatabase.memory());
    clock = FixedClock();
    final ids = SequentialIds();
    wardrobe = DriftWardrobeRepository(
      database: db,
      files: LocalFileStore(Directory(p.join(tmp.path, 'store'))),
      images: FakeImageProcessor(),
      hasher: sha256OfFile,
      clock: clock,
      ids: ids,
    );
    outfits = DriftOutfitRepository(database: db, clock: clock, ids: ids);
    generate = GenerateOutfits(
      wardrobe: wardrobe,
      profiles: DriftProfileRepository(database: db, clock: clock),
      outfits: outfits,
      clock: clock,
    );
  });

  tearDown(() async {
    await db.close();
    await tmp.delete(recursive: true);
  });

  Future<String> add(
    GarmentCategory category,
    ColorFamily color, {
    bool activate = true,
  }) async {
    final photo = await writePhoto(tmp, 'p${seed++}.jpg', seed: seed);
    final id = (await wardrobe.importImage(photo)).valueOrNull!.id;
    await wardrobe.saveAttributes(
      id,
      ClothingAttributes(category: category, primaryColor: color),
      activate: activate,
    );
    return id;
  }

  test(
    'generates, stores and reloads outfits from ACTIVE items only',
    () async {
      final tee = await add(GarmentCategory.top, ColorFamily.white);
      final jeans = await add(GarmentCategory.bottom, ColorFamily.navy);
      final shoes = await add(GarmentCategory.footwear, ColorFamily.white);
      final draft = await add(
        GarmentCategory.top,
        ColorFamily.red,
        activate: false,
      );

      final result = await generate(
        const StylistQuery(occasion: Occasion.casual),
      );

      final outcome = result.valueOrNull!;
      expect(outcome.outfits, hasLength(1));
      final saved = outcome.outfits.single;
      expect(saved.outfit.itemIds, {tee, jeans, shoes});
      expect(saved.outfit.itemIds, isNot(contains(draft)));

      final reloaded = await outfits.watchOutfit(saved.id).first;
      expect(reloaded!.outfit.signature, saved.outfit.signature);
      expect(
        reloaded.outfit.totalScore,
        closeTo(saved.outfit.totalScore, 1e-9),
      );
      expect(reloaded.outfit.breakdown, saved.outfit.breakdown);
      expect(reloaded.outfit.reasons, saved.outfit.reasons);
      expect(reloaded.outfit.templateId, OutfitTemplate.separates.id);
      expect(reloaded.occasion, Occasion.casual);
    },
  );

  test('history makes the next generation avoid the same outfit', () async {
    await add(GarmentCategory.top, ColorFamily.white);
    await add(GarmentCategory.top, ColorFamily.grey);
    await add(GarmentCategory.bottom, ColorFamily.navy);
    await add(GarmentCategory.footwear, ColorFamily.black);

    final first = (await generate(
      const StylistQuery(occasion: Occasion.casual, count: 1),
    )).valueOrNull!.outfits.single;
    final second = (await generate(
      const StylistQuery(occasion: Occasion.casual, count: 1),
    )).valueOrNull!.outfits.single;

    expect(second.outfit.signature, isNot(first.outfit.signature));
    final history = (await outfits.recentHistory(
      since: clock.now.subtract(const Duration(days: 1)),
    )).valueOrNull!;
    expect(history.signatures, hasLength(2));
  });

  test('nothing is stored when no outfit is possible', () async {
    await add(GarmentCategory.top, ColorFamily.white);

    final outcome = (await generate(
      const StylistQuery(occasion: Occasion.casual),
    )).valueOrNull!;

    expect(outcome.outfits, isEmpty);
    expect(outcome.activeItemCount, 1);
    expect(
      outcome.missing.map((m) => m.category),
      containsAll([GarmentCategory.bottom, GarmentCategory.footwear]),
    );
    expect(await db.select(db.outfits).get(), isEmpty);
  });

  test('an item used in an outfit is hidden, not deleted', () async {
    final tee = await add(GarmentCategory.top, ColorFamily.white);
    await add(GarmentCategory.bottom, ColorFamily.navy);
    await add(GarmentCategory.footwear, ColorFamily.white);
    final saved = (await generate(
      const StylistQuery(occasion: Occasion.casual),
    )).valueOrNull!.outfits.single;

    expect(
      (await wardrobe.deleteItem(tee)).valueOrNull,
      DeleteOutcome.hiddenForHistory,
    );
    // History still resolves the item reference.
    final reloaded = await outfits.watchOutfit(saved.id).first;
    expect(reloaded!.outfit.itemIds, contains(tee));
  });
}
