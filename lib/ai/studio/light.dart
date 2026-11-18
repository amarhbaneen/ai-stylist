import 'dart:math' as math;
import 'dart:typed_data';

import '../color/color_space.dart';
import 'studio_buffer.dart';

/// Largest allowed average colour change of the garment from the light
/// correction, in CIE76 ΔE (DECISIONS D-44). About 2–3 is "just
/// noticeable" side by side; 6 brightens a dull photo without making a
/// navy shirt look blue.
const maxMeanDeltaE = 6.0;

/// Largest change of any single garment pixel, in ΔE.
const maxPixelDeltaE = 15.0;

/// Gray-world white-balance gains are pulled only this far toward neutral
/// and kept within ±[maxWhiteBalance].
const whiteBalanceWeight = 0.3;
const maxWhiteBalance = 0.08;

/// The correction a [LightCorrection.strength] of 1 would apply.
final class LightCorrection {
  const LightCorrection({
    required this.low,
    required this.high,
    required this.gains,
  });

  /// Luma percentiles stretched to 0 and 255.
  final double low;
  final double high;

  /// Per-channel white-balance gains.
  final List<double> gains;

  /// Applies the correction at [strength] (0 = none, 1 = full) to one
  /// channel value of channel [c].
  int apply(int v, int c, double strength) {
    final stretched = high - low < 1
        ? v.toDouble()
        : (v - low) * 255 / (high - low);
    final balanced = stretched * gains[c];
    final out = v + (balanced - v) * strength;
    return out.round().clamp(0, 255);
  }
}

/// The full correction for [b]'s garment pixels: levels p2 → p98 on luma,
/// and a weak gray-world white balance. `null` without garment pixels.
LightCorrection? measureLight(StudioBuffer b) {
  final hist = Int32List(256);
  var n = 0;
  var sr = 0.0, sg = 0.0, sb = 0.0;
  for (var i = 0; i < b.pixels; i++) {
    if (b.alphaAt(i) < solidAlpha) continue;
    final r = b.rgba[i * 4], g = b.rgba[i * 4 + 1], bl = b.rgba[i * 4 + 2];
    hist[(0.299 * r + 0.587 * g + 0.114 * bl).round().clamp(0, 255)]++;
    sr += r;
    sg += g;
    sb += bl;
    n++;
  }
  if (n == 0) return null;
  double percentile(double p) {
    final target = p * n;
    var seen = 0;
    for (var v = 0; v < 256; v++) {
      seen += hist[v];
      if (seen >= target) return v.toDouble();
    }
    return 255;
  }

  final means = [sr / n, sg / n, sb / n];
  final grey = (means[0] + means[1] + means[2]) / 3;
  final gains = [
    for (final m in means)
      m < 1
          ? 1.0
          : (1 + (grey / m - 1) * whiteBalanceWeight).clamp(
              1 - maxWhiteBalance,
              1 + maxWhiteBalance,
            ),
  ];
  return LightCorrection(
    low: percentile(0.02),
    high: percentile(0.98),
    gains: gains,
  );
}

/// [b] with its light corrected as strongly as the ΔE caps allow
/// ([maxMeanDeltaE] on average, [maxPixelDeltaE] for any pixel), found by
/// bisection on the strength. Transparent pixels are left alone.
StudioBuffer correctLight(StudioBuffer b) {
  final c = measureLight(b);
  if (c == null) return b;

  // Measure on a sample of garment pixels to keep this fast.
  final sample = <int>[];
  var garment = 0;
  for (var i = 0; i < b.pixels; i++) {
    if (b.alphaAt(i) >= solidAlpha) garment++;
  }
  final step = math.max(1, garment ~/ 2000);
  var k = 0;
  for (var i = 0; i < b.pixels; i++) {
    if (b.alphaAt(i) < solidAlpha) continue;
    if (k++ % step == 0) sample.add(i);
  }
  final before = [
    for (final i in sample)
      Lab.fromRgb(b.rgba[i * 4], b.rgba[i * 4 + 1], b.rgba[i * 4 + 2]),
  ];

  bool withinCaps(double s) {
    var total = 0.0;
    for (var j = 0; j < sample.length; j++) {
      final i = sample[j];
      final after = Lab.fromRgb(
        c.apply(b.rgba[i * 4], 0, s),
        c.apply(b.rgba[i * 4 + 1], 1, s),
        c.apply(b.rgba[i * 4 + 2], 2, s),
      );
      final d = before[j].distanceTo(after);
      if (d > maxPixelDeltaE) return false;
      total += d;
    }
    return total / sample.length <= maxMeanDeltaE;
  }

  var lo = 0.0, hi = 1.0;
  if (withinCaps(1)) {
    lo = 1;
  } else {
    for (var it = 0; it < 10; it++) {
      final mid = (lo + hi) / 2;
      if (withinCaps(mid)) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
  }
  if (lo == 0) return b;

  final out = b.copy();
  for (var i = 0; i < b.pixels; i++) {
    if (b.alphaAt(i) == 0) continue;
    for (var ch = 0; ch < 3; ch++) {
      out.rgba[i * 4 + ch] = c.apply(b.rgba[i * 4 + ch], ch, lo);
    }
  }
  return out;
}

/// Mean CIE76 ΔE between the garment pixels of [a] and [b] (same size),
/// for tests and reporting.
double meanDeltaE(StudioBuffer a, StudioBuffer b) {
  var total = 0.0;
  var n = 0;
  for (var i = 0; i < a.pixels; i++) {
    if (a.alphaAt(i) < solidAlpha) continue;
    total += Lab.fromRgb(a.rgba[i * 4], a.rgba[i * 4 + 1], a.rgba[i * 4 + 2])
        .distanceTo(
          Lab.fromRgb(b.rgba[i * 4], b.rgba[i * 4 + 1], b.rgba[i * 4 + 2]),
        );
    n++;
  }
  return n == 0 ? 0 : total / n;
}
