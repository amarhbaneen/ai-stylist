import 'package:meta/meta.dart';

import '../taxonomy/taxonomy.dart';
import 'clothing_attributes.dart';

/// App-relative paths to an item's stored images (never absolute paths).
@immutable
final class ItemImages {
  const ItemImages({
    required this.original,
    required this.working,
    required this.thumbnail,
  });

  /// The user's photo exactly as imported (preserved, FR-02).
  final String original;

  /// Downscaled, orientation-corrected copy used for display and analysis.
  final String working;

  /// Small copy for grids.
  final String thumbnail;
}

/// A garment in the user's wardrobe.
@immutable
final class ClothingItem {
  const ClothingItem({
    required this.id,
    required this.attributes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.images,
  });

  /// Stable UUID.
  final String id;
  final ClothingAttributes attributes;
  final ItemStatus status;

  /// `null` only if image records are missing (e.g. a damaged restore).
  final ItemImages? images;

  /// UTC.
  final DateTime createdAt;

  /// UTC.
  final DateTime updatedAt;

  /// Only ACTIVE items may appear in new outfits (CLAUDE.md rule 9).
  bool get isEligibleForOutfits => status == ItemStatus.active;

  /// Name to show in the UI: the user's name, else the subcategory/category.
  String? get displayName => attributes.displayName;
}
