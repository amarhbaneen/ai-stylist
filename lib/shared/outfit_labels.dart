import 'package:outfit_engine/outfit_engine.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

/// English UI text for engine concepts (single place to localise).
abstract final class OutfitLabels {
  static String occasion(Occasion o) => switch (o) {
    Occasion.casual => 'Casual',
    Occasion.smartCasual => 'Smart casual',
    Occasion.business => 'Business',
    Occasion.formal => 'Formal',
    Occasion.custom => 'Custom',
  };

  static String slot(Slot s) => switch (s) {
    Slot.top => 'Top',
    Slot.bottom => 'Bottom',
    Slot.onePiece => 'One-piece',
    Slot.outerwear => 'Layer',
    Slot.footwear => 'Shoes',
  };

  static String component(ScoreComponent c) => switch (c) {
    ScoreComponent.color => 'Colour',
    ScoreComponent.style => 'Style',
    ScoreComponent.occasion => 'Occasion',
    ScoreComponent.weather => 'Weather',
    ScoreComponent.preference => 'Your preferences',
    ScoreComponent.variety => 'Variety',
  };

  static String reason(ReasonCode r) => switch (r) {
    ReasonCode.neutralBase => 'Built on a neutral base',
    ReasonCode.monochrome => 'A tonal, single-colour look',
    ReasonCode.analogousColors => 'Neighbouring colours that blend',
    ReasonCode.complementaryColors => 'Bold, contrasting colours',
    ReasonCode.colorClash => 'Some colours compete',
    ReasonCode.formalityMatch => 'Right formality for the occasion',
    ReasonCode.formalityMixed => 'Mixes dressy and casual pieces',
    ReasonCode.patternMix => 'Mixes several patterns',
    ReasonCode.styleMatch => 'Matches the style you chose',
    ReasonCode.weatherLayered => 'Layered for cooler weather',
    ReasonCode.weatherWarmthMatch => 'Right warmth for the weather',
    ReasonCode.weatherRainFootwear => 'Rain-ready shoes',
    ReasonCode.weatherNotConsidered => 'Weather not considered',
    ReasonCode.favoredColor => 'Uses colours you like',
    ReasonCode.avoidedColor => 'Includes a colour you avoid',
    ReasonCode.learnedLike => 'Similar to outfits you liked',
    ReasonCode.freshItems => 'Pieces not suggested recently',
    ReasonCode.recentlySuggested => 'Suggested recently',
  };

  static String feedbackReason(FeedbackReason r) => switch (r) {
    FeedbackReason.notMyStyle => 'Not my style',
    FeedbackReason.colorsClash => 'Colours don\'t work',
    FeedbackReason.tooFormal => 'Too formal',
    FeedbackReason.tooCasual => 'Too casual',
    FeedbackReason.wrongForWeather => 'Wrong for the weather',
    FeedbackReason.wornRecently => 'Wore it recently',
    FeedbackReason.other => 'Something else',
  };

  /// Whether a reason is a caveat (shown with a different icon).
  static bool isCaveat(ReasonCode r) => const {
    ReasonCode.colorClash,
    ReasonCode.formalityMixed,
    ReasonCode.patternMix,
    ReasonCode.avoidedColor,
    ReasonCode.recentlySuggested,
  }.contains(r);

  /// Plain-language fix for a missing requirement (REQUIREMENTS §6.4.7).
  static String missing(MissingRequirement m, Occasion forOccasion) {
    final (one, many) = switch (m.category) {
      GarmentCategory.top => ('a top', 'tops'),
      GarmentCategory.bottom => ('trousers, jeans or a skirt', 'bottoms'),
      GarmentCategory.onePiece => ('a dress or jumpsuit', 'dresses'),
      GarmentCategory.outerwear => ('a jacket or coat', 'jackets or coats'),
      GarmentCategory.footwear => ('shoes', 'shoes'),
      GarmentCategory.accessory => ('an accessory', 'accessories'),
      GarmentCategory.unknown => ('an item', 'items'),
    };
    return switch (m.reason) {
      MissingReason.noItems => 'Add $one',
      MissingReason.notSuitableForOccasion =>
        'None of your $many suit ${occasion(forOccasion).toLowerCase()}: '
            'add $one, or edit an item\'s formality',
      MissingReason.notSuitableForWeather =>
        'None of your $many suit this weather: add $one',
    };
  }
}
