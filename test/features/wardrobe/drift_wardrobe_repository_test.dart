import 'dart:io';
import 'dart:typed_data';

import 'package:ai_stylist/core/database/app_database.dart';
import 'package:ai_stylist/core/media/file_hasher.dart';
import 'package:ai_stylist/core/storage/file_store.dart';
import 'package:ai_stylist/features/wardrobe/data/drift_wardrobe_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../support/fakes.dart';

void main() {
  late Directory tmp;
  late AppDatabase db;
  late FlakyFileStore files;
  late FakeImageProcessor processor;
  late FixedClock clock;
  late DriftWardrobeRepository repo;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('wardrobe_repo_test');
    db = AppDatabase(NativeDatabase.memory());
    files = FlakyFileStore(
      LocalFileStore(Directory(p.join(tmp.path, 'store'))),
    );
    processor = FakeImageProcessor();
    clock = FixedClock();
    repo = DriftWardrobeRepository(
      database: db,
      files: files,
      images: processor,
      hasher: sha256OfFile,
      clock: clock,
      ids: SequentialIds(),
    );
  });

  tearDown(() async {
    await db.close();
    await tmp.delete(recursive: true);
  });

  Future<ClothingItem> importOk(String name, {int seed = 1}) async {
    final path = await writePhoto(tmp, name, seed: seed);
    final result = await repo.importImage(path);
    expect(result, isA<Success<ClothingItem>>(), reason: '$result');
    return result.valueOrNull!;
  }

  Future<List<String>> storedFiles() async =>
      (await files.list('images')).valueOrNull!;

  group('importImage', () {
    test('creates a DRAFT with original, working copy and thumbnail', () async {
      final item = await importOk('shirt.JPG');

      expect(item.status, ItemStatus.draft);
      expect(item.attributes.category, GarmentCategory.unknown);
      expect(item.createdAt, clock.now);
      expect(item.images!.original, 'images/originals/${item.id}.jpg');
      expect(await storedFiles(), hasLength(3));
      // The original is preserved byte-for-byte (FR-02).
      final original = (await files.readBytes(item.images!.original))
          .valueOrNull;
      final source = await File(p.join(tmp.path, 'shirt.JPG')).readAsBytes();
      expect(original, source);
      expect(processor.calls.map((c) => c.$2), [1024, 320]);
    });

    test('the same photo twice is a duplicate, not a second item', () async {
      final first = await importOk('a.jpg');
      final copy = await File(p.join(tmp.path, 'a.jpg'))
          .copy(p.join(tmp.path, 'a-copy.jpg'));

      final result = await repo.importImage(copy.path);

      final failure = (result as Failure).failure;
      expect(failure, isA<DuplicateItemFailure>());
      expect((failure as DuplicateItemFailure).existingItemId, first.id);
      expect(await storedFiles(), hasLength(3));
    });

    test('rejects unsupported file types without touching storage', () async {
      final path = await writePhoto(tmp, 'notes.txt');
      final result = await repo.importImage(path);
      expect((result as Failure).failure, isA<UnsupportedImageFailure>());
      expect(await storedFiles(), isEmpty);
    });

    test('an undecodable image leaves no files and no rows', () async {
      processor.fail = true;
      final path = await writePhoto(tmp, 'broken.jpg');

      final result = await repo.importImage(path);

      expect((result as Failure).failure, isA<UnsupportedImageFailure>());
      expect(await storedFiles(), isEmpty);
      expect(await db.select(db.clothingItems).get(), isEmpty);
    });

    test(
      'low storage mid-import rolls back the files already written',
      () async {
        files.failOn = 'thumbs';
        final path = await writePhoto(tmp, 'big.jpg');

        final result = await repo.importImage(path);

        expect((result as Failure).failure, isA<InsufficientStorageFailure>());
        expect(await storedFiles(), isEmpty);
        expect(await db.select(db.clothingImages).get(), isEmpty);
      },
    );

    test('a missing source file is reported', () async {
      final result = await repo.importImage(p.join(tmp.path, 'gone.jpg'));
      expect((result as Failure).failure, isA<StorageFailure>());
    });
  });

  group('editing', () {
    test('confirming saves attributes and activates the draft', () async {
      final item = await importOk('tee.jpg');
      final attributes = ClothingAttributes(
        category: GarmentCategory.top,
        subcategory: GarmentSubcategory.tShirt,
        displayName: 'Navy tee',
        primaryColor: ColorFamily.navy,
        secondaryColors: {ColorFamily.white, ColorFamily.red},
        pattern: GarmentPattern.striped,
        seasons: {Season.summer, Season.spring},
        formality: Formality.casual,
        fit: GarmentFit.regular,
        brand: 'Acme',
        warmth: Warmth.light,
        notes: 'Soft cotton',
      );
      clock.now = clock.now.add(const Duration(minutes: 5));

      final saved = await repo.saveAttributes(
        item.id,
        attributes,
        activate: true,
      );

      expect(saved.valueOrNull!.status, ItemStatus.active);
      expect(saved.valueOrNull!.attributes, attributes);
      expect(saved.valueOrNull!.updatedAt, clock.now);
      // Re-read from the database to prove persistence.
      expect((await repo.getItem(item.id)).valueOrNull!.attributes, attributes);
    });

    test(
      'editing replaces colours and seasons rather than appending',
      () async {
        final item = await importOk('x.jpg');
        await repo.saveAttributes(
          item.id,
          ClothingAttributes(
            category: GarmentCategory.top,
            secondaryColors: {ColorFamily.red, ColorFamily.blue},
            seasons: {Season.winter},
          ),
          activate: true,
        );
        final updated = ClothingAttributes(
          category: GarmentCategory.top,
          secondaryColors: {ColorFamily.green},
        );

        await repo.saveAttributes(item.id, updated, activate: false);

        final read = (await repo.getItem(item.id)).valueOrNull!;
        expect(read.attributes, updated);
        expect(read.status, ItemStatus.active, reason: 'stays active');
      },
    );

    test('archive and restore; drafts cannot be archived', () async {
      final draft = await importOk('d.jpg');
      final denied = await repo.setStatus(draft.id, ItemStatus.archived);
      expect((denied as Failure).failure, isA<ValidationFailure>());

      await repo.saveAttributes(
        draft.id,
        ClothingAttributes(category: GarmentCategory.bottom),
        activate: true,
      );
      final archived = await repo.setStatus(draft.id, ItemStatus.archived);
      expect(archived.valueOrNull!.status, ItemStatus.archived);
      final restored = await repo.setStatus(draft.id, ItemStatus.active);
      expect(restored.valueOrNull!.status, ItemStatus.active);
    });

    test('unknown ids are NotFound', () async {
      expect(
        ((await repo.getItem('nope')) as Failure).failure,
        isA<NotFoundFailure>(),
      );
      expect(
        ((await repo.setStatus('nope', ItemStatus.active)) as Failure).failure,
        isA<NotFoundFailure>(),
      );
    });
  });

  group('watchItems', () {
    test('applies status, category and colour filters', () async {
      final tee = await importOk('tee.jpg', seed: 1);
      final boots = await importOk('boots.jpg', seed: 2);
      final draft = await importOk('draft.jpg', seed: 3);
      await repo.saveAttributes(
        tee.id,
        ClothingAttributes(
          category: GarmentCategory.top,
          primaryColor: ColorFamily.navy,
        ),
        activate: true,
      );
      await repo.saveAttributes(
        boots.id,
        ClothingAttributes(category: GarmentCategory.footwear),
        activate: true,
      );
      await repo.setStatus(boots.id, ItemStatus.archived);

      Future<List<String>> ids(WardrobeFilter f) async =>
          (await repo.watchItems(f).first).map((i) => i.id).toList();

      expect(await ids(WardrobeFilter()), unorderedEquals([tee.id, draft.id]));
      expect(await ids(WardrobeFilter(statuses: {ItemStatus.archived})), [
        boots.id,
      ]);
      expect(await ids(WardrobeFilter(colors: {ColorFamily.navy})), [tee.id]);
      expect(await ids(WardrobeFilter(categories: {GarmentCategory.top})), [
        tee.id,
      ]);
    });

    test('emits again after an edit', () async {
      final item = await importOk('a.jpg');
      final stream = repo.watchItem(item.id);
      final expectation = expectLater(
        stream.map((i) => i?.attributes.category),
        emitsInOrder([GarmentCategory.unknown, GarmentCategory.top]),
      );
      await Future<void>.delayed(Duration.zero);
      await repo.saveAttributes(
        item.id,
        ClothingAttributes(category: GarmentCategory.top),
        activate: true,
      );
      await expectation;
    });
  });

  group('deleteItem', () {
    test('removes the row and all files when unused by outfits', () async {
      final item = await importOk('a.jpg');

      final result = await repo.deleteItem(item.id);

      expect(result.valueOrNull, DeleteOutcome.removed);
      expect(await storedFiles(), isEmpty);
      expect(await db.select(db.clothingImages).get(), isEmpty);
    });

    test(
      'hides an item used in outfit history and keeps its thumbnail',
      () async {
        final item = await importOk('a.jpg');
        await repo.saveAttributes(
          item.id,
          ClothingAttributes(category: GarmentCategory.top),
          activate: true,
        );
        await db
            .into(db.outfits)
            .insert(
              OutfitsCompanion.insert(
                id: 'o1',
                signature: 's',
                occasion: 'CASUAL',
                requestJson: '{}',
                totalScore: 1,
                breakdownJson: '{}',
                reasonsJson: '[]',
                weatherConsidered: false,
                createdAt: 0,
              ),
            );
        await db
            .into(db.outfitItems)
            .insert(
              OutfitItemsCompanion.insert(
                outfitId: 'o1',
                itemId: item.id,
                slot: 'TOP',
              ),
            );

        final result = await repo.deleteItem(item.id);

        expect(result.valueOrNull, DeleteOutcome.hiddenForHistory);
        expect(
          ((await repo.getItem(item.id)) as Failure).failure,
          isA<NotFoundFailure>(),
        );
        expect(await repo.watchItems(WardrobeFilter()).first, isEmpty);
        expect(await storedFiles(), ['images/thumbs/${item.id}.jpg']);
        expect(await db.select(db.outfitItems).get(), hasLength(1));

        // The same photo can be added again as a new item.
        final again = await repo.importImage(p.join(tmp.path, 'a.jpg'));
        expect(again.isSuccess, isTrue);
      },
    );
  });

  test('removeOrphanFiles deletes only unreferenced image files', () async {
    final item = await importOk('a.jpg');
    await files.writeBytes(
      'images/originals/stray.jpg',
      Uint8List.fromList([1]),
    );

    final removed = await repo.removeOrphanFiles();

    expect(removed.valueOrNull, 1);
    expect(await storedFiles(), hasLength(3));
    expect(await files.exists(item.images!.thumbnail), isTrue);
  });
}
