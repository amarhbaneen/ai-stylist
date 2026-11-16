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
