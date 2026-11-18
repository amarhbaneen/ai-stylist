import 'dart:math' as math;

import 'package:image/image.dart' as img;

import 'canvas.dart';
import 'defringe.dart';
import 'inpaint.dart';
import 'light.dart';
import 'mask_cleanup.dart';
import 'straighten.dart';
import 'studio_buffer.dart';

/// Which studio steps run (all by default). For tests and diagnostics.
final class StudioOptions {
  const StudioOptions({
    this.cleanMask = true,
    this.defringe = true,
    this.straighten = true,
    this.light = true,
    this.canvas = true,
  });

  final bool cleanMask;
  final bool defringe;
  final bool straighten;
  final bool light;
  final bool canvas;
}

/// Turns a raw garment cut-out into a shop-style product image, using only
/// its own pixels (DECISIONS D-44). Pure and isolate-safe.
///
/// 1. Mask clean-up: pinholes and hairline cracks (closing radius ≈1% of
///    the long edge; holes up to 2% of the garment) become garment.
/// 2. Those pixels get colour diffused from around them (push-pull).
/// 3. Edges lose the background tint, then get a light feather.
/// 4. A tilt of 2°–15° is straightened.
/// 5. Light: levels and a weak white balance, capped in ΔE.
/// 6. Centred on a transparent 4:5 canvas at 85%.
///
/// Returns `null` when the cut-out has no garment pixels; callers then keep
/// the raw cut-out.
img.Image? polishCutout(
  img.Image cutout, [
  StudioOptions options = const StudioOptions(),
]) {
  var b = StudioBuffer.fromImage(cutout);
  final mask = solidMask(b);
  if (!mask.contains(1)) return null;

  if (options.cleanMask) {
    final radius = math.max(1, (math.max(b.width, b.height) * 0.01).round());
    final fill = holesToFill(mask, b.width, b.height, closeRadius: radius);
    b = fillHoles(b, fill);
  }
  if (options.defringe) b = feather(defringe(b));
  if (options.straighten) b = straighten(b);
  if (options.light) b = correctLight(b);
  if (options.canvas) {
    final placed = placeOnCanvas(b);
    if (placed == null) return null;
    b = placed;
  }
  return b.toImage();
}
