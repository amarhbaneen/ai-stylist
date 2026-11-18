import 'dart:math' as math;

import 'package:image/image.dart' as img;

import 'studio_buffer.dart';

/// Smallest and largest tilt corrected, in degrees (DECISIONS D-44). Below
/// the minimum it is not worth resampling; above the maximum the garment is
/// probably meant to lie that way (or the axis is unreliable).
const minTilt = 2.0;
const maxTilt = 15.0;

/// A shape must be at least this elongated for its axis to mean anything:
/// (λ1 − λ2) / (λ1 + λ2) of the mask's second moments.
const minElongation = 0.08;

/// How far the garment's principal axis is from upright (or level), in
/// degrees, positive = clockwise. `null` when the shape is too round to
/// tell or has no pixels.
double? tiltDegrees(StudioBuffer b) {
  var n = 0;
  var sx = 0.0, sy = 0.0;
  for (var i = 0; i < b.pixels; i++) {
    if (b.alphaAt(i) < solidAlpha) continue;
    n++;
    sx += i % b.width;
    sy += i ~/ b.width;
  }
  if (n < 16) return null;
  final cx = sx / n, cy = sy / n;
  var mxx = 0.0, myy = 0.0, mxy = 0.0;
  for (var i = 0; i < b.pixels; i++) {
    if (b.alphaAt(i) < solidAlpha) continue;
    final dx = i % b.width - cx, dy = i ~/ b.width - cy;
    mxx += dx * dx;
    myy += dy * dy;
    mxy += dx * dy;
  }
  final trace = mxx + myy;
  final diff = math.sqrt((mxx - myy) * (mxx - myy) + 4 * mxy * mxy);
  if (trace == 0 || diff / trace < minElongation) return null;
  // Angle of the major axis from the x axis (y grows downwards).
  final theta = 0.5 * math.atan2(2 * mxy, mxx - myy) * 180 / math.pi;
  // Distance to the nearest of 0° or ±90°, in (-45, 45].
  var tilt = theta % 90;
  if (tilt > 45) tilt -= 90;
  return tilt;
}

/// [b] rotated upright when its tilt is between [minTilt] and [maxTilt]
/// degrees; otherwise [b] itself. The canvas grows so nothing is cut off,
/// and new corners are transparent.
StudioBuffer straighten(StudioBuffer b) {
  final tilt = tiltDegrees(b);
  if (tilt == null || tilt.abs() < minTilt || tilt.abs() > maxTilt) return b;
  final rotated = img.copyRotate(
    b.toImage(),
    angle: -tilt,
    interpolation: img.Interpolation.cubic,
  );
  return StudioBuffer.fromImage(rotated);
}
