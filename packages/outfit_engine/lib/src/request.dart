import 'package:meta/meta.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

/// Occasions offered to the user (REQUIREMENTS §6.4).
enum Occasion implements CodedEnum {
  casual('CASUAL', target: 2, min: 1, max: 3),
  smartCasual('SMART_CASUAL', target: 3, min: 2, max: 4),
  business('BUSINESS', target: 4, min: 3, max: 5),
  formal('FORMAL', target: 5, min: 4, max: 5),

  /// The user picks the formality; the window is that level ±1.
  custom('CUSTOM', target: 3, min: 1, max: 5);

  const Occasion(
    this.code, {
    required this.target,
    required this.min,
    required this.max,
  });

  @override
  final String code;

  /// Ideal formality level (1–5).
  final int target;

  /// Allowed formality window for items whose formality is known.
  final int min;
  final int max;

  static Occasion fromCode(String? code) =>
      enumFromCode(values, code, fallback: Occasion.casual);
}

/// Weather the user entered (manual, offline) or fetched with consent (M7).
@immutable
final class WeatherContext {
  const WeatherContext({
    required this.temperatureC,
    this.precipitation = false,
  });

  final double temperatureC;
  final bool precipitation;

  /// Below this, an outfit must include outerwear (template modifier).
  static const coldThreshold = 12.0;

  /// At or above this, heavy garments are excluded.
  static const hotThreshold = 28.0;

  bool get isCold => temperatureC < coldThreshold;
  bool get isHot => temperatureC >= hotThreshold;

  /// Ideal garment warmth for this temperature (1 light – 3 heavy).
  double get idealWarmth {
    if (temperatureC < 10) return 3;
    if (temperatureC < 18) return 2;
    if (temperatureC < 24) return 1.5;
    return 1;
  }

  /// Seasons that suit this temperature, for excluding clearly
  /// unsuitable items (e.g. winter-only items on a hot day).
  Set<Season> get suitableSeasons {
    if (temperatureC < 10) return {Season.winter, Season.autumn};
    if (temperatureC < 18) {
      return {Season.autumn, Season.spring, Season.winter};
    }
    if (temperatureC < 24) {
      return {Season.spring, Season.autumn, Season.summer};
    }
    return {Season.summer, Season.spring};
  }

  Map<String, Object> toJson() => {
    'temperatureC': temperatureC,
    'precipitation': precipitation,
  };
}

/// Everything the engine needs to know about what the user asked for.
@immutable
final class OutfitRequest {
  OutfitRequest({
    required this.occasion,
    this.customFormality,
    this.style,
    this.weather,
    int count = 3,
    Set<String> excludedSignatures = const {},
    Map<String, int> recentItemUse = const {},
  }) : count = count.clamp(1, maxCount),
       excludedSignatures = Set.unmodifiable(excludedSignatures),
       recentItemUse = Map.unmodifiable(recentItemUse);

  static const maxCount = 3;

  final Occasion occasion;

  /// Required meaning for [Occasion.custom]; ignored otherwise.
  final Formality? customFormality;

  /// Optional requested style for this outfit.
  final StylePreference? style;

  /// `null` means weather is not considered (and not penalised).
  final WeatherContext? weather;

  /// Up to three results; fewer are returned when fewer are valid.
  final int count;

  /// Signatures of recently suggested outfits to avoid repeating.
  final Set<String> excludedSignatures;

  /// How often each item appeared in recent suggestions (for variety).
  final Map<String, int> recentItemUse;

  int get targetFormality => occasion == Occasion.custom
      ? (customFormality?.level ?? Occasion.custom.target)
      : occasion.target;

  int get minFormality => occasion == Occasion.custom
      ? (targetFormality - 1).clamp(1, 5)
      : occasion.min;

  int get maxFormality => occasion == Occasion.custom
      ? (targetFormality + 1).clamp(1, 5)
      : occasion.max;

  Map<String, Object?> toJson() => {
    'occasion': occasion.code,
    'customFormality': customFormality?.level,
    'style': style?.code,
    'weather': weather?.toJson(),
    'count': count,
  };
}

/// Learned (not explicit) preference weights from feedback (D-11, M6).
/// Keys look like `item:<id>` or `color:<CODE>`; values are in [-0.3, 0.3].
@immutable
final class LearnedPreferences {
  LearnedPreferences([Map<String, double> weights = const {}])
    : weights = Map.unmodifiable(weights);

  static final none = LearnedPreferences();

  final Map<String, double> weights;

  double of(String key) => weights[key] ?? 0;
}
