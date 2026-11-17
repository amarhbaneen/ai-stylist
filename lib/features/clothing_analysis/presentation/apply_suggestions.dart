import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../wardrobe/presentation/clothing_attributes_form.dart';

/// Prefills the review form from [analysis] according to [policy] (D-09).
///
/// Rules:
/// - only fields the user has not touched and that are still empty;
/// - only suggestions at the prefill or confirm level (hints are offered as
///   chips, never applied);
/// - a type is only prefilled when it belongs to the form's category;
/// - secondary colours are never prefilled: they are offered as chips.
///
/// Returns the attributes that were prefilled.
Set<AnalyzedAttribute> applySuggestions(
  AttributesDraft draft,
  ClothingAnalysis analysis,
  ConfidencePolicy policy,
) {
  final applied = <AnalyzedAttribute>{};
  bool usable(Suggestion<Object?>? s, AnalyzedAttribute a) =>
      s != null &&
      policy.levelOf(s.confidence) != SuggestionLevel.hint &&
      !draft.touched.contains(a);

  final primary = analysis.primaryColor;
  if (usable(primary, AnalyzedAttribute.primaryColor) &&
      draft.primaryColor == null) {
    draft.primaryColor = primary!.value;
    draft.secondaryColors.remove(primary.value);
    applied.add(AnalyzedAttribute.primaryColor);
  }

  final category = analysis.category;
  if (usable(category, AnalyzedAttribute.category) &&
      draft.category == GarmentCategory.unknown) {
    draft.category = category!.value;
    if (draft.subcategory?.category != draft.category) draft.subcategory = null;
    applied.add(AnalyzedAttribute.category);
  }

  final sub = analysis.subcategory;
  if (usable(sub, AnalyzedAttribute.subcategory) &&
      draft.subcategory == null &&
      sub!.value.category == draft.category) {
    draft.subcategory = sub.value;
    applied.add(AnalyzedAttribute.subcategory);
  }

  final pattern = analysis.pattern;
  if (usable(pattern, AnalyzedAttribute.pattern) &&
      draft.pattern == GarmentPattern.unknown) {
    draft.pattern = pattern!.value;
    applied.add(AnalyzedAttribute.pattern);
  }
  return applied;
}
