import '../core/result.dart';
import '../taxonomy/taxonomy.dart';
import 'clothing_attributes.dart';
import 'clothing_item.dart';
import 'wardrobe_filter.dart';

/// Outcome of deleting an item.
enum DeleteOutcome {
  /// The item and its files were removed.
  removed,

  /// The item is referenced by outfit history, so it was hidden instead and
  /// its thumbnail kept for that history (DECISIONS D-19).
  hiddenForHistory,
}

/// Persistence and file lifecycle for wardrobe items (REQUIREMENTS §12).
///
/// Implementations own both database rows and image files, and must keep
/// them consistent: a failed operation leaves neither half-written.
abstract interface class WardrobeRepository {
  /// Live list of non-deleted items matching [filter], newest first.
  Stream<List<ClothingItem>> watchItems(WardrobeFilter filter);

  /// Live single item; emits `null` once it is deleted.
  Stream<ClothingItem?> watchItem(String id);

  Future<Result<ClothingItem>> getItem(String id);

  /// Copies the image at [sourcePath] into private storage, creates the
  /// working copy and thumbnail, and creates a DRAFT item.
  ///
  /// Fails with `DuplicateItemFailure` when identical image bytes already
  /// belong to a non-deleted item, `UnsupportedImageFailure` for files that
  /// are not decodable images, and `InsufficientStorageFailure` when full.
  Future<Result<ClothingItem>> importImage(String sourcePath);

  /// Replaces the item's attributes. With [activate], a DRAFT becomes ACTIVE.
  Future<Result<ClothingItem>> saveAttributes(
    String id,
    ClothingAttributes attributes, {
    required bool activate,
  });

  /// Archives or restores an item. DRAFT items cannot be archived.
  Future<Result<ClothingItem>> setStatus(String id, ItemStatus status);

  Future<Result<DeleteOutcome>> deleteItem(String id);

  /// Removes image files that no database row references (for example after
  /// a crash mid-import). Returns the number of files removed.
  Future<Result<int>> removeOrphanFiles();
}
