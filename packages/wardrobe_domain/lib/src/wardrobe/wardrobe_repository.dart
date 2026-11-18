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

  /// Stores a background-removed copy of the item's photo and shows it.
  /// Replaces an earlier cut-out. The original photo is never changed.
  Future<Result<ClothingItem>> saveCutout(String id, CutoutImages cutout);

  /// Mirrors the cut-out left to right (for front-camera selfies) and
  /// shows it. Fails with `ValidationFailure` when there is no cut-out.
  Future<Result<ClothingItem>> flipCutout(String id);

  /// Stores a product photo the user chose (D-41), as downscaled JPEG
  /// copies of the image at [sourcePath], and shows it. Replaces an earlier
  /// product photo. Fails like [importImage] for unreadable images.
  Future<Result<ClothingItem>> saveProductPhoto(String id, String sourcePath);

  /// Deletes the product photo, if any, and shows the cut-out or photo.
  Future<Result<ClothingItem>> removeProductPhoto(String id);

  /// Chooses which image is shown. Fails with `ValidationFailure` when the
  /// item has no such image.
  Future<Result<ClothingItem>> setView(String id, ItemView view);

  /// Creates a new DRAFT item from the same photo as [sourceId], for a photo
  /// with several garments (D-39). The new item gets its own copies of the
  /// photo files, so deleting one item never affects another.
  Future<Result<ClothingItem>> copyPhotoToNewItem(String sourceId);

  /// Archives or restores an item. DRAFT items cannot be archived.
  Future<Result<ClothingItem>> setStatus(String id, ItemStatus status);

  Future<Result<DeleteOutcome>> deleteItem(String id);

  /// Removes image files that no database row references (for example after
  /// a crash mid-import). Returns the number of files removed.
  Future<Result<int>> removeOrphanFiles();
}
