import 'dart:typed_data';

import 'studio_buffer.dart';

/// Classical hole filling (push-pull; DECISIONS D-44): each pixel in
/// [fill] gets a colour diffused from the garment pixels around it, and
/// becomes opaque. No model, no invented texture: small holes take the
/// surrounding colour.
///
/// Known pixels are the solid garment pixels outside [fill]. The image is
/// averaged down into a pyramid (weighted by known pixels), then unknown
/// pixels are pulled back up from the coarser levels.
StudioBuffer fillHoles(StudioBuffer b, Uint8List fill) {
  var any = false;
  for (final v in fill) {
    if (v == 1) {
      any = true;
      break;
    }
  }
  if (!any) return b;

  // Level 0: premultiplied colour and weight per pixel.
  final levels = <_Level>[];
  var level = _Level(b.width, b.height);
  for (var i = 0; i < b.pixels; i++) {
    if (fill[i] == 1 || b.alphaAt(i) < solidAlpha) continue;
    level.w[i] = 1;
    level.r[i] = b.rgba[i * 4].toDouble();
    level.g[i] = b.rgba[i * 4 + 1].toDouble();
    level.b[i] = b.rgba[i * 4 + 2].toDouble();
  }
  levels.add(level);

  // Push: halve until 1 × 1, averaging known colour.
  while (level.width > 1 || level.height > 1) {
    final next = _Level((level.width + 1) ~/ 2, (level.height + 1) ~/ 2);
    for (var y = 0; y < level.height; y++) {
      for (var x = 0; x < level.width; x++) {
        final i = y * level.width + x;
        final wt = level.w[i];
        if (wt == 0) continue;
        final j = (y ~/ 2) * next.width + x ~/ 2;
        next.w[j] += wt;
        next.r[j] += level.r[i] * wt;
        next.g[j] += level.g[i] * wt;
        next.b[j] += level.b[i] * wt;
      }
    }
    for (var j = 0; j < next.w.length; j++) {
      final wt = next.w[j];
      if (wt == 0) continue;
      next.r[j] /= wt;
      next.g[j] /= wt;
      next.b[j] /= wt;
      next.w[j] = wt > 1 ? 1 : wt;
    }
    levels.add(next);
    level = next;
  }

  // Pull: fill unknown pixels from the coarser level.
  for (var k = levels.length - 2; k >= 0; k--) {
    final fine = levels[k], coarse = levels[k + 1];
    for (var y = 0; y < fine.height; y++) {
      for (var x = 0; x < fine.width; x++) {
        final i = y * fine.width + x;
        if (fine.w[i] > 0) continue;
        final j = (y ~/ 2) * coarse.width + x ~/ 2;
        fine.r[i] = coarse.r[j];
        fine.g[i] = coarse.g[j];
        fine.b[i] = coarse.b[j];
        fine.w[i] = coarse.w[j] > 0 ? 1 : 0;
      }
    }
  }

  final out = b.copy();
  final base = levels.first;
  for (var i = 0; i < b.pixels; i++) {
    if (fill[i] != 1) continue;
    out.rgba[i * 4] = base.r[i].round().clamp(0, 255);
    out.rgba[i * 4 + 1] = base.g[i].round().clamp(0, 255);
    out.rgba[i * 4 + 2] = base.b[i].round().clamp(0, 255);
    out.rgba[i * 4 + 3] = 255;
  }
  return out;
}

final class _Level {
  _Level(this.width, this.height)
    : r = Float32List(width * height),
      g = Float32List(width * height),
      b = Float32List(width * height),
      w = Float32List(width * height);

  final int width;
  final int height;
  final Float32List r;
  final Float32List g;
  final Float32List b;
  final Float32List w;
}
