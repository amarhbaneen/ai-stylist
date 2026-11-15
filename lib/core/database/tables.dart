// Drift table definitions, schema v1 (IMPLEMENTATION_PLAN.md §2).
//
// Conventions: UUID v4 text primary keys, integer UTC epoch milliseconds,
// enum values stored as their stable `code` strings from wardrobe_domain,
// and image files referenced by app-relative paths only.
//
// Drift CHECK constraints reference the column being declared
// (`x => integer().check(x.isNull() | ...)`). That is Drift's documented
// pattern and is evaluated by the code generator, not at run time.
// ignore_for_file: recursive_getters
import 'package:drift/drift.dart';

/// Single local profile with optional explicit preferences (FR-01).
class UserProfile extends Table {
  TextColumn get id => text()();

  /// JSON array of style codes.
  TextColumn get preferredStyles => text().withDefault(const Constant('[]'))();

  /// JSON array of colour codes to favour.
  TextColumn get favoredColors => text().withDefault(const Constant('[]'))();

  /// JSON array of colour codes to avoid.
  TextColumn get avoidedColors => text().withDefault(const Constant('[]'))();

  TextColumn get fitPreference => text().nullable()();
  IntColumn get formalityPreference => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_clothing_items_status', columns: {#status})
@TableIndex(name: 'idx_clothing_items_category', columns: {#category})
@TableIndex(name: 'idx_clothing_items_sha256', columns: {#contentSha256})
class ClothingItems extends Table {
  TextColumn get id => text()();
  TextColumn get category => text()();
  TextColumn get subcategory => text().nullable()();
  TextColumn get displayName => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get primaryColor => text().nullable()();
  TextColumn get pattern => text().nullable()();

  /// Formality level 1–5; null when unknown.
  IntColumn get formality => integer().nullable().check(
    formality.isNull() | formality.isBetweenValues(1, 5),
  )();

  TextColumn get fit => text().nullable()();
  TextColumn get brand => text().nullable()();

  /// Warmth level 1–3; null when unknown (proposed addition for weather).
  IntColumn get warmth => integer().nullable().check(
    warmth.isNull() | warmth.isBetweenValues(1, 3),
  )();

  /// DRAFT, ACTIVE or ARCHIVED (ItemStatus codes).
  TextColumn get status => text()();

  /// SHA-256 of the original image bytes, used for duplicate detection.
  TextColumn get contentSha256 => text().nullable()();

  /// Set when the user deletes an item that outfit history still references.
  /// Such tombstones are never shown or used for new outfits.
  IntColumn get deletedAt => integer().nullable()();

  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Primary and secondary colours of an item.
class ClothingItemColors extends Table {
  TextColumn get itemId =>
      text().references(ClothingItems, #id, onDelete: KeyAction.cascade)();
  TextColumn get color => text()();

  /// PRIMARY or SECONDARY.
  TextColumn get role => text()();

  @override
  Set<Column> get primaryKey => {itemId, color, role};
}

class ClothingItemSeasons extends Table {
  TextColumn get itemId =>
      text().references(ClothingItems, #id, onDelete: KeyAction.cascade)();

  /// Season code.
  TextColumn get season => text()();

  @override
  Set<Column> get primaryKey => {itemId, season};
}

@TableIndex(name: 'idx_clothing_images_item', columns: {#itemId})
class ClothingImages extends Table {
  TextColumn get id => text()();
  TextColumn get itemId =>
      text().references(ClothingItems, #id, onDelete: KeyAction.cascade)();

  /// ORIGINAL, WORKING, THUMBNAIL or CUTOUT.
  TextColumn get kind => text()();

  /// Path relative to the app's private storage root. Never absolute.
  TextColumn get relativePath => text()();

  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  IntColumn get byteSize => integer().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// AI-proposed or user-confirmed attribute values with provenance (FR-04).
@TableIndex(name: 'idx_clothing_attributes_item', columns: {#itemId})
class ClothingAttributes extends Table {
  TextColumn get id => text()();
  TextColumn get itemId =>
      text().references(ClothingItems, #id, onDelete: KeyAction.cascade)();
  TextColumn get attribute => text()();
  TextColumn get value => text()();
  RealColumn get confidence => real().nullable().check(
    confidence.isNull() | confidence.isBetweenValues(0, 1),
  )();
  TextColumn get modelId => text().nullable()();
  TextColumn get modelVersion => text().nullable()();
  IntColumn get analyzedAt => integer().nullable()();
  BoolColumn get userConfirmed =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_outfits_signature', columns: {#signature})
@TableIndex(name: 'idx_outfits_created', columns: {#createdAt})
class Outfits extends Table {
  TextColumn get id => text()();

  /// Stable hash of the sorted item IDs, used for de-duplication.
  TextColumn get signature => text()();
  TextColumn get occasion => text()();
  TextColumn get requestJson => text()();
  RealColumn get totalScore => real()();
  TextColumn get breakdownJson => text()();
  TextColumn get reasonsJson => text()();
  BoolColumn get weatherConsidered => boolean()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class OutfitItems extends Table {
  TextColumn get outfitId =>
      text().references(Outfits, #id, onDelete: KeyAction.cascade)();

  /// RESTRICT keeps outfit history intact; deleting a referenced garment
  /// becomes a tombstone (ClothingItems.deletedAt) instead.
  TextColumn get itemId =>
      text().references(ClothingItems, #id, onDelete: KeyAction.restrict)();
  TextColumn get slot => text()();

  @override
  Set<Column> get primaryKey => {outfitId, itemId};
}

@TableIndex(name: 'idx_outfit_feedback_outfit', columns: {#outfitId})
class OutfitFeedback extends Table {
  TextColumn get id => text()();
  TextColumn get outfitId =>
      text().references(Outfits, #id, onDelete: KeyAction.cascade)();

  /// LIKE or DISLIKE.
  TextColumn get kind => text()();
  TextColumn get reasonCode => text().nullable()();
  TextColumn get reasonText => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Learned (not explicit) preference weights, bounded and resettable (D-11).
class LearnedPreferences extends Table {
  /// For example `color:navy` or `style:minimal`.
  TextColumn get key => text()();
  RealColumn get weight => real().check(weight.isBetweenValues(-0.3, 0.3))();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {key};
}

class ModelInstallations extends Table {
  TextColumn get modelId => text()();
  TextColumn get version => text()();
  TextColumn get relativePath => text()();
  TextColumn get sha256 => text()();
  IntColumn get byteSize => integer()();
  TextColumn get license => text()();

  /// INSTALLED, STAGED or FAILED.
  TextColumn get state => text()();
  IntColumn get installedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {modelId, version};
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
