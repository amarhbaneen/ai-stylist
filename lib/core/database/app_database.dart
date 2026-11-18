import 'package:drift/drift.dart';

import 'app_database.steps.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// The app's single local SQLite database.
///
/// Only repositories in `data/` layers may use this class; UI code must go
/// through use cases (CLAUDE.md architecture rules).
@DriftDatabase(
  tables: [
    UserProfile,
    ClothingItems,
    ClothingItemColors,
    ClothingItemSeasons,
    ClothingImages,
    ClothingAttributes,
    Outfits,
    OutfitItems,
    OutfitFeedback,
    LearnedPreferences,
    ModelInstallations,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Bump on every schema change and add a step to [migration]. Never drop
  /// user data in a migration (REQUIREMENTS §11).
  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: stepByStep(
      // v2 (FR-05): per-item choice between cut-out and original photo.
      from1To2: (m, schema) async {
        await m.addColumn(
          schema.clothingItems,
          schema.clothingItems.showCutout,
        );
      },
      // v3 (D-41): per-item choice of a product photo the user picked.
      from2To3: (m, schema) async {
        await m.addColumn(
          schema.clothingItems,
          schema.clothingItems.showProduct,
        );
      },
    ),
    beforeOpen: (details) async {
      // SQLite only enforces foreign keys when enabled on each connection.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
