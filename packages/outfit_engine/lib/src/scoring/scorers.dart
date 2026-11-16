import 'dart:math' as math;

import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../learner.dart';
import '../outfit.dart';
import '../request.dart';
import '../templates.dart';
import 'color_harmony.dart';

/// One component's score in [0, 1] plus the reasons behind it.
typedef ComponentScore = (double, Set<ReasonCode>);

/// A candidate's garments, by slot.
typedef Pieces = Map<Slot, ClothingItem>;

double _mean(Iterable<double> values) {
  var sum = 0.0, n = 0;
  for (final v in values) {
    sum += v;
    n++;
  }
  return n == 0 ? 0 : sum / n;
}

// ------------------------------------------------------------------ colour

ComponentScore scoreColor(Pieces pieces) =>
    colorScore([for (final i in pieces.values) i.attributes.primaryColor]);

// ---------------------------------------------------------------- occasion

/// How close one item's formality is to the target; unknown is neutral.
double itemOccasionScore(ClothingItem item, OutfitRequest request) {
  final level = item.attributes.formality?.level;
  if (level == null) return 0.6;
  return 1 - (level - request.targetFormality).abs() / 4;
}

ComponentScore scoreOccasion(Pieces pieces, OutfitRequest request) {
  final s = _mean(pieces.values.map((i) => itemOccasionScore(i, request)));
  return (s, {if (s >= 0.85) ReasonCode.formalityMatch});
}

// ------------------------------------------------------------------- style

/// Affinity of one item to a style, 0–1. Items carry no style tag, so style
/// is read from formality, pattern, colour and type (explainable proxies).
double styleAffinity(ClothingItem item, StylePreference style) {
  final a = item.attributes;
  final f = a.formality?.level;
  final solid = a.pattern == GarmentPattern.solid;
  final neutral = a.primaryColor?.isNeutral ?? false;
  final sneakers = a.subcategory == GarmentSubcategory.sneakers;
  switch (style) {
    case StylePreference.casual:
      return f == null ? 0.7 : (f <= 3 ? 1 : 0.4);
    case StylePreference.classic:
      final classicPattern = {
        GarmentPattern.solid,
        GarmentPattern.striped,
        GarmentPattern.checked,
        GarmentPattern.unknown,
      }.contains(a.pattern);
      return (f != null && f >= 3 && f <= 4 && classicPattern) ? 1 : 0.5;
    case StylePreference.minimal:
      if (solid && neutral) return 1;
      return solid ? 0.8 : 0.3;
    case StylePreference.sporty:
      return (sneakers || (f != null && f <= 2)) ? 1 : 0.4;
    case StylePreference.streetwear:
      if (sneakers ||
          a.subcategory == GarmentSubcategory.hoodie ||
          a.pattern == GarmentPattern.graphic) {
        return 1;
      }
      return (f != null && f <= 2) ? 0.7 : 0.3;
    case StylePreference.elegant:
      if (f == null) return 0.5;
      return f >= 4 ? 1 : (f == 3 ? 0.6 : 0.2);
    case StylePreference.bohemian:
      final earthy = {
        ColorFamily.beige,
        ColorFamily.brown,
        ColorFamily.olive,
      }.contains(a.primaryColor);
      return (a.pattern == GarmentPattern.floral || earthy) ? 1 : 0.5;
  }
}

/// Coherence of the outfit itself (formality spread, pattern mixing) plus,
/// when styles are given, affinity to the best-matching one.
ComponentScore scoreStyle(Pieces pieces, Set<StylePreference> styles) {
  final reasons = <ReasonCode>{};
  final levels = [
    for (final i in pieces.values)
      if (i.attributes.formality case final f?) f.level,
  ];
  final spread = levels.length < 2
      ? 0
      : levels.reduce(math.max) - levels.reduce(math.min);
  final coherence = switch (spread) {
    0 => 1.0,
    1 => 0.85,
    2 => 0.55,
    _ => 0.25,
  };
  if (spread >= 2) reasons.add(ReasonCode.formalityMixed);

  final patterned = pieces.values
      .where(
        (i) => !{
          GarmentPattern.solid,
          GarmentPattern.unknown,
        }.contains(i.attributes.pattern),
      )
      .length;
  final pattern = patterned <= 1 ? 1.0 : (patterned == 2 ? 0.6 : 0.3);
  if (patterned >= 2) reasons.add(ReasonCode.patternMix);

  final parts = [coherence, pattern];
  if (styles.isNotEmpty) {
    final affinity = styles
        .map((s) => _mean(pieces.values.map((i) => styleAffinity(i, s))))
        .reduce(math.max);
    parts.add(affinity);
    if (affinity >= 0.8) reasons.add(ReasonCode.styleMatch);
  }
  return (_mean(parts), reasons);
}

