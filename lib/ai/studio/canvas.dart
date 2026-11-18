import 'dart:math' as math;

import 'package:image/image.dart' as img;

import 'studio_buffer.dart';

/// Canvas proportions: 4:5 portrait, the shape of the item photo frame and
/// of most shop product shots (DECISIONS D-42, D-44), so the polished
/// cut-out fills the frame without letterboxing.
const canvasAspect = 4 / 5;

/// The garment takes this share of the canvas in its limiting direction.
const garmentFill = 0.85;

/// Longest canvas edge, as for stored cut-outs.
const maxCanvasEdge = 1024;

/// [b] trimmed to its garment and centred on a transparent 4:5 canvas where
/// it fills [garmentFill] of the limiting side. `null` when [b] has no
/// visible pixels. Scales down only (never enlarges a small cut-out past
/// its own pixels) to respect [maxCanvasEdge].
StudioBuffer? placeOnCanvas(StudioBuffer b) {
  var left = b.width, top = b.height, right = -1, bottom = -1;
  for (var i = 0; i < b.pixels; i++) {
    if (b.alphaAt(i) == 0) continue;
    final x = i % b.width, y = i ~/ b.width;
    if (x < left) left = x;
    if (x > right) right = x;
    if (y < top) top = y;
    if (y > bottom) bottom = y;
  }
  if (right < 0) return null;
  final gw = right - left + 1, gh = bottom - top + 1;

  // Canvas at the garment's own resolution, scaled down to the edge limit.
  final ch = math.max(gh / garmentFill, gw / canvasAspect / garmentFill);
  final scale = math.min(1.0, maxCanvasEdge / ch);
  // Exactly 4:5: the height is a multiple of 5 (rounding moves the 85% by
  // at most 2 pixels).
  final h = (ch * scale / 5).round().clamp(1, maxCanvasEdge ~/ 5) * 5;
  final w = h * 4 ~/ 5;

  var garment = img.copyCrop(
    b.toImage(),
    x: left,
    y: top,
    width: gw,
    height: gh,
  );
  if (scale < 1) {
    garment = img.copyResize(
      garment,
      width: math.max(1, (gw * scale).round()),
      height: math.max(1, (gh * scale).round()),
      interpolation: img.Interpolation.average,
    );
  }
  final canvas = img.Image(width: w, height: h, numChannels: 4);
  img.compositeImage(
    canvas,
    garment,
    dstX: (w - garment.width) ~/ 2,
    dstY: (h - garment.height) ~/ 2,
    blend: img.BlendMode.direct,
  );
  return StudioBuffer.fromImage(canvas);
}
