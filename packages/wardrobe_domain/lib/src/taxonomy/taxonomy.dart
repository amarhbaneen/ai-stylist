// Garment taxonomy (DECISIONS P-6, IMPLEMENTATION_PLAN.md §4), accepted as
// the working default when M2 started. Categories are garment-based and never
// gendered. Codes are persisted: add new values freely, never rename codes.
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

/// How warm a garment is, used later by weather scoring. 1–3; null = unknown.
enum Warmth {
  light(1),
  medium(2),
  heavy(3);

  const Warmth(this.level);

  final int level;

  static Warmth? tryFromLevel(int? level) {
    for (final value in values) {
      if (value.level == level) return value;
    }
    return null;
  }
}

/// Subcategories, each belonging to exactly one [GarmentCategory].
enum GarmentSubcategory implements CodedEnum {
  tShirt('T_SHIRT', GarmentCategory.top),
  shirt('SHIRT', GarmentCategory.top),
  blouse('BLOUSE', GarmentCategory.top),
  polo('POLO', GarmentCategory.top),
  sweater('SWEATER', GarmentCategory.top),
  hoodie('HOODIE', GarmentCategory.top),
  tank('TANK', GarmentCategory.top),
  otherTop('OTHER_TOP', GarmentCategory.top),
  jeans('JEANS', GarmentCategory.bottom),
  trousers('TROUSERS', GarmentCategory.bottom),
  chinos('CHINOS', GarmentCategory.bottom),
  shorts('SHORTS', GarmentCategory.bottom),
  skirt('SKIRT', GarmentCategory.bottom),
  leggings('LEGGINGS', GarmentCategory.bottom),
  otherBottom('OTHER_BOTTOM', GarmentCategory.bottom),
  dress('DRESS', GarmentCategory.onePiece),
  jumpsuit('JUMPSUIT', GarmentCategory.onePiece),
  overall('OVERALL', GarmentCategory.onePiece),
  otherOnePiece('OTHER_ONE_PIECE', GarmentCategory.onePiece),
  jacket('JACKET', GarmentCategory.outerwear),
  blazer('BLAZER', GarmentCategory.outerwear),
  coat('COAT', GarmentCategory.outerwear),
  cardigan('CARDIGAN', GarmentCategory.outerwear),
  vest('VEST', GarmentCategory.outerwear),
  otherOuterwear('OTHER_OUTERWEAR', GarmentCategory.outerwear),
  sneakers('SNEAKERS', GarmentCategory.footwear),
  boots('BOOTS', GarmentCategory.footwear),
  dressShoes('DRESS_SHOES', GarmentCategory.footwear),
  loafers('LOAFERS', GarmentCategory.footwear),
  sandals('SANDALS', GarmentCategory.footwear),
  heels('HEELS', GarmentCategory.footwear),
  flats('FLATS', GarmentCategory.footwear),
  otherFootwear('OTHER_FOOTWEAR', GarmentCategory.footwear),
  bag('BAG', GarmentCategory.accessory),
  hat('HAT', GarmentCategory.accessory),
  scarf('SCARF', GarmentCategory.accessory),
  belt('BELT', GarmentCategory.accessory),
  tie('TIE', GarmentCategory.accessory),
  otherAccessory('OTHER_ACCESSORY', GarmentCategory.accessory);

  const GarmentSubcategory(this.code, this.category);

  @override
  final String code;

  final GarmentCategory category;

  /// Subcategories valid for [category] (empty for [GarmentCategory.unknown]).
  static List<GarmentSubcategory> of(GarmentCategory category) =>
      values.where((s) => s.category == category).toList(growable: false);

  static GarmentSubcategory? tryFromCode(String? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}

/// Named colour families. Exact colour values are not stored in the MVP.
enum ColorFamily implements CodedEnum {
  black('BLACK', isNeutral: true),
  white('WHITE', isNeutral: true),
  grey('GREY', isNeutral: true),
  beige('BEIGE', isNeutral: true),
  brown('BROWN', isNeutral: true),
  navy('NAVY', isNeutral: true),
  blue('BLUE'),
  green('GREEN'),
  olive('OLIVE'),
  yellow('YELLOW'),
  orange('ORANGE'),
  red('RED'),
  burgundy('BURGUNDY'),
  pink('PINK'),
  purple('PURPLE'),
  multicolor('MULTICOLOR');

  const ColorFamily(this.code, {this.isNeutral = false});

  @override
  final String code;

  /// Neutrals pair with almost anything (used by colour scoring later).
  final bool isNeutral;

  static ColorFamily? tryFromCode(String? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}

/// Optional style preferences chosen by the user (never inferred from photos).
enum StylePreference implements CodedEnum {
  casual('CASUAL'),
  classic('CLASSIC'),
  minimal('MINIMAL'),
  sporty('SPORTY'),
  streetwear('STREETWEAR'),
  elegant('ELEGANT'),
  bohemian('BOHEMIAN');

  const StylePreference(this.code);

  @override
  final String code;

  static StylePreference? tryFromCode(String? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}
