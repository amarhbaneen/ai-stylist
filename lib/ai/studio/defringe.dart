import 'dart:collection';
import 'dart:typed_data';

import 'studio_buffer.dart';

/// Removes the background halo from soft edges (DECISIONS D-44).
///
/// Semi-transparent edge pixels still carry the colour of what was behind
/// the garment (a chair's mesh, a wall). Each one within [radius] pixels of
/// the fully opaque interior takes the colour of the nearest opaque pixel;
/// its alpha is kept, so the edge stays soft.
StudioBuffer defringe(StudioBuffer b, {int radius = 8}) {
  final w = b.width, h = b.height, n = b.pixels;
  final source = Int32List(n)..fillRange(0, n, -1);
  final dist = Int32List(n)..fillRange(0, n, 1 << 30);
  final queue = Queue<int>();
  for (var i = 0; i < n; i++) {
    if (b.alphaAt(i) == 255) {
      source[i] = i;
      dist[i] = 0;
      queue.add(i);
    }
  }
  // Breadth-first from all opaque pixels at once: the first to reach a
  // pixel is (one of) the nearest.
  while (queue.isNotEmpty) {
    final i = queue.removeFirst();
    final d = dist[i];
    if (d >= radius) continue;
    final x = i % w, y = i ~/ w;
    void visit(int j) {
      if (dist[j] <= d + 1) return;
      dist[j] = d + 1;
      source[j] = source[i];
      queue.add(j);
    }

    if (x > 0) visit(i - 1);
    if (x < w - 1) visit(i + 1);
    if (y > 0) visit(i - w);
    if (y < h - 1) visit(i + w);
  }

  final out = b.copy();
  for (var i = 0; i < n; i++) {
    final a = b.alphaAt(i);
    if (a == 0 || a == 255) continue;
    final s = source[i];
    if (s < 0) continue;
    out.rgba[i * 4] = b.rgba[s * 4];
    out.rgba[i * 4 + 1] = b.rgba[s * 4 + 1];
    out.rgba[i * 4 + 2] = b.rgba[s * 4 + 2];
  }
  return out;
}

/// A light feather: the edge band's alpha is averaged over 3 × 3, which
/// softens stair-steps without blurring the garment.
StudioBuffer feather(StudioBuffer b) {
  final w = b.width, h = b.height;
  final out = b.copy();
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = y * w + x;
      final a = b.alphaAt(i);
      var edge = a > 0 && a < 255;
      var sum = 0, count = 0;
      for (var dy = -1; dy <= 1; dy++) {
        final yy = y + dy;
        if (yy < 0 || yy >= h) continue;
        for (var dx = -1; dx <= 1; dx++) {
          final xx = x + dx;
          if (xx < 0 || xx >= w) continue;
          final v = b.alphaAt(yy * w + xx);
          if ((v == 0) != (a == 0)) edge = true;
          sum += v;
          count++;
        }
      }
      if (edge && a > 0) out.rgba[i * 4 + 3] = (sum / count).round();
    }
  }
  return out;
}
