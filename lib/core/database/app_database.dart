import 'package:drift/drift.dart';

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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      // SQLite only enforces foreign keys when enabled on each connection.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
