import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../outfit.dart';

/// Position of each chromatic family on the painter's (RYB) colour wheel,
/// in degrees. Fashion harmony rules are stated on this wheel (red–green,
/// orange–blue and yellow–purple are complementary); perceptual spaces
/// such as CIELAB do not place complements 180° apart.
const _hue = <ColorFamily, double>{
  ColorFamily.red: 0,
  ColorFamily.burgundy: 350,
  ColorFamily.pink: 335,
  ColorFamily.orange: 60,
  ColorFamily.yellow: 120,
  ColorFamily.olive: 140,
  ColorFamily.green: 180,
  ColorFamily.blue: 240,
  ColorFamily.purple: 300,
};

/// Compatibility of two colour families, 0–1, with the reason it implies.
///
/// Rules (deliberately simple and explainable):
/// - neutrals (black, white, grey, beige, brown, navy) go with anything;
/// - the same family reads as monochrome;
/// - hues within 60° (two wheel segments) are analogous; 150–210° apart
///   are complementary;
/// - multicolour pairs well with neutrals, less with other colours;
/// - anything else is a mild clash.
(double, ReasonCode?) pairHarmony(ColorFamily? a, ColorFamily? b) {
  if (a == null || b == null) return (0.65, null);
  if (a.isNeutral || b.isNeutral) return (1.0, ReasonCode.neutralBase);
  if (a == ColorFamily.multicolor || b == ColorFamily.multicolor) {
    return a == b ? (0.3, ReasonCode.colorClash) : (0.55, null);
  }
  if (a == b) return (0.85, ReasonCode.monochrome);
  final ha = _hue[a]!, hb = _hue[b]!;
  var d = (ha - hb).abs();
  if (d > 180) d = 360 - d;
  if (d <= 60) return (0.8, ReasonCode.analogousColors);
  if (d >= 150) return (0.75, ReasonCode.complementaryColors);
  return (0.45, ReasonCode.colorClash);
}

/// Colour score of a whole outfit: the mean pairwise harmony of the pieces'
/// main colours, minus a penalty when more than two non-neutral colours
/// compete.
(double, Set<ReasonCode>) colorScore(List<ColorFamily?> colors) {
  if (colors.length < 2) return (1.0, const {});
  var sum = 0.0;
  var pairs = 0;
  final reasons = <ReasonCode>{};
  for (var i = 0; i < colors.length; i++) {
    for (var j = i + 1; j < colors.length; j++) {
      final (score, reason) = pairHarmony(colors[i], colors[j]);
      sum += score;
      pairs++;
      if (reason != null) reasons.add(reason);
    }
  }
  var score = sum / pairs;
  final chromatic = {
    for (final c in colors)
      if (c != null && !c.isNeutral) c,
  };
  if (chromatic.length > 2) {
    score -= 0.15 * (chromatic.length - 2);
    reasons.add(ReasonCode.colorClash);
  }
  // A clash anywhere outweighs the positive labels in the explanation.
  if (reasons.contains(ReasonCode.colorClash)) {
    reasons.removeAll({
      ReasonCode.analogousColors,
      ReasonCode.complementaryColors,
    });
  }
  return (score.clamp(0.0, 1.0), reasons);
}
