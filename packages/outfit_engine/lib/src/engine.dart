import 'package:wardrobe_domain/wardrobe_domain.dart';

import 'constraints.dart';
import 'outfit.dart';
import 'request.dart';
import 'score_weights.dart';
import 'scoring/scorers.dart';
import 'templates.dart';

/// Deterministic outfit generator (DECISIONS D-10). Pure Dart.
///
/// Pipeline: ACTIVE items → hard constraints per slot → keep the strongest
/// [maxPerSlot] items per slot → enumerate template combinations → score
/// the six components → de-duplicate by signature → pick up to
/// [OutfitRequest.count] varied outfits. Never fabricates an outfit.
final class OutfitEngine {
  OutfitEngine({
    ScoreWeights? weights,
    this.templates = OutfitTemplate.all,
    this.maxPerSlot = 10,
    this.overlapPenalty = 0.04,
  }) : weights = weights ?? ScoreWeights.defaults();

  final ScoreWeights weights;
  final List<OutfitTemplate> templates;

  /// Bounds the search: at most maxPerSlot^3 × (maxPerSlot + 1) candidates
  /// per template, whatever the wardrobe size.
  final int maxPerSlot;

  /// Score penalty per item shared with an already chosen outfit, so the
  /// results are not three near-copies.
  final double overlapPenalty;

  GenerationResult generate({
    required List<ClothingItem> wardrobe,
    required OutfitRequest request,
    StyleProfile? profile,
    LearnedPreferences? learned,
  }) {
    final prefs = profile ?? StyleProfile.empty;
    final learnedPrefs = learned ?? LearnedPreferences.none;
    final weather = request.weather;
    final normalized = weights.normalized(weatherAvailable: weather != null);
    final styles = request.style != null
        ? {request.style!}
        : prefs.preferredStyles;

    // Stable order: everything downstream is deterministic.
    final active = wardrobe.where((i) => i.isEligibleForOutfits).toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    final eligible = <Slot, List<ClothingItem>>{
      for (final slot in Slot.values)
        slot: _shortlist(
          active.where((i) => HardConstraints.allows(i, slot, request)),
          request,
          prefs,
          learnedPrefs,
        ),
    };

    final missing = <MissingRequirement>[];
    final bySignature = <String, Outfit>{};
    var considered = 0;

    for (final template in templates) {
      final required = template.requiredFor(cold: weather?.isCold ?? false);
      if (required.any((s) => eligible[s]!.isEmpty)) {
        missing.addAll(
          HardConstraints.explainMissing(template, active, request, eligible),
        );
        continue;
      }
      final optional = template.optional.difference(required);
      for (final pieces in _combinations(required, optional, eligible)) {
        considered++;
        final outfit = _score(
          template,
          pieces,
          request,
          prefs,
          learnedPrefs,
          styles,
          normalized,
        );
        final existing = bySignature[outfit.signature];
        if (existing == null || outfit.totalScore > existing.totalScore) {
          bySignature[outfit.signature] = outfit;
        }
      }
    }

    return GenerationResult(
      outfits: _select(bySignature.values.toList(), request),
      missing: missing,
      candidatesConsidered: considered,
    );
  }

  /// Eligible items for one slot, best first, capped at [maxPerSlot].
  List<ClothingItem> _shortlist(
    Iterable<ClothingItem> items,
    OutfitRequest request,
    StyleProfile profile,
    LearnedPreferences learned,
  ) {
    double rank(ClothingItem i) {
      final w = request.weather;
      final parts = [
        (itemOccasionScore(i, request), 0.4),
        (itemPreferenceScore(i, profile, learned), 0.3),
        (itemVarietyScore(i, request), 0.1),
        if (w != null) (itemWeatherScore(i, w), 0.2),
      ];
      final total = parts.fold<double>(0, (s, p) => s + p.$2);
      return parts.fold<double>(0, (s, p) => s + p.$1 * p.$2) / total;
    }

    final ranked = [for (final i in items) (i, rank(i))]
      ..sort((a, b) {
        final c = b.$2.compareTo(a.$2);
        return c != 0 ? c : a.$1.id.compareTo(b.$1.id);
      });
    return [for (final (i, _) in ranked.take(maxPerSlot)) i];
  }

