import 'dart:math' as math;
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import 'color_naming.dart';
import 'color_space.dart';

/// Result of colour analysis: suggestions only; the user confirms or edits.
@immutable
final class ColorAnalysis {
  const ColorAnalysis({
    required this.primary,
    required this.secondary,
    required this.confidence,
    required this.shares,
    required this.backgroundRemoved,
  });

  /// `null` when nothing could be measured (e.g. an empty image).
  final ColorFamily? primary;

  /// Other families covering a meaningful share of the garment.
  final Set<ColorFamily> secondary;

  /// Share of garment pixels in [primary] (0–1). Low values mean "unsure".
  final double confidence;

  /// Share of garment pixels per family, largest first.
  final Map<ColorFamily, double> shares;

  /// Whether a plain background was detected and excluded.
  final bool backgroundRemoved;

  static const empty = ColorAnalysis(
    primary: null,
    secondary: {},
    confidence: 0,
    shares: {},
    backgroundRemoved: false,
  );
}

/// Deterministic Tier-0 colour extraction (DECISIONS D-08): no model, no
/// network, same output for the same pixels.
///
/// 1. Estimate the background from the image border; if the border is
///    uniform, drop pixels close to it.
/// 2. Weight the remaining pixels towards the centre, where garments sit.
/// 3. Cluster them in CIELAB with seeded k-means.
/// 4. Name each cluster ([nameColor]) and sum shares per colour family.
final class ColorExtractor {
  const ColorExtractor({
    this.clusters = 5,
    this.iterations = 12,
    this.secondaryMinShare = 0.15,
    this.multicolorMaxPrimaryShare = 0.35,
  });

  final int clusters;
  final int iterations;
  final double secondaryMinShare;
  final double multicolorMaxPrimaryShare;

  /// Border pixels whose mean distance to their average is below this are
  /// treated as a plain background.
  static const _uniformBorderMaxSpread = 10.0;

  /// Pixels this close (CIE76) to the background colour are background.
  static const _backgroundDistance = 14.0;

  /// If less than this share of pixels survives background removal, the
  /// garment is probably the same colour as the background: keep them all.
  static const _minForegroundShare = 0.08;

  /// Analyses tightly packed 8-bit RGB pixels ([rgb].length == w*h*3).
  ColorAnalysis analyzeRgb(Uint8List rgb, int width, int height) {
    if (width <= 0 || height <= 0 || rgb.length < width * height * 3) {
      return ColorAnalysis.empty;
    }
    final labs = List<Lab>.generate(
      width * height,
      (i) => Lab.fromRgb(rgb[i * 3], rgb[i * 3 + 1], rgb[i * 3 + 2]),
      growable: false,
    );

    final background = _uniformBorder(labs, width, height);
    final weights = Float64List(labs.length);
    var kept = 0;
    final cx = (width - 1) / 2, cy = (height - 1) / 2;
    final maxR2 = cx * cx + cy * cy;
    for (var i = 0; i < labs.length; i++) {
      if (background != null &&
          labs[i].distanceTo(background) < _backgroundDistance) {
        continue;
      }
      final dx = i % width - cx, dy = i ~/ width - cy;
      // 1.0 at the centre, 0.35 in the corners.
      weights[i] = 1 - 0.65 * (dx * dx + dy * dy) / (maxR2 == 0 ? 1 : maxR2);
      kept++;
    }
    var backgroundRemoved = background != null;
    if (kept < labs.length * _minForegroundShare) {
      backgroundRemoved = false;
      for (var i = 0; i < labs.length; i++) {
        weights[i] = 1;
      }
    }

    final (centroids, clusterWeights) = _kMeans(labs, weights);
    final total = clusterWeights.fold<double>(0, (a, b) => a + b);
    if (total == 0) return ColorAnalysis.empty;

    final byFamily = <ColorFamily, double>{};
    for (var k = 0; k < centroids.length; k++) {
      if (clusterWeights[k] == 0) continue;
      final family = nameColor(centroids[k]);
      byFamily[family] = (byFamily[family] ?? 0) + clusterWeights[k] / total;
    }
    final ranked = byFamily.entries.toList()
      ..sort((x, y) {
        final c = y.value.compareTo(x.value);
        return c != 0 ? c : x.key.index.compareTo(y.key.index);
      });
    final shares = {for (final e in ranked) e.key: e.value};
    final significant = [
      for (final e in ranked)
        if (e.value >= secondaryMinShare) e.key,
    ];

    final top = ranked.first;
    final isMulticolor =
        top.value < multicolorMaxPrimaryShare && significant.length >= 3;
    final primary = isMulticolor ? ColorFamily.multicolor : top.key;
    return ColorAnalysis(
      primary: primary,
      secondary: {
        for (final f in significant)
          if (f != primary) f,
      },
      confidence: isMulticolor
          ? significant.fold<double>(0, (a, f) => a + shares[f]!)
          : top.value,
      shares: shares,
      backgroundRemoved: backgroundRemoved,
    );
  }

