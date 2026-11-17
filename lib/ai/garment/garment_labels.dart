import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

/// One output of the `type` head, mapped to the app taxonomy.
@immutable
final class GarmentTypeLabel {
  const GarmentTypeLabel({
    required this.label,
    required this.category,
    this.subcategory,
  });

  /// Model label, for example `shirt_blouse`.
  final String label;
  final GarmentCategory category;

  /// `null` when the training data cannot tell types apart (for example
  /// "shirt, blouse" or "shoe"): the user picks the type.
  final GarmentSubcategory? subcategory;
}

/// The label table shipped next to a garment model (`labels.json` from
/// `training/`, schema version 1). Index `i` names output element `i`.
///
/// Parsing is strict: an unknown category, subcategory or pattern code, a
/// subcategory that belongs to another category, or a duplicate label
/// rejects the whole table, so the model is never run with a table it does
/// not match.
@immutable
final class GarmentLabels {
  GarmentLabels._(List<GarmentTypeLabel> types, List<GarmentPattern> patterns)
    : types = List.unmodifiable(types),
      patterns = List.unmodifiable(patterns);

  static const supportedSchema = 1;

  final List<GarmentTypeLabel> types;
  final List<GarmentPattern> patterns;

  /// Label → category code, for `OutputValidator`.
  Map<String, String> get categoryCodes => {
    for (final t in types) t.label: t.category.code,
  };

  /// Label → subcategory code; labels without a subcategory are left out,
  /// so their probability lowers the subcategory confidence honestly.
  Map<String, String> get subcategoryCodes => {
    for (final t in types)
      if (t.subcategory case final s?) t.label: s.code,
  };

  /// Pattern outputs are taxonomy codes already.
  Map<String, String> get patternCodes => {
    for (final p in patterns) p.code: p.code,
  };

  static GarmentLabels? tryParse(String text) {
    final Object? json;
    try {
      json = jsonDecode(text);
    } on FormatException {
      return null;
    }
    if (json is! Map<String, Object?> ||
        json['schemaVersion'] != supportedSchema) {
      return null;
    }
    final outputs = json['outputs'];
    if (outputs is! Map<String, Object?>) return null;
    final rawTypes = outputs['type'];
    final rawPatterns = outputs['pattern'];
    if (rawTypes is! List || rawPatterns is! List) return null;
    if (rawTypes.isEmpty || rawPatterns.isEmpty) return null;

    final types = <GarmentTypeLabel>[];
    for (final t in rawTypes) {
      final parsed = _type(t);
      if (parsed == null) return null;
      types.add(parsed);
    }
    final patterns = <GarmentPattern>[];
    for (final p in rawPatterns) {
      final pattern = p is String ? GarmentPattern.fromCode(p) : null;
      if (pattern == null || pattern == GarmentPattern.unknown) return null;
      patterns.add(pattern);
    }
    if (types.map((t) => t.label).toSet().length != types.length ||
        patterns.toSet().length != patterns.length) {
      return null;
    }
    return GarmentLabels._(types, patterns);
  }

  static GarmentTypeLabel? _type(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final label = json['label'];
    final categoryCode = json['category'];
    final subCode = json['subcategory'];
    if (label is! String || label.isEmpty || categoryCode is! String) {
      return null;
    }
    final category = GarmentCategory.fromCode(categoryCode);
    if (category == GarmentCategory.unknown) return null;
    GarmentSubcategory? sub;
    if (subCode != null) {
      sub = subCode is String ? GarmentSubcategory.tryFromCode(subCode) : null;
      if (sub == null || sub.category != category) return null;
    }
    return GarmentTypeLabel(label: label, category: category, subcategory: sub);
  }
}