// ----------------------------------------------------------------- weather

/// Slot importance for warmth (the layer and top matter most).
const _warmthWeight = <Slot, double>{
  Slot.outerwear: 1,
  Slot.top: 1,
  Slot.onePiece: 1,
  Slot.bottom: 0.6,
  Slot.footwear: 0.4,
};

double itemWeatherScore(ClothingItem item, WeatherContext weather) {
  final w = item.attributes.warmth?.level;
  if (w == null) return 0.6;
  return (1 - (w - weather.idealWarmth).abs() / 2).clamp(0.0, 1.0);
}

ComponentScore scoreWeather(Pieces pieces, WeatherContext weather) {
  final reasons = <ReasonCode>{};
  var sum = 0.0, weights = 0.0;
  for (final MapEntry(key: slot, value: item) in pieces.entries) {
    final w = _warmthWeight[slot]!;
    sum += itemWeatherScore(item, weather) * w;
    weights += w;
  }
  var score = sum / weights;
  if (score >= 0.8) reasons.add(ReasonCode.weatherWarmthMatch);

  if (weather.temperatureC < 18 && pieces.containsKey(Slot.outerwear)) {
    score += 0.1;
    reasons.add(ReasonCode.weatherLayered);
  }
  if (weather.precipitation) {
    final shoe = pieces[Slot.footwear]?.attributes.subcategory;
    if (shoe == GarmentSubcategory.sandals) {
      score -= 0.3;
    } else if (shoe == GarmentSubcategory.boots) {
      score += 0.1;
      reasons.add(ReasonCode.weatherRainFootwear);
    }
  }
  return (score.clamp(0.0, 1.0), reasons);
}

// -------------------------------------------------------------- preference

double itemPreferenceScore(
  ClothingItem item,
  StyleProfile profile,
  LearnedPreferences learned,
) {
  final a = item.attributes;
  final colors = {?a.primaryColor, ...a.secondaryColors};
  var s = 0.5;
  if (colors.any(profile.favoredColors.contains)) s += 0.3;
  if (colors.any(profile.avoidedColors.contains)) s -= 0.4;
  if (profile.fit != null && a.fit == profile.fit) s += 0.1;
  if (profile.formality case final f? when a.formality != null) {
    s += 0.1 * (1 - (a.formality!.level - f.level).abs() / 4);
  }
  // Learned affinities are kept separate from explicit preferences (D-11)
  // and only nudge the score.
  s += learned.of('item:${item.id}');
  if (a.primaryColor case final c?) s += learned.of('color:${c.code}');
  return s.clamp(0.0, 1.0);
}

ComponentScore scorePreference(
  Pieces pieces,
  StyleProfile profile,
  LearnedPreferences learned,
) {
  final reasons = <ReasonCode>{};
  for (final i in pieces.values) {
    final a = i.attributes;
    final colors = {?a.primaryColor, ...a.secondaryColors};
    if (colors.any(profile.favoredColors.contains)) {
      reasons.add(ReasonCode.favoredColor);
    }
    if (colors.any(profile.avoidedColors.contains)) {
      reasons.add(ReasonCode.avoidedColor);
    }
  }
  // Learned affinity for garments worn *together* (pair keys, D-11).
  final ids = pieces.values.map((i) => i.id).toList()..sort();
  final pairWeights = [
    for (var a = 0; a < ids.length; a++)
      for (var b = a + 1; b < ids.length; b++)
        learned.of(PreferenceLearner.pairKey(ids[a], ids[b])),
  ];
  final pairAffinity = _mean(pairWeights);

  final learnedSum =
      pieces.values.fold<double>(0, (s, i) => s + learned.of('item:${i.id}')) +
      pairWeights.fold<double>(0, (s, w) => s + w);
  if (learnedSum > 0.05) reasons.add(ReasonCode.learnedLike);
  final score =
      _mean(
        pieces.values.map((i) => itemPreferenceScore(i, profile, learned)),
      ) +
      pairAffinity;
  return (score.clamp(0.0, 1.0), reasons);
}

// ----------------------------------------------------------------- variety

double itemVarietyScore(ClothingItem item, OutfitRequest request) =>
    1 / (1 + (request.recentItemUse[item.id] ?? 0));

ComponentScore scoreVariety(Pieces pieces, OutfitRequest request) {
  final s = _mean(pieces.values.map((i) => itemVarietyScore(i, request)));
  return (s, {if (s == 1) ReasonCode.freshItems});
}