  /// The average border colour if the border is uniform, else `null`.
  Lab? _uniformBorder(List<Lab> labs, int w, int h) {
    final border = <Lab>[
      for (var x = 0; x < w; x++) ...[labs[x], labs[(h - 1) * w + x]],
      for (var y = 1; y < h - 1; y++) ...[labs[y * w], labs[y * w + w - 1]],
    ];
    if (border.isEmpty) return null;
    var l = 0.0, a = 0.0, b = 0.0;
    for (final p in border) {
      l += p.l;
      a += p.a;
      b += p.b;
    }
    final mean = Lab(l / border.length, a / border.length, b / border.length);
    final spread =
        border.fold<double>(0, (s, p) => s + p.distanceTo(mean)) /
        border.length;
    return spread <= _uniformBorderMaxSpread ? mean : null;
  }

  /// Weighted k-means with deterministic k-means++ seeding.
  (List<Lab>, List<double>) _kMeans(List<Lab> labs, Float64List weights) {
    final points = [
      for (var i = 0; i < labs.length; i++)
        if (weights[i] > 0) i,
    ];
    if (points.isEmpty) return (const [], const []);
    final k = math.min(clusters, points.length);
    final random = math.Random(42);

    final centroids = <Lab>[labs[points[random.nextInt(points.length)]]];
    while (centroids.length < k) {
      final d2 = <double>[];
      for (final i in points) {
        final d = centroids.map((c) => labs[i].distanceTo(c)).reduce(math.min);
        d2.add(d * d * weights[i]);
      }
      final sum = d2.fold<double>(0, (a, b) => a + b);
      if (sum == 0) break; // fewer distinct colours than k
      var pick = random.nextDouble() * sum;
      var chosen = points.last;
      for (var j = 0; j < points.length; j++) {
        pick -= d2[j];
        if (pick <= 0) {
          chosen = points[j];
          break;
        }
      }
      centroids.add(labs[chosen]);
    }

    final assignment = List<int>.filled(labs.length, 0);
    var clusterWeights = List<double>.filled(centroids.length, 0);
    for (var iter = 0; iter < iterations; iter++) {
      final sums = List.generate(centroids.length, (_) => [0.0, 0.0, 0.0]);
      clusterWeights = List<double>.filled(centroids.length, 0);
      for (final i in points) {
        var best = 0;
        var bestD = double.infinity;
        for (var c = 0; c < centroids.length; c++) {
          final d = labs[i].distanceTo(centroids[c]);
          if (d < bestD) {
            bestD = d;
            best = c;
          }
        }
        assignment[i] = best;
        final w = weights[i];
        sums[best][0] += labs[i].l * w;
        sums[best][1] += labs[i].a * w;
        sums[best][2] += labs[i].b * w;
        clusterWeights[best] += w;
      }
      for (var c = 0; c < centroids.length; c++) {
        final w = clusterWeights[c];
        if (w > 0) {
          centroids[c] = Lab(sums[c][0] / w, sums[c][1] / w, sums[c][2] / w);
        }
      }
    }
    return (centroids, clusterWeights);
  }
}
