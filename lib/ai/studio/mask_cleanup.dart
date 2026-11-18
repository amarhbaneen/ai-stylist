import 'dart:collection';
import 'dart:typed_data';

/// Mask clean-up for the studio polish (DECISIONS D-44). Masks are
/// `width × height` bytes, `1` = garment.

/// Dilation of a binary [mask] by a square of radius [r] (O(pixels), via
/// prefix sums along rows, then columns).
Uint8List dilate(Uint8List mask, int width, int height, int r) =>
    _box(mask, width, height, r, (count) => count > 0);

/// Erosion of a binary [mask] by a square of radius [r]. Pixels outside
/// the image count as garment, so erosion never eats in from the frame.
Uint8List erode(Uint8List mask, int width, int height, int r) {
  final inverted = Uint8List(mask.length);
  for (var i = 0; i < mask.length; i++) {
    inverted[i] = mask[i] == 0 ? 1 : 0;
  }
  final grown = dilate(inverted, width, height, r);
  for (var i = 0; i < grown.length; i++) {
    grown[i] = grown[i] == 0 ? 1 : 0;
  }
  return grown;
}

/// Morphological closing: seals hairline cracks and pinholes narrower than
/// about `2r`.
Uint8List close(Uint8List mask, int width, int height, int r) =>
    erode(dilate(mask, width, height, r), width, height, r);

Uint8List _box(
  Uint8List mask,
  int width,
  int height,
  int r,
  bool Function(int count) hit,
) {
  if (r <= 0) return Uint8List.fromList(mask);
  final rows = Uint8List(mask.length);
  final sums = Int32List(width + 1);
  for (var y = 0; y < height; y++) {
    final row = y * width;
    for (var x = 0; x < width; x++) {
      sums[x + 1] = sums[x] + mask[row + x];
    }
    for (var x = 0; x < width; x++) {
      final a = x - r < 0 ? 0 : x - r;
      final b = x + r + 1 > width ? width : x + r + 1;
      if (hit(sums[b] - sums[a])) rows[row + x] = 1;
    }
  }
  final out = Uint8List(mask.length);
  final col = Int32List(height + 1);
  for (var x = 0; x < width; x++) {
    for (var y = 0; y < height; y++) {
      col[y + 1] = col[y] + rows[y * width + x];
    }
    for (var y = 0; y < height; y++) {
      final a = y - r < 0 ? 0 : y - r;
      final b = y + r + 1 > height ? height : y + r + 1;
      if (hit(col[b] - col[a])) out[y * width + x] = 1;
    }
  }
  return out;
}

/// Pixels to make opaque: transparent pixels enclosed by the garment once
/// it is closed with radius [closeRadius], in holes no larger than
/// [maxHoleShare] of the garment area. Larger holes are left: they may be
/// real (a gap between a strap and the body). Returns `1` per pixel to fill.
Uint8List holesToFill(
  Uint8List mask,
  int width,
  int height, {
  required int closeRadius,
  double maxHoleShare = 0.02,
}) {
  final closed = close(mask, width, height, closeRadius);
  final n = width * height;

  // Background: transparent (in the closed mask) and reachable from the
  // frame. Everything else that is transparent in [mask] is enclosed.
  final outside = Uint8List(n);
  final queue = Queue<int>();
  void seed(int i) {
    if (closed[i] == 0 && outside[i] == 0) {
      outside[i] = 1;
      queue.add(i);
    }
  }

  for (var x = 0; x < width; x++) {
    seed(x);
    seed((height - 1) * width + x);
  }
  for (var y = 0; y < height; y++) {
    seed(y * width);
    seed(y * width + width - 1);
  }
  while (queue.isNotEmpty) {
    final i = queue.removeFirst();
    final x = i % width, y = i ~/ width;
    if (x > 0) seed(i - 1);
    if (x < width - 1) seed(i + 1);
    if (y > 0) seed(i - width);
    if (y < height - 1) seed(i + width);
  }

  var area = 0;
  for (final v in mask) {
    area += v;
  }
  final cap = (area * maxHoleShare).floor();

  // Enclosed pixels, grouped into 4-connected holes; keep the small ones.
  final fill = Uint8List(n);
  final seen = Uint8List(n);
  final hole = <int>[];
  for (var start = 0; start < n; start++) {
    if (mask[start] == 1 || outside[start] == 1 || seen[start] == 1) continue;
    hole.clear();
    seen[start] = 1;
    queue.add(start);
    while (queue.isNotEmpty) {
      final i = queue.removeFirst();
      hole.add(i);
      final x = i % width, y = i ~/ width;
      void visit(int j) {
        if (mask[j] == 0 && outside[j] == 0 && seen[j] == 0) {
          seen[j] = 1;
          queue.add(j);
        }
      }

      if (x > 0) visit(i - 1);
      if (x < width - 1) visit(i + 1);
      if (y > 0) visit(i - width);
      if (y < height - 1) visit(i + width);
    }
    if (hole.length <= cap) {
      for (final i in hole) {
        fill[i] = 1;
      }
    }
  }
  return fill;
}
