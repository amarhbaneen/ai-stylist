import 'package:drift/drift.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../../core/database/app_database.dart';

/// Stored values for `clothing_images.kind`.
abstract final class ImageKind {
  static const original = 'ORIGINAL';
  static const working = 'WORKING';
  static const thumbnail = 'THUMBNAIL';
  static const cutout = 'CUTOUT';
  static const cutoutThumbnail = 'CUTOUT_THUMBNAIL';

  /// The cut-out before studio polish, for analysis (D-44).
  static const cutoutRaw = 'CUTOUT_RAW';
  static const cutoutRawThumbnail = 'CUTOUT_RAW_THUMBNAIL';
  static const product = 'PRODUCT';
  static const productThumbnail = 'PRODUCT_THUMBNAIL';

  /// Kinds that belong to the photo (copied when one photo makes several
  /// items); the rest belong to one garment.
  static const photo = {original, working, thumbnail};

  /// Kinds kept for outfit history when a used item is deleted.
  static const history = {thumbnail, cutoutThumbnail, productThumbnail};
}

/// Stored values for `clothing_item_colors.role`.
abstract final class ColorRole {
  static const primary = 'PRIMARY';
  static const secondary = 'SECONDARY';
}

/// Converts between Drift rows and domain [ClothingItem]s.
abstract final class ClothingItemMapper {
  static ClothingItem toDomain(
    ClothingItemRow row, {
    required List<ClothingItemColorRow> colors,
    required List<ClothingItemSeasonRow> seasons,
    required List<ClothingImageRow> images,
  }) {
    final category = GarmentCategory.fromCode(row.category);
    var subcategory = GarmentSubcategory.tryFromCode(row.subcategory);
    // Drop inconsistent stored data rather than surfacing an invalid entity.
    if (subcategory != null && subcategory.category != category) {
      subcategory = null;
    }
    final primary = ColorFamily.tryFromCode(row.primaryColor);
    final secondary = {
      for (final c in colors)
        if (c.role == ColorRole.secondary) ?ColorFamily.tryFromCode(c.color),
    };
    return ClothingItem(
      id: row.id,
      status: ItemStatus.fromCode(row.status),
      createdAt: fromEpochMillisUtc(row.createdAt),
      updatedAt: fromEpochMillisUtc(row.updatedAt),
      images: _images(
        images,
        view: row.showProduct
            ? ItemView.product
            : row.showCutout
            ? ItemView.cutout
            : ItemView.photo,
      ),
      attributes: ClothingAttributes(
        category: category,
        subcategory: subcategory,
        displayName: row.displayName,
        notes: row.notes,
        primaryColor: primary,
        secondaryColors: secondary,
        pattern: GarmentPattern.fromCode(row.pattern),
        seasons: {for (final s in seasons) ?Season.tryFromCode(s.season)},
        formality: Formality.tryFromLevel(row.formality),
        fit: GarmentFit.fromCode(row.fit),
        brand: row.brand,
        warmth: Warmth.tryFromLevel(row.warmth),
      ),
    );
  }

  static ItemImages? _images(
    List<ClothingImageRow> rows, {
    required ItemView view,
  }) {
    String? find(String kind) {
      for (final r in rows) {
        if (r.kind == kind) return r.relativePath;
      }
      return null;
    }

    final original = find(ImageKind.original);
    final working = find(ImageKind.working);
    final thumbnail = find(ImageKind.thumbnail);
    if (thumbnail == null) return null;
    // History tombstones keep only thumbnails; show what the user saw.
    ItemPicture? picture(String large, String small) {
      final thumb = find(small);
      return thumb == null
          ? null
          : ItemPicture(image: find(large) ?? thumb, thumbnail: thumb);
    }

    return ItemImages(
      original: original ?? working ?? thumbnail,
      working: working ?? thumbnail,
      thumbnail: thumbnail,
      cutout: picture(ImageKind.cutout, ImageKind.cutoutThumbnail),
      cutoutRaw: picture(ImageKind.cutoutRaw, ImageKind.cutoutRawThumbnail),
      product: picture(ImageKind.product, ImageKind.productThumbnail),
      view: view,
    );
  }

  /// Column values for the attribute fields of `clothing_items`.
  static ClothingItemsCompanion attributeColumns(
    ClothingAttributes a, {
    required int updatedAt,
  }) => ClothingItemsCompanion(
    category: Value(a.category.code),
    subcategory: Value(a.subcategory?.code),
    displayName: Value(a.displayName),
    notes: Value(a.notes),
    primaryColor: Value(a.primaryColor?.code),
    pattern: Value(a.pattern.code),
    formality: Value(a.formality?.level),
    fit: Value(a.fit.code),
    brand: Value(a.brand),
    warmth: Value(a.warmth?.level),
    updatedAt: Value(updatedAt),
  );

  static List<ClothingItemColorsCompanion> colorRows(
    String itemId,
    ClothingAttributes a,
  ) => [
    if (a.primaryColor case final primary?)
      ClothingItemColorsCompanion.insert(
        itemId: itemId,
        color: primary.code,
        role: ColorRole.primary,
      ),
    for (final c in a.secondaryColors)
      ClothingItemColorsCompanion.insert(
        itemId: itemId,
        color: c.code,
        role: ColorRole.secondary,
      ),
  ];

  static List<ClothingItemSeasonsCompanion> seasonRows(
    String itemId,
    ClothingAttributes a,
  ) => [
    for (final s in a.seasons)
      ClothingItemSeasonsCompanion.insert(itemId: itemId, season: s.code),
  ];
}
