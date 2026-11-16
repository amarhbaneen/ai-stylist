import 'package:wardrobe_domain/wardrobe_domain.dart';

import 'outfit.dart';
import 'request.dart';
import 'templates.dart';

/// Hard constraints (FR-06): applied before any scoring and never
/// overridden by weights. Unknown attributes never make an item ineligible.
abstract final class HardConstraints {
  /// Whether [item] may fill [slot] for [request].
  static bool allows(ClothingItem item, Slot slot, OutfitRequest request) =>
      _status(item) &&
      item.attributes.category == slot.category &&
      _formality(item, request) &&
      _weather(item, slot, request.weather);

  /// Only ACTIVE items (CLAUDE.md rule 9).
  static bool _status(ClothingItem item) => item.isEligibleForOutfits;

  static bool _formality(ClothingItem item, OutfitRequest request) {
    final level = item.attributes.formality?.level;
    if (level == null) return true;
    return level >= request.minFormality && level <= request.maxFormality;
  }

  static bool _weather(ClothingItem item, Slot slot, WeatherContext? weather) {
    if (weather == null) return true;
    final a = item.attributes;
    // Items explicitly tagged only for other seasons are excluded.
    if (a.seasons.isNotEmpty &&
        a.seasons.intersection(weather.suitableSeasons).isEmpty) {
      return false;
    }
    if (weather.isHot) {
      if (a.warmth == Warmth.heavy) return false;
      if (slot == Slot.outerwear && a.warmth == Warmth.medium) return false;
    }
    return true;
  }

  /// Explains why [template] cannot be filled, one entry per required slot
  /// with no eligible item (REQUIREMENTS §6.4.7).
  static List<MissingRequirement> explainMissing(
    OutfitTemplate template,
    List<ClothingItem> wardrobe,
    OutfitRequest request,
    Map<Slot, List<ClothingItem>> eligible,
  ) {
    final required = template.requiredFor(
      cold: request.weather?.isCold ?? false,
    );
    final missing = <MissingRequirement>[];
    for (final slot in Slot.values) {
      if (!required.contains(slot)) continue;
      if ((eligible[slot] ?? const []).isNotEmpty) continue;
      final inCategory = wardrobe.where(
        (i) => _status(i) && i.attributes.category == slot.category,
      );
      final MissingReason reason;
      if (inCategory.isEmpty) {
        reason = MissingReason.noItems;
      } else if (!inCategory.any((i) => _formality(i, request))) {
        reason = MissingReason.notSuitableForOccasion;
      } else {
        reason = MissingReason.notSuitableForWeather;
      }
      missing.add(
        MissingRequirement(
          templateId: template.id,
          category: slot.category,
          reason: reason,
        ),
      );
    }
    return missing;
  }
}
