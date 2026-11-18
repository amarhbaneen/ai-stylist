import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../taxonomy/taxonomy.dart';
import 'clothing_attributes.dart';

/// App-relative paths to a large image and its small copy.
@immutable
final class ItemPicture {
  const ItemPicture({required this.image, required this.thumbnail});

  /// Large image for the details screens.
  final String image;

  /// Small copy for grids and analysis.
  final String thumbnail;
}

/// Which of an item's images is shown (FR-05, DECISIONS D-39, D-41).
enum ItemView {
  /// The user's own photo.
  photo,

  /// The background-removed cut-out made on the device.
  cutout,

  /// A product photo the user chose (for example found with a visual
  /// search app).
  product,
}

/// App-relative paths to an item's stored images (never absolute paths).
@immutable
final class ItemImages {
  const ItemImages({
    required this.original,
    required this.working,
    required this.thumbnail,
    this.cutout,
    this.cutoutRaw,
    this.product,
    this.view = ItemView.photo,
  });

  /// The user's photo exactly as imported (preserved, FR-02).
  final String original;

  /// Downscaled, orientation-corrected copy used for display and analysis.
  final String working;

  /// Small copy for grids.
  final String thumbnail;

  /// Background-removed version (transparent PNGs), if one was made. The
  /// original photo is always kept, so the user can switch back (D-39).
  final ItemPicture? cutout;

  /// The cut-out before studio polish (D-44), when [cutout] was polished.
  /// Analysis reads it, so polish never changes detected attributes.
  final ItemPicture? cutoutRaw;

  /// A product photo the user chose (JPEGs), if any (D-41).
  final ItemPicture? product;

  /// The image the user chose to show. Falls back to the photo when the
  /// chosen image does not exist.
  final ItemView view;

  /// The view actually shown.
  ItemView get shown => switch (view) {
    ItemView.cutout when cutout != null => ItemView.cutout,
    ItemView.product when product != null => ItemView.product,
    _ => ItemView.photo,
  };

  /// The large image to show.
  String get display => switch (shown) {
    ItemView.cutout => cutout!.image,
    ItemView.product => product!.image,
    ItemView.photo => working,
  };

  /// The small image to show and analyse.
  String get displayThumbnail => switch (shown) {
    ItemView.cutout => cutout!.thumbnail,
    ItemView.product => product!.thumbnail,
    ItemView.photo => thumbnail,
  };

  /// The small image to analyse: as shown, except that a polished cut-out
  /// is analysed from its unpolished copy (D-44).
  String get analysisThumbnail => shown == ItemView.cutout
      ? (cutoutRaw ?? cutout!).thumbnail
      : displayThumbnail;

  /// Whether [v] can be shown.
  bool has(ItemView v) => switch (v) {
    ItemView.photo => true,
    ItemView.cutout => cutout != null,
    ItemView.product => product != null,
  };
}

/// Encoded images for a cut-out, produced on device (FR-05).
@immutable
final class CutoutImages {
  const CutoutImages({
    required this.image,
    required this.thumbnail,
    required this.width,
    required this.height,
    this.rawImage,
    this.rawThumbnail,
  });

  /// PNG with transparency.
  final Uint8List image;

  /// Small PNG with transparency.
  final Uint8List thumbnail;

  /// Size of [image] in pixels.
  final int width;
  final int height;

  /// The cut-out before studio polish (PNGs), when [image] was polished
  /// (D-44). Kept so analysis reads real, unpolished pixels.
  final Uint8List? rawImage;
  final Uint8List? rawThumbnail;

  /// Whether this cut-out was polished (and carries its raw copy).
  bool get isPolished => rawImage != null && rawThumbnail != null;
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
