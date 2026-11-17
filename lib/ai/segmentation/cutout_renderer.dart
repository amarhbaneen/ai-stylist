import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:wardrobe_domain/wardrobe_domain.dart';

import 'garment_regions.dart';

/// Renders a garment's cut-out from the photo and its soft mask (pure;
/// tested directly). Runs on a background isolate.
///
/// The mask is scaled up with bilinear sampling and mapped through a short
/// ramp, so edges are soft rather than blocky. The result is cropped to
/// the garment with a small margin; pixels outside it are transparent.
/// Returns `null` when the mask is empty at photo size.
CutoutImages? renderCutout(
  img.Image photo,
  GarmentRegion region, {
  int thumbnailEdge = 320,
  double margin = 0.03,
}) {
  final w = photo.width, h = photo.height;
  if (w == 0 || h == 0) return null;
  final alpha = _scaledAlpha(region, w, h);

  var left = w, top = h, right = -1, bottom = -1;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (alpha[y * w + x] < 128) continue;
      if (x < left) left = x;
      if (x > right) right = x;
      if (y < top) top = y;
      if (y > bottom) bottom = y;
    }
  }
  if (right < 0) return null;
  final pad = (margin * math.max(w, h)).round();
  left = math.max(0, left - pad);
  top = math.max(0, top - pad);
  right = math.min(w - 1, right + pad);
  bottom = math.min(h - 1, bottom + pad);

  final rgb = photo.convert(format: img.Format.uint8, numChannels: 3);
  final cut = img.Image(
    width: right - left + 1,
    height: bottom - top + 1,
    numChannels: 4,
  );
  for (final p in cut) {
    final sx = p.x + left, sy = p.y + top;
    final a = alpha[sy * w + sx];
    if (a == 0) continue; // stays fully transparent black
    final s = rgb.getPixel(sx, sy);
    p
      ..r = s.r
      ..g = s.g
      ..b = s.b
      ..a = a;
  }

  final scale = thumbnailEdge / math.max(cut.width, cut.height);
  final thumb = scale >= 1
      ? cut
      : img.copyResize(
          cut,
          width: math.max(1, (cut.width * scale).round()),
          height: math.max(1, (cut.height * scale).round()),
          interpolation: img.Interpolation.average,
        );
  return CutoutImages(
    image: img.encodePng(cut),
    thumbnail: img.encodePng(thumb),
    width: cut.width,
    height: cut.height,
  );
}

/// Mask values below [_rampLow] are transparent and above [_rampHigh] fully
/// opaque; in between they fade, which softens the edge.
const _rampLow = 0.3;
const _rampHigh = 0.7;

List<int> _scaledAlpha(GarmentRegion region, int w, int h) {
  final s = region.size;
  final src = region.alpha;
  final out = List<int>.filled(w * h, 0);
  for (var y = 0; y < h; y++) {
    final v = ((y + 0.5) * s / h - 0.5).clamp(0.0, s - 1.0);
    final y0 = v.floor(), y1 = math.min(y0 + 1, s - 1);
    final fy = v - y0;
    for (var x = 0; x < w; x++) {
      final u = ((x + 0.5) * s / w - 0.5).clamp(0.0, s - 1.0);
      final x0 = u.floor(), x1 = math.min(x0 + 1, s - 1);
      final fx = u - x0;
      final top = src[y0 * s + x0] * (1 - fx) + src[y0 * s + x1] * fx;
      final bottom = src[y1 * s + x0] * (1 - fx) + src[y1 * s + x1] * fx;
      final p = top * (1 - fy) + bottom * fy;
      final t = ((p - _rampLow) / (_rampHigh - _rampLow)).clamp(0.0, 1.0);
      out[y * w + x] = (t * 255).round();
    }
  }
  return out;
}
