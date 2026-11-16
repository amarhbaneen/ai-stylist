import 'package:meta/meta.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import 'score_weights.dart';
import 'templates.dart';

/// Why an outfit scored as it did. Codes are stable for storage; the UI
/// turns them into sentences.
enum ReasonCode implements CodedEnum {
  neutralBase('NEUTRAL_BASE'),
  monochrome('MONOCHROME'),
  analogousColors('ANALOGOUS_COLORS'),
  complementaryColors('COMPLEMENTARY_COLORS'),
  colorClash('COLOR_CLASH'),
  formalityMatch('FORMALITY_MATCH'),
  formalityMixed('FORMALITY_MIXED'),
  patternMix('PATTERN_MIX'),
  styleMatch('STYLE_MATCH'),
  weatherLayered('WEATHER_LAYERED'),
  weatherWarmthMatch('WEATHER_WARMTH_MATCH'),
  weatherRainFootwear('WEATHER_RAIN_FOOTWEAR'),
  weatherNotConsidered('WEATHER_NOT_CONSIDERED'),
  favoredColor('FAVORED_COLOR'),
  avoidedColor('AVOIDED_COLOR'),
  learnedLike('LEARNED_LIKE'),
  freshItems('FRESH_ITEMS'),
  recentlySuggested('RECENTLY_SUGGESTED');

  const ReasonCode(this.code);

  @override
  final String code;

  static ReasonCode? tryFromCode(String code) {
    for (final r in values) {
      if (r.code == code) return r;
    }
    return null;
  }
}

/// One garment placed in a slot.
@immutable
final class OutfitPiece {
  const OutfitPiece(this.slot, this.itemId);

  final Slot slot;
  final String itemId;

  @override
  bool operator ==(Object other) =>
      other is OutfitPiece && other.slot == slot && other.itemId == itemId;

  @override
  int get hashCode => Object.hash(slot, itemId);
}

/// A validated outfit suggestion: real ACTIVE item IDs, a total score in
/// [0, 1], the per-component breakdown and reason codes (FR-06, FR-07).
@immutable
final class Outfit {
  Outfit({
    required this.templateId,
    required List<OutfitPiece> pieces,
    required this.totalScore,
    required Map<ScoreComponent, double> breakdown,
    required Map<ScoreComponent, double> weights,
    required List<ReasonCode> reasons,
    required this.weatherConsidered,
  }) : pieces = List.unmodifiable(pieces),
       breakdown = Map.unmodifiable(breakdown),
       weights = Map.unmodifiable(weights),
       reasons = List.unmodifiable(reasons);

  final String templateId;
  final List<OutfitPiece> pieces;
  final double totalScore;

  /// Each component's score in [0, 1]. Weather is absent when not considered.
  final Map<ScoreComponent, double> breakdown;

  /// Normalised weights that produced [totalScore].
  final Map<ScoreComponent, double> weights;
  final List<ReasonCode> reasons;
  final bool weatherConsidered;

  Set<String> get itemIds => {for (final p in pieces) p.itemId};

  /// Order-independent identity of the combination (used for de-duplication
  /// and to avoid repeating recent suggestions).
  String get signature => signatureOf(itemIds);

  static String signatureOf(Iterable<String> itemIds) =>
      (itemIds.toList()..sort()).join('+');
}

/// Why no outfit could be made for a template (REQUIREMENTS §6.4.7).
enum MissingReason {
  /// The wardrobe has no ACTIVE item in this category.
  noItems,

  /// Items exist, but none fit the occasion's formality.
  notSuitableForOccasion,

  /// Items exist, but none suit the weather.
  notSuitableForWeather,
}

@immutable
final class MissingRequirement {
  const MissingRequirement({
    required this.templateId,
    required this.category,
    required this.reason,
  });

  final String templateId;
  final GarmentCategory category;
  final MissingReason reason;

  @override
  bool operator ==(Object other) =>
      other is MissingRequirement &&
      other.templateId == templateId &&
      other.category == category &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(templateId, category, reason);
}

/// Engine output: zero to [OutfitRequest.count] outfits, never padded.
@immutable
final class GenerationResult {
  GenerationResult({
    required List<Outfit> outfits,
    required List<MissingRequirement> missing,
    required this.candidatesConsidered,
  }) : outfits = List.unmodifiable(outfits),
       missing = List.unmodifiable(missing);

  final List<Outfit> outfits;

  /// Filled when a template could not be completed; the UI suggests what to
  /// add. Only meaningful to show when [outfits] is empty or short.
  final List<MissingRequirement> missing;
  final int candidatesConsidered;
}
