// DRAFT taxonomy, pending product approval (DECISIONS P-6,
// IMPLEMENTATION_PLAN.md §4). Categories are garment-based, never gendered.
import 'coded_enum.dart';

/// Lifecycle status of a wardrobe item.
enum ItemStatus implements CodedEnum {
  /// Imported but not yet confirmed by the user; never eligible for outfits.
  draft('DRAFT'),

  /// Confirmed and eligible for outfit generation.
  active('ACTIVE'),

  /// Kept for history but excluded from new outfits.
  archived('ARCHIVED');

  const ItemStatus(this.code);

  @override
  final String code;

  static ItemStatus fromCode(String? code) =>
      enumFromCode(values, code, fallback: ItemStatus.draft);
}

/// Top-level garment category used by outfit templates.
enum GarmentCategory implements CodedEnum {
  top('TOP'),
  bottom('BOTTOM'),
  onePiece('ONE_PIECE'),
  outerwear('OUTERWEAR'),
  footwear('FOOTWEAR'),
  accessory('ACCESSORY'),
  unknown('UNKNOWN');

  const GarmentCategory(this.code);

  @override
  final String code;

  static GarmentCategory fromCode(String? code) =>
      enumFromCode(values, code, fallback: GarmentCategory.unknown);
}

/// Visual pattern of a garment.
enum GarmentPattern implements CodedEnum {
  solid('SOLID'),
  striped('STRIPED'),
  checked('CHECKED'),
  floral('FLORAL'),
  graphic('GRAPHIC'),
  dotted('DOTTED'),
  animal('ANIMAL'),
  other('OTHER'),
  unknown('UNKNOWN');

  const GarmentPattern(this.code);

  @override
  final String code;

  static GarmentPattern fromCode(String? code) =>
      enumFromCode(values, code, fallback: GarmentPattern.unknown);
}

/// Seasons an item suits (an item can have several).
enum Season implements CodedEnum {
  spring('SPRING'),
  summer('SUMMER'),
  autumn('AUTUMN'),
  winter('WINTER');

  const Season(this.code);

  @override
  final String code;

  /// Returns `null` for unknown codes so callers can drop them.
  static Season? tryFromCode(String code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}

/// Garment fit. Optional; [unknown] when not provided.
enum GarmentFit implements CodedEnum {
  slim('SLIM'),
  regular('REGULAR'),
  relaxed('RELAXED'),
  oversized('OVERSIZED'),
  unknown('UNKNOWN');

  const GarmentFit(this.code);

  @override
  final String code;

  static GarmentFit fromCode(String? code) =>
      enumFromCode(values, code, fallback: GarmentFit.unknown);
}

/// Formality on a defined 1–5 scale (REQUIREMENTS FR-03).
enum Formality {
  lounge(1),
  casual(2),
  smartCasual(3),
  business(4),
  formal(5);

  const Formality(this.level);

  /// Stored integer level, 1 (least formal) to 5 (most formal).
  final int level;

  /// Returns `null` for out-of-range levels (meaning "unknown").
  static Formality? tryFromLevel(int? level) {
    for (final value in values) {
      if (value.level == level) return value;
    }
    return null;
  }
}
