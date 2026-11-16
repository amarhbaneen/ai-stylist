import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../wardrobe/presentation/clothing_attributes_form.dart';

/// Prefills the review form from [analysis] according to [policy] (D-09).
///
/// Rules:
/// - only fields the user has not touched and that are still empty;
/// - only suggestions at the prefill or confirm level (hints are offered as
///   chips, never applied);
/// - secondary colours are never prefilled: they are offered as chips.
///
/// Returns the attributes that were prefilled.
Set<AnalyzedAttribute> applySuggestions(
  AttributesDraft draft,
  ClothingAnalysis analysis,
  ConfidencePolicy policy,
) {
  final applied = <AnalyzedAttribute>{};
  final primary = analysis.primaryColor;
  if (primary != null &&
      policy.levelOf(primary.confidence) != SuggestionLevel.hint &&
      !draft.touched.contains(AnalyzedAttribute.primaryColor) &&
      draft.primaryColor == null) {
    draft.primaryColor = primary.value;
    draft.secondaryColors.remove(primary.value);
    applied.add(AnalyzedAttribute.primaryColor);
  }
  return applied;
}
