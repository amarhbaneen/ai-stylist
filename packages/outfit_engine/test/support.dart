import 'package:wardrobe_domain/wardrobe_domain.dart';

final _t = DateTime.utc(2026, 11, 16);

/// Concise test-item builder.
ClothingItem item(
  String id,
  GarmentCategory category, {
  ColorFamily? color,
  Formality? formality,
  Warmth? warmth,
  Set<Season> seasons = const {},
  GarmentPattern pattern = GarmentPattern.solid,
  GarmentSubcategory? sub,
  GarmentFit fit = GarmentFit.unknown,
  ItemStatus status = ItemStatus.active,
}) => ClothingItem(
  id: id,
  status: status,
  createdAt: _t,
  updatedAt: _t,
  attributes: ClothingAttributes(
    category: category,
    subcategory: sub,
    primaryColor: color,
    formality: formality,
    warmth: warmth,
    seasons: seasons,
    pattern: pattern,
    fit: fit,
  ),
);

ClothingItem top(String id, {ColorFamily? color, Formality? f, Warmth? w}) =>
    item(id, GarmentCategory.top, color: color, formality: f, warmth: w);

ClothingItem bottom(String id, {ColorFamily? color, Formality? f}) =>
    item(id, GarmentCategory.bottom, color: color, formality: f);

ClothingItem shoes(
  String id, {
  ColorFamily? color,
  Formality? f,
  GarmentSubcategory? sub,
}) => item(id, GarmentCategory.footwear, color: color, formality: f, sub: sub);

ClothingItem layer(String id, {ColorFamily? color, Formality? f, Warmth? w}) =>
    item(id, GarmentCategory.outerwear, color: color, formality: f, warmth: w);

/// A small, sensible wardrobe used by many tests.
List<ClothingItem> basicWardrobe() => [
  top('t-white', color: ColorFamily.white, f: Formality.casual),
  top('t-red', color: ColorFamily.red, f: Formality.casual),
  bottom('b-navy', color: ColorFamily.navy, f: Formality.casual),
  bottom('b-green', color: ColorFamily.green, f: Formality.casual),
  shoes('s-white', color: ColorFamily.white, f: Formality.casual),
];
