import 'dart:math' as math;

/// A colour in CIELAB (D65), where Euclidean distance approximates perceived
/// difference. Pure Dart: no Flutter or image-library types.
final class Lab {
  const Lab(this.l, this.a, this.b);

  /// Converts 8-bit sRGB to CIELAB (D65 white point).
  factory Lab.fromRgb(int r, int g, int b) {
    double lin(int c) {
      final v = c / 255;
      return v <= 0.04045
          ? v / 12.92
          : math.pow((v + 0.055) / 1.055, 2.4) as double;
    }

    final rl = lin(r), gl = lin(g), bl = lin(b);
    final x = (rl * 0.4124564 + gl * 0.3575761 + bl * 0.1804375) / 0.95047;
    final y = rl * 0.2126729 + gl * 0.7151522 + bl * 0.0721750;
    final z = (rl * 0.0193339 + gl * 0.1191920 + bl * 0.9503041) / 1.08883;

    double f(double t) =>
        t > 0.008856 ? math.pow(t, 1 / 3) as double : 7.787 * t + 16 / 116;

    final fx = f(x), fy = f(y), fz = f(z);
    return Lab(116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz));
  }

  /// Lightness, 0 (black) to 100 (white).
  final double l;
  final double a;
  final double b;

  /// Chroma: distance from grey.
  double get chroma => math.sqrt(a * a + b * b);

  /// Hue angle in degrees, 0–360.
  double get hue {
    final h = math.atan2(b, a) * 180 / math.pi;
    return h < 0 ? h + 360 : h;
  }

  /// CIE76 colour difference.
  double distanceTo(Lab o) {
    final dl = l - o.l, da = a - o.a, db = b - o.b;
    return math.sqrt(dl * dl + da * da + db * db);
  }

  @override
  String toString() =>
      'Lab(${l.toStringAsFixed(1)}, ${a.toStringAsFixed(1)}, '
      '${b.toStringAsFixed(1)})';
}
