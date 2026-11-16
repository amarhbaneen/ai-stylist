import 'package:wardrobe_domain/wardrobe_domain.dart';

import 'feedback.dart';
import 'request.dart';

/// Turns feedback into bounded, explainable preference weights (D-11).
///
/// - **Deterministic:** the result depends only on the events, applied in
///   (createdAt, id) order; input order does not matter.
/// - **Latest opinion wins:** only the newest event per outfit counts, so
///   changing a like to a dislike does not double-count.
/// - **Bounded:** every weight is clamped to ±[maxWeight] after each step.
/// - **Explainable:** three kinds of key, each a simple counter:
///   `item:<id>`, `color:<CODE>` and `pair:<idA>+<idB>`.
/// - **Separate:** explicit preferences are never read or written here.
final class PreferenceLearner {
  const PreferenceLearner();

  static const maxWeight = 0.30;
  static const itemStep = 0.05;
  static const colorStep = 0.03;
  static const pairStep = 0.05;

  /// [colors] maps item IDs to their main colour (`null`/missing = unknown,
  /// e.g. a garment that has since been deleted).
  LearnedPreferences learn(
    Iterable<FeedbackEvent> events,
    Map<String, ColorFamily?> colors,
  ) {
    // Latest event per outfit.
    final latest = <String, FeedbackEvent>{};
    for (final e in events) {
      final current = latest[e.feedback.outfitId];
      if (current == null || _compare(e, current) > 0) {
        latest[e.feedback.outfitId] = e;
      }
    }
    final ordered = latest.values.toList()..sort(_compare);

    final weights = <String, double>{};
    void bump(String key, double delta) {
      if (delta == 0) return;
      weights[key] = ((weights[key] ?? 0) + delta).clamp(-maxWeight, maxWeight);
    }

    for (final e in ordered) {
      final (item, color, pair) = _steps(e.feedback);
      final ids = [...e.itemIds]..sort();
      for (final id in ids) {
        bump('item:$id', item);
      }
      final outfitColors = {for (final id in ids) ?colors[id]}.toList()
        ..sort((a, b) => a.index.compareTo(b.index));
      for (final c in outfitColors) {
        bump('color:${c.code}', color);
      }
      for (var i = 0; i < ids.length; i++) {
        for (var j = i + 1; j < ids.length; j++) {
          bump(pairKey(ids[i], ids[j]), pair);
        }
      }
    }
    weights.removeWhere((_, w) => w == 0);
    return LearnedPreferences(weights);
  }

  /// Order-independent key for two items worn together.
  static String pairKey(String a, String b) =>
      a.compareTo(b) <= 0 ? 'pair:$a+$b' : 'pair:$b+$a';

  /// (item, colour, pair) deltas for one opinion.
  static (double, double, double) _steps(OutfitFeedback f) =>
      switch ((f.kind, f.reason)) {
        (FeedbackKind.cleared, _) => (0, 0, 0),
        (FeedbackKind.like, _) => (itemStep, colorStep, pairStep),
        // Not about taste: it only reflects what was worn lately.
        (FeedbackKind.dislike, FeedbackReason.wornRecently) => (0, 0, 0),
        // The combination of colours is the problem, not each garment.
        (FeedbackKind.dislike, FeedbackReason.colorsClash) => (
          -0.01,
          -colorStep,
          -pairStep,
        ),
        // Wrong context: the pieces are fine, the pairing for this
        // occasion/weather is not.
        (
          FeedbackKind.dislike,
          FeedbackReason.tooFormal ||
              FeedbackReason.tooCasual ||
              FeedbackReason.wrongForWeather,
        ) =>
          (-0.01, 0, -pairStep),
        (FeedbackKind.dislike, _) => (-itemStep, -colorStep, -pairStep),
      };

  static int _compare(FeedbackEvent a, FeedbackEvent b) {
    final c = a.feedback.createdAt.compareTo(b.feedback.createdAt);
    return c != 0 ? c : a.feedback.id.compareTo(b.feedback.id);
  }
}
