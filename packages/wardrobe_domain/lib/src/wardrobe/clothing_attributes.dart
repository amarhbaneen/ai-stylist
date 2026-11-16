import 'package:meta/meta.dart';

import '../core/app_failure.dart';
import '../core/set_equality.dart';
import '../taxonomy/taxonomy.dart';

/// Every user-editable attribute of a garment (REQUIREMENTS FR-03).
///
/// All fields except [category] are optional. Every field can be corrected by
/// the user, including values suggested by AI later (CLAUDE.md rule 8).
@immutable
final class ClothingAttributes {
  ClothingAttributes({
    this.category = GarmentCategory.unknown,
    this.subcategory,
    String? displayName,
    String? notes,
    this.primaryColor,
    Set<ColorFamily> secondaryColors = const {},
    this.pattern = GarmentPattern.unknown,
    Set<Season> seasons = const {},
    this.formality,
    this.fit = GarmentFit.unknown,
    String? brand,
    this.warmth,
  }) : displayName = _clean(displayName),
       notes = _clean(notes),
       brand = _clean(brand),
       secondaryColors = Set.unmodifiable(
         secondaryColors.where((c) => c != primaryColor),
       ),
       seasons = Set.unmodifiable(seasons);

  static const maxNameLength = 80;
  static const maxNotesLength = 500;
  static const maxBrandLength = 60;

  final GarmentCategory category;
  final GarmentSubcategory? subcategory;
  final String? displayName;
  final String? notes;
  final ColorFamily? primaryColor;

  /// Never contains [primaryColor].
  final Set<ColorFamily> secondaryColors;

  final GarmentPattern pattern;
  final Set<Season> seasons;
  final Formality? formality;
  final GarmentFit fit;
  final String? brand;
  final Warmth? warmth;

  /// Returns a failure describing the first problem, or `null` when the
  /// attributes are valid. When [forActivation] is true the item must have a
  /// known category so it can take part in outfit templates.
  ValidationFailure? validate({required bool forActivation}) {
    if (forActivation && category == GarmentCategory.unknown) {
      return const ValidationFailure('Choose a category before saving.');
    }
    final sub = subcategory;
    if (sub != null && sub.category != category) {
      return ValidationFailure(
        'Subcategory ${sub.code} does not belong to ${category.code}.',
      );
    }
    if ((displayName?.length ?? 0) > maxNameLength) {
      return const ValidationFailure('Name is too long.');
    }
    if ((notes?.length ?? 0) > maxNotesLength) {
      return const ValidationFailure('Notes are too long.');
    }
    if ((brand?.length ?? 0) > maxBrandLength) {
      return const ValidationFailure('Brand is too long.');
    }
    return null;
  }

  /// Trims text and turns blank strings into `null`.
  static String? _clean(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  @override
  bool operator ==(Object other) =>
      other is ClothingAttributes &&
      other.category == category &&
      other.subcategory == subcategory &&
      other.displayName == displayName &&
      other.notes == notes &&
      other.primaryColor == primaryColor &&
      setEquals(other.secondaryColors, secondaryColors) &&
      other.pattern == pattern &&
      setEquals(other.seasons, seasons) &&
      other.formality == formality &&
      other.fit == fit &&
      other.brand == brand &&
      other.warmth == warmth;

  @override
  int get hashCode => Object.hash(
    category,
    subcategory,
    displayName,
    notes,
    primaryColor,
    setHash(secondaryColors),
    pattern,
    setHash(seasons),
    formality,
    fit,
    brand,
    warmth,
  );
}
