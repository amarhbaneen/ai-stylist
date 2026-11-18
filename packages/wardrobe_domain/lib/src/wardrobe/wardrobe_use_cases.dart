import '../core/app_failure.dart';
import '../core/result.dart';
import '../taxonomy/taxonomy.dart';
import 'clothing_attributes.dart';
import 'clothing_item.dart';
import 'wardrobe_filter.dart';
import 'wardrobe_repository.dart';

/// Imports a photo the user picked and returns the new DRAFT item.
final class ImportClothingPhoto {
  const ImportClothingPhoto(this._repository);

  final WardrobeRepository _repository;

  Future<Result<ClothingItem>> call(String sourcePath) =>
      _repository.importImage(sourcePath);
}

/// Applies cut-outs found in one photo (FR-05, D-39): the first goes to
/// [itemId]; each other one becomes a new DRAFT item from the same photo.
///
/// All or nothing for the new items: if one cannot be created, the ones
/// already created are removed and the failure is returned. The first item
/// keeps its photo either way, so adding it is never blocked.
final class AddGarmentsFromPhoto {
  const AddGarmentsFromPhoto(this._repository);

  final WardrobeRepository _repository;

  /// Returns the items in the order of [cutouts].
  Future<Result<List<ClothingItem>>> call(
    String itemId,
    List<CutoutImages> cutouts,
  ) async {
    if (cutouts.isEmpty) {
      return const Failure(ValidationFailure('No garments were selected'));
    }
    final first = await _repository.saveCutout(itemId, cutouts.first);
    if (first case Failure(:final failure)) return Failure(failure);
    final items = [(first as Success<ClothingItem>).value];

    for (final cutout in cutouts.skip(1)) {
      final created = await _repository.copyPhotoToNewItem(itemId);
      final Result<ClothingItem> saved = switch (created) {
        Success(:final value) => await _repository.saveCutout(value.id, cutout),
        Failure(:final failure) => Failure(failure),
      };
      switch (saved) {
        case Success(:final value):
          items.add(value);
        case Failure(:final failure):
          if (created case Success(:final value)) {
            await _repository.deleteItem(value.id);
          }
          for (final item in items.skip(1)) {
            await _repository.deleteItem(item.id);
          }
          return Failure(failure);
      }
    }
    return Success(items);
  }
}

/// Chooses which of an item's images is shown (photo, cut-out or product
/// photo).
final class ChooseItemView {
  const ChooseItemView(this._repository);

  final WardrobeRepository _repository;

  Future<Result<ClothingItem>> call(String id, ItemView view) =>
      _repository.setView(id, view);
}

/// Mirrors an item's cut-out, for selfies the front camera saved mirrored.
final class FlipCutout {
  const FlipCutout(this._repository);

  final WardrobeRepository _repository;

  Future<Result<ClothingItem>> call(String id) => _repository.flipCutout(id);
}

/// Sets or removes the product photo the user chose for an item (D-41).
final class ManageProductPhoto {
  const ManageProductPhoto(this._repository);

  final WardrobeRepository _repository;

  Future<Result<ClothingItem>> use(String id, String sourcePath) =>
      _repository.saveProductPhoto(id, sourcePath);

  Future<Result<ClothingItem>> remove(String id) =>
      _repository.removeProductPhoto(id);
}

/// Validates and saves attributes; [confirm] makes the item ACTIVE.
///
/// An item becomes ACTIVE only after the user confirms it (REQUIREMENTS
/// §6.2.8), and only with a known category.
final class SaveClothingItem {
  const SaveClothingItem(this._repository);

  final WardrobeRepository _repository;

  Future<Result<ClothingItem>> call(
    String id,
    ClothingAttributes attributes, {
    required bool confirm,
  }) async {
    final existing = await _repository.getItem(id);
    final ItemStatus status;
    switch (existing) {
      case Failure(:final failure):
        return Failure(failure);
      case Success(:final value):
        status = value.status;
    }
    // Items that are already ACTIVE must keep a valid category.
    final mustBeActivatable = confirm || status == ItemStatus.active;
    final invalid = attributes.validate(forActivation: mustBeActivatable);
    if (invalid != null) return Failure(invalid);
    return _repository.saveAttributes(id, attributes, activate: confirm);
  }
}

final class ArchiveClothingItem {
  const ArchiveClothingItem(this._repository);

  final WardrobeRepository _repository;

  Future<Result<ClothingItem>> call(String id) =>
      _repository.setStatus(id, ItemStatus.archived);
}

final class RestoreClothingItem {
  const RestoreClothingItem(this._repository);

  final WardrobeRepository _repository;

  Future<Result<ClothingItem>> call(String id) =>
      _repository.setStatus(id, ItemStatus.active);
}

final class DeleteClothingItem {
  const DeleteClothingItem(this._repository);

  final WardrobeRepository _repository;

  Future<Result<DeleteOutcome>> call(String id) => _repository.deleteItem(id);
}

final class WatchWardrobe {
  const WatchWardrobe(this._repository);

  final WardrobeRepository _repository;

  Stream<List<ClothingItem>> call(WardrobeFilter filter) =>
      _repository.watchItems(filter);
}
