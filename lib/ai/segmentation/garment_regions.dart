import 'dart:math' as math;
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import 'segmentation_labels.dart';

/// One garment found in a photo, as a soft mask at the model's resolution.
@immutable
final class GarmentRegion {
  const GarmentRegion({
    required this.category,
    required this.areaShare,
    required this.alpha,
    required this.size,
  });

  /// The segmentation model's category. Only a label for the picker: the
  /// classifier later suggests the item's attributes from the cut-out.
  final GarmentCategory category;

  /// Share of the photo the garment covers (0–1).
  final double areaShare;

  /// `size × size`, row-major, 0–1: how much each pixel belongs to it.
  final Float32List alpha;
  final int size;
}

/// Mask values at or above this are visible in the cut-out (the renderer's
/// ramp starts here), so connected parts are measured on them.
const visibleAlpha = 0.3;

/// A connected part of a garment's mask smaller than this share of its
/// largest part is treated as a speck and removed.
const minPartShare = 0.2;

/// Turns per-pixel class probabilities into garments (pure; tested
/// directly). See DECISIONS D-40.
///
/// - Pixels are grouped by app **category**, not by model class. The model
///   often confuses neighbouring classes (shirt vs. sweater, jacket vs.
///   coat), and one garment must not be split in two because of that.
/// - A category is offered when its pixels (by arg-max) cover at least
///   [minAreaShare] of the photo. Larger garments come first.
/// - Every garment pixel is given to the most likely offered category, so a
///   small mislabelled patch inside a garment is not cut out of it.
/// - Specks are removed: within each garment, connected parts smaller than
///   [minPartShare] of its largest part are dropped. A garment that then
///   falls below [minAreaShare] is dropped too, and the masks are rebuilt
///   without it, so its pixels go back to the garments that remain.
/// - With one garment, its mask is simply "not background".
/// - The mask value is the garment probability (1 − background), which
///   gives soft edges when it is scaled up to the photo.
List<GarmentRegion> findRegions(
  Float32List probabilities,
  SegmentationLabels labels, {
  double? minAreaShare,
}) {
  final size = labels.inputSize;
  final channels = labels.classes.length;
  final pixels = size * size;
  if (probabilities.length != pixels * channels) {
    throw ArgumentError.value(
      probabilities.length,
      'probabilities',
      'expected $pixels × $channels values',
    );
  }
  final threshold = minAreaShare ?? labels.minAreaShare;

  final categories = labels.classes
      .map((c) => c.category)
      .nonNulls
      .toSet()
      .toList();
  final groupOf = Int32List(channels)..[0] = -1;
  for (var k = 1; k < channels; k++) {
    groupOf[k] = categories.indexOf(labels.classes[k].category!);
  }

  // Arg-max area per category decides which garments are candidates.
  final counts = Int32List(categories.length);
  for (var i = 0; i < pixels; i++) {
    final base = i * channels;
    var best = 0;
    for (var k = 1; k < channels; k++) {
      if (probabilities[base + k] > probabilities[base + best]) best = k;
    }
    if (best != 0) counts[groupOf[best]]++;
  }
  var kept = [
    for (var g = 0; g < categories.length; g++)
      if (counts[g] / pixels >= threshold) g,
  ];

  // Build masks, remove specks, and repeat without any garment that
  // became too small. Each round drops at least one, so this ends.
  while (kept.isNotEmpty) {
    final alphas = _assign(probabilities, channels, groupOf, kept, pixels);
    final areas = [for (final a in alphas) _removeSpecks(a, size) / pixels];
    final survivors = [
      for (var s = 0; s < kept.length; s++)
        if (areas[s] >= threshold) s,
    ];
    if (survivors.length < kept.length) {
      kept = [for (final s in survivors) kept[s]];
      continue;
    }
    final order = List.generate(kept.length, (s) => s)
      ..sort((a, b) {
        final c = areas[b].compareTo(areas[a]);
        return c != 0 ? c : kept[a] - kept[b];
      });
    return [
      for (final s in order)
        GarmentRegion(
          category: categories[kept[s]],
          areaShare: areas[s],
          alpha: alphas[s],
          size: size,
        ),
    ];
  }
  return const [];
}

/// Soft masks for the [kept] category groups: each pixel goes to the kept
/// group with the highest summed probability, with value 1 − background.
List<Float32List> _assign(
  Float32List probabilities,
  int channels,
  Int32List groupOf,
  List<int> kept,
  int pixels,
) {
  final alphas = [for (final _ in kept) Float32List(pixels)];
  final slot = Int32List(groupOf.reduce(math.max) + 1)
    ..fillRange(0, groupOf.reduce(math.max) + 1, -1);
  for (var s = 0; s < kept.length; s++) {
    slot[kept[s]] = s;
  }
  final sums = Float64List(kept.length);
  for (var i = 0; i < pixels; i++) {
    final base = i * channels;
    final garment = (1 - probabilities[base]).clamp(0.0, 1.0);
    if (kept.length == 1) {
      alphas[0][i] = garment;
      continue;
    }
    sums.fillRange(0, sums.length, 0);
    for (var k = 1; k < channels; k++) {
      final s = slot[groupOf[k]];
      if (s >= 0) sums[s] += probabilities[base + k];
    }
    var best = 0;
    for (var s = 1; s < sums.length; s++) {
      if (sums[s] > sums[best]) best = s;
    }
    alphas[best][i] = garment;
  }
  return alphas;
}

/// Zeroes connected parts (4-connected, on visible pixels) smaller than
/// [minPartShare] of the largest part. Returns the garment's remaining
/// area in pixels (mask ≥ 0.5).
int _removeSpecks(Float32List alpha, int size) {
  final n = size * size;
  final part = Int32List(n)..fillRange(0, n, -1);
  final partSizes = <int>[];
  final stack = Int32List(n);
  for (var start = 0; start < n; start++) {
    if (part[start] >= 0 || alpha[start] < visibleAlpha) continue;
    final id = partSizes.length;
    var top = 0, count = 0;
    stack[top++] = start;
    part[start] = id;
    while (top > 0) {
      final i = stack[--top];
      count++;
      final x = i % size, y = i ~/ size;
      void visit(int j) {
        if (part[j] < 0 && alpha[j] >= visibleAlpha) {
          part[j] = id;
          stack[top++] = j;
        }
      }

      if (x > 0) visit(i - 1);
      if (x < size - 1) visit(i + 1);
      if (y > 0) visit(i - size);
      if (y < size - 1) visit(i + size);
    }
    partSizes.add(count);
  }
  if (partSizes.isEmpty) return 0;
  final largest = partSizes.reduce(math.max);
  var area = 0;
  for (var i = 0; i < n; i++) {
    final id = part[i];
    if (id < 0) continue;
    if (partSizes[id] < largest * minPartShare) {
      alpha[i] = 0;
    } else if (alpha[i] >= 0.5) {
      area++;
    }
  }
  return area;
}