  /// Cartesian product of required slots, each optionally extended by one
  /// item per optional slot.
  Iterable<Pieces> _combinations(
    Set<Slot> required,
    Set<Slot> optional,
    Map<Slot, List<ClothingItem>> eligible,
  ) sync* {
    final slots = Slot.values.where(required.contains).toList();
    Iterable<Pieces> build(int index, Pieces acc) sync* {
      if (index == slots.length) {
        yield* _withOptional(
          acc,
          Slot.values.where(optional.contains),
          eligible,
        );
        return;
      }
      final slot = slots[index];
      for (final item in eligible[slot]!) {
        yield* build(index + 1, {...acc, slot: item});
      }
    }

    yield* build(0, const {});
  }

  Iterable<Pieces> _withOptional(
    Pieces base,
    Iterable<Slot> optional,
    Map<Slot, List<ClothingItem>> eligible,
  ) sync* {
    if (optional.isEmpty) {
      yield base;
      return;
    }
    final slot = optional.first;
    final rest = optional.skip(1);
    yield* _withOptional(base, rest, eligible);
    for (final item in eligible[slot]!) {
      yield* _withOptional({...base, slot: item}, rest, eligible);
    }
  }

  Outfit _score(
    OutfitTemplate template,
    Pieces pieces,
    OutfitRequest request,
    StyleProfile profile,
    LearnedPreferences learned,
    Set<StylePreference> styles,
    Map<ScoreComponent, double> weights,
  ) {
    final components = <ScoreComponent, ComponentScore>{
      ScoreComponent.color: scoreColor(pieces),
      ScoreComponent.style: scoreStyle(pieces, styles),
      ScoreComponent.occasion: scoreOccasion(pieces, request),
      if (request.weather case final w?)
        ScoreComponent.weather: scoreWeather(pieces, w),
      ScoreComponent.preference: scorePreference(pieces, profile, learned),
      ScoreComponent.variety: scoreVariety(pieces, request),
    };
    var total = 0.0;
    final reasons = <ReasonCode>{};
    for (final MapEntry(key: c, value: (score, why)) in components.entries) {
      total += (weights[c] ?? 0) * score;
      reasons.addAll(why);
    }
    if (request.weather == null) reasons.add(ReasonCode.weatherNotConsidered);

    return Outfit(
      templateId: template.id,
      pieces: [
        for (final slot in Slot.values)
          if (pieces[slot] case final item?) OutfitPiece(slot, item.id),
      ],
      totalScore: total.clamp(0.0, 1.0),
      breakdown: {
        for (final MapEntry(key: c, value: (s, _)) in components.entries) c: s,
      },
      weights: weights,
      reasons: ReasonCode.values.where(reasons.contains).toList(),
      weatherConsidered: request.weather != null,
    );
  }

  /// Greedy, deterministic pick: best adjusted score first, penalising
  /// overlap with outfits already chosen. Recently suggested combinations
  /// are skipped where possible and used only if nothing else is valid.
  List<Outfit> _select(List<Outfit> candidates, OutfitRequest request) {
    int byScore(Outfit a, Outfit b) {
      final c = b.totalScore.compareTo(a.totalScore);
      return c != 0 ? c : a.signature.compareTo(b.signature);
    }

    final fresh =
        candidates
            .where((o) => !request.excludedSignatures.contains(o.signature))
            .toList()
          ..sort(byScore);
    final recent =
        candidates
            .where((o) => request.excludedSignatures.contains(o.signature))
            .toList()
          ..sort(byScore);

    final chosen = <Outfit>[];
    for (final pool in [fresh, recent]) {
      final remaining = [...pool];
      while (chosen.length < request.count && remaining.isNotEmpty) {
        Outfit? best;
        var bestScore = double.negativeInfinity;
        for (final o in remaining) {
          final shared = chosen.fold<int>(
            0,
            (n, c) => n + c.itemIds.intersection(o.itemIds).length,
          );
          final adjusted = o.totalScore - overlapPenalty * shared;
          if (adjusted > bestScore) {
            bestScore = adjusted;
            best = o;
          }
        }
        remaining.remove(best);
        chosen.add(identical(pool, recent) ? _markRecent(best!) : best!);
      }
    }
    return chosen;
  }

  Outfit _markRecent(Outfit o) => Outfit(
    templateId: o.templateId,
    pieces: o.pieces,
    totalScore: o.totalScore,
    breakdown: o.breakdown,
    weights: o.weights,
    reasons: [...o.reasons, ReasonCode.recentlySuggested],
    weatherConsidered: o.weatherConsidered,
  );
}
