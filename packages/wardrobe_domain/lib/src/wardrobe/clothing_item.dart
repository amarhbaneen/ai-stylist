import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../taxonomy/taxonomy.dart';
import 'clothing_attributes.dart';

/// App-relative paths to a background-removed copy of the photo (FR-05).
@immutable
final class ItemCutout {
  const ItemCutout({required this.image, required this.thumbnail});

  /// Transparent PNG of the garment, cropped to it.
  final String image;

  /// Small transparent PNG for grids and analysis.
  final String thumbnail;
}

/// App-relative paths to an item's stored images (never absolute paths).
@immutable
final class ItemImages {
  const ItemImages({
    required this.original,
    required this.working,
    required this.thumbnail,
    this.cutout,
    this.showCutout = false,
  });

  /// The user's photo exactly as imported (preserved, FR-02).
  final String original;

  /// Downscaled, orientation-corrected copy used for display and analysis.
  final String working;

  /// Small copy for grids.
  final String thumbnail;

  /// Background-removed version, if one was made. The original photo is
  /// always kept, so the user can switch back (DECISIONS D-39).
  final ItemCutout? cutout;

  /// Whether the user chose the cut-out over the photo.
  final bool showCutout;

  bool get _useCutout => showCutout && cutout != null;

  /// The large image to show: the cut-out when chosen, else the photo.
  String get display => _useCutout ? cutout!.image : working;

  /// The small image to show and analyse.
  String get displayThumbnail => _useCutout ? cutout!.thumbnail : thumbnail;
}

/// Encoded images for a cut-out, produced on device (FR-05).
@immutable
final class CutoutImages {
  const CutoutImages({
    required this.image,
    required this.thumbnail,
    required this.width,
    required this.height,
  });

  /// PNG with transparency.
  final Uint8List image;

  /// Small PNG with transparency.
  final Uint8List thumbnail;

  /// Size of [image] in pixels.
  final int width;
  final int height;
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
