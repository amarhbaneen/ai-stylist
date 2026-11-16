import 'package:wardrobe_domain/wardrobe_domain.dart';

import 'color_space.dart';

/// Maps a CIELAB colour to one of the app's [ColorFamily] names using
/// lightness (L*), chroma (C*) and hue (h°) bands.
///
/// Rules, rather than nearest-swatch matching, keep dark and light shades of
/// the same hue together (navy vs blue, burgundy vs red, beige vs brown).
/// Hue anchors in CIELAB: red ≈ 40°, orange ≈ 73°, yellow ≈ 103°,
/// green ≈ 136°, teal ≈ 196°, blue ≈ 306°, purple ≈ 328°, pink ≈ 0–10°.
ColorFamily nameColor(Lab c) {
  final l = c.l, ch = c.chroma, h = c.hue;

  // Achromatic: too little colour to have a meaningful hue.
  if (ch < 10) {
    if (l < 25) return ColorFamily.black;
    if (l > 90) return ColorFamily.white;
    return ColorFamily.grey;
  }

  if (h >= 20 && h < 50) {
    if (l < 30) return ColorFamily.burgundy;
    if (l >= 72 && ch < 45) return ColorFamily.pink;
    return ColorFamily.red;
  }
  if (h >= 50 && h < 85) {
    if (l < 50) return ColorFamily.brown;
    if (ch < 30 && l >= 60) return ColorFamily.beige;
    return ColorFamily.orange;
  }
  if (h >= 85 && h < 115) {
    if (l < 60) return ColorFamily.olive;
    if (ch < 30) return ColorFamily.beige;
    return ColorFamily.yellow;
  }
  if (h >= 115 && h < 200) {
    // Dark yellow-greens (dark olive ≈ L42, C38, h120) read as olive.
    if (h < 135 && l < 45 && ch < 45) return ColorFamily.olive;
    return ColorFamily.green;
  }
  if (h >= 200 && h < 315) {
    return l < 30 ? ColorFamily.navy : ColorFamily.blue;
  }
  if (h >= 315 && h < 330) return ColorFamily.purple;

  // 330°–20°: pinks, magenta-reds and deep wine shades.
  if (l >= 60) return ColorFamily.pink;
  if (l < 30) return ColorFamily.burgundy;
  return ColorFamily.red;
}
