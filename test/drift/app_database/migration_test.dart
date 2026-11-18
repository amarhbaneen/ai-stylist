// dart format width=80
// ignore_for_file: unused_local_variable, unused_import, directives_ordering
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:ai_stylist/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  // v2 only adds `clothing_items.show_cutout`: existing items and their
  // images must survive unchanged, showing their original photo.
  test('v1 to v2 keeps items and images, cut-out off', () async {
    const image = v1.ClothingImagesData(
      id: 'img-1',
      itemId: 'item-1',
      kind: 'THUMBNAIL',
      relativePath: 'images/thumbs/item-1.jpg',
      byteSize: 1234,
      createdAt: 1700000000000,
    );
    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.clothingItems, [
          const v1.ClothingItemsData(
            id: 'item-1',
            category: 'TOP',
            primaryColor: 'NAVY',
            status: 'ACTIVE',
            contentSha256: 'abc',
            createdAt: 1700000000000,
            updatedAt: 1700000000001,
          ),
        ]);
        batch.insertAll(oldDb.clothingImages, [image]);
      },
      validateItems: (newDb) async {
        expect(await newDb.select(newDb.clothingItems).get(), [
          const v2.ClothingItemsData(
            id: 'item-1',
            category: 'TOP',
            primaryColor: 'NAVY',
            status: 'ACTIVE',
            showCutout: 0, // false
            contentSha256: 'abc',
            createdAt: 1700000000000,
            updatedAt: 1700000000001,
          ),
        ]);
        expect(await newDb.select(newDb.clothingImages).get(), [
          v2.ClothingImagesData(
            id: image.id,
            itemId: image.itemId,
            kind: image.kind,
            relativePath: image.relativePath,
            byteSize: image.byteSize,
            createdAt: image.createdAt,
          ),
        ]);
      },
    );
  });

  // v3 only adds `clothing_items.show_product`: the cut-out choice stays.
  test('v2 to v3 keeps the cut-out choice, product photo off', () async {
    await verifier.testWithDataIntegrity(
      oldVersion: 2,
      newVersion: 3,
      createOld: v2.DatabaseAtV2.new,
      createNew: v3.DatabaseAtV3.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.clothingItems, [
          const v2.ClothingItemsData(
            id: 'item-1',
            category: 'TOP',
            status: 'ACTIVE',
            showCutout: 1,
            createdAt: 1700000000000,
            updatedAt: 1700000000001,
          ),
        ]);
      },
      validateItems: (newDb) async {
        expect(await newDb.select(newDb.clothingItems).get(), [
          const v3.ClothingItemsData(
            id: 'item-1',
            category: 'TOP',
            status: 'ACTIVE',
            showCutout: 1,
            showProduct: 0,
            createdAt: 1700000000000,
            updatedAt: 1700000000001,
          ),
        ]);
      },
    );
  });
}
