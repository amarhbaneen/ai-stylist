import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ai_stylist/ai/color/color_space.dart';
import 'package:ai_stylist/ai/studio/canvas.dart';
import 'package:ai_stylist/ai/studio/defringe.dart';
import 'package:ai_stylist/ai/studio/inpaint.dart';
import 'package:ai_stylist/ai/studio/light.dart';
import 'package:ai_stylist/ai/studio/mask_cleanup.dart';
import 'package:ai_stylist/ai/studio/straighten.dart';
import 'package:ai_stylist/ai/studio/studio_buffer.dart';
import 'package:ai_stylist/ai/studio/studio_polish.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// A [w] × [h] buffer where [inside] pixels have colour [rgb] (opaque) and
/// the rest are transparent.
StudioBuffer _shape(
  int w,
  int h,
  bool Function(int x, int y) inside, {
  List<int> rgb = const [40, 60, 120],
}) {
  final b = StudioBuffer.blank(w, h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (!inside(x, y)) continue;
      final i = (y * w + x) * 4;
      b.rgba
        ..[i] = rgb[0]
        ..[i + 1] = rgb[1]
        ..[i + 2] = rgb[2]
        ..[i + 3] = 255;
    }
  }
  return b;
}

List<int> _px(StudioBuffer b, int x, int y) {
  final i = (y * b.width + x) * 4;
  return b.rgba.sublist(i, i + 4);
}

void main() {
  group('mask clean-up', () {
    test('a pinhole inside the garment is filled', () {
      final b = _shape(40, 40, (x, y) => x >= 5 && x < 35 && y >= 5 && y < 35)
        ..rgba[(20 * 40 + 20) * 4 + 3] = 0;
      final fill = holesToFill(solidMask(b), 40, 40, closeRadius: 1);
      expect(fill[20 * 40 + 20], 1);
      expect(fill.where((v) => v == 1), hasLength(1));
    });

    test('a large hole is left (it may be real)', () {
      // 10 × 10 hole in a 30 × 30 garment: 11% of its area.
      final b = _shape(
        40,
        40,
        (x, y) =>
            x >= 5 &&
            x < 35 &&
            y >= 5 &&
            y < 35 &&
            !(x >= 15 && x < 25 && y >= 15 && y < 25),
      );
      final fill = holesToFill(solidMask(b), 40, 40, closeRadius: 1);
      expect(fill.contains(1), isFalse);
    });

    test('the background outside is never filled', () {
      final b = _shape(
        30,
        30,
        (x, y) => x >= 10 && x < 20 && y >= 10 && y < 20,
      );
      final fill = holesToFill(solidMask(b), 30, 30, closeRadius: 1);
      expect(fill[0], 0);
      expect(fill[29 * 30 + 29], 0);
    });

    test('closing then erosion keep a solid square the same', () {
      final m = solidMask(
        _shape(20, 20, (x, y) => x >= 4 && x < 16 && y >= 4 && y < 16),
      );
      expect(close(m, 20, 20, 2), m);
    });
  });

  group('hole fill (push-pull)', () {
    test('takes the colour around the hole, and makes it opaque', () {
      final b = _shape(30, 30, (x, y) => true, rgb: const [200, 40, 40])
        ..rgba[(15 * 30 + 15) * 4 + 3] = 0;
      final fill = Uint8List(900)..[15 * 30 + 15] = 1;
      final out = fillHoles(b, fill);
      expect(_px(out, 15, 15), [200, 40, 40, 255]);
      // Other pixels unchanged.
      expect(_px(out, 3, 3), [200, 40, 40, 255]);
    });
  });

  group('defringe', () {
    test('a halo edge takes the garment colour, keeping its alpha', () {
      // Navy garment; a soft edge column still tinted grey by a chair.
      final b = _shape(20, 10, (x, y) => x < 10, rgb: const [20, 30, 90]);
      for (var y = 0; y < 10; y++) {
        final i = (y * 20 + 10) * 4;
        b.rgba
          ..[i] = 150
          ..[i + 1] = 150
          ..[i + 2] = 150
          ..[i + 3] = 120;
      }
      final out = defringe(b);
      expect(_px(out, 10, 5), [20, 30, 90, 120]);
      // Interior and transparent pixels are untouched.
      expect(_px(out, 2, 5), [20, 30, 90, 255]);
      expect(_px(out, 15, 5)[3], 0);
    });

    test('feather softens only the edge band', () {
      final b = _shape(20, 20, (x, y) => x < 10);
      final out = feather(b);
      expect(out.alphaAt(5 * 20 + 2), 255);
      expect(out.alphaAt(5 * 20 + 9), lessThan(255));
      expect(out.alphaAt(5 * 20 + 15), 0);
    });
  });

  group('straighten', () {
    // A long bar (like a hanging shirt) rotated by [deg] degrees.
    StudioBuffer bar(double deg) {
      final t = deg * math.pi / 180;
      return _shape(120, 120, (x, y) {
        final dx = x - 60.0, dy = y - 60.0;
        final u = dx * math.cos(t) + dy * math.sin(t);
        final v = -dx * math.sin(t) + dy * math.cos(t);
        return u.abs() < 15 && v.abs() < 45;
      });
    }

    test('measures the tilt of a tilted shirt', () {
      expect(tiltDegrees(bar(8))!, closeTo(8, 1));
      expect(tiltDegrees(bar(-6))!, closeTo(-6, 1));
      expect(tiltDegrees(bar(0))!, closeTo(0, 0.5));
    });

    test('rotates a 2°–15° tilt upright', () {
      final out = straighten(bar(8));
      expect(tiltDegrees(out)!.abs(), lessThan(1.5));
    });

    test('leaves tiny and large tilts, and round shapes, alone', () {
      for (final b in [bar(1), bar(30)]) {
        expect(identical(straighten(b), b), isTrue);
      }
      final round = _shape(
        60,
        60,
        (x, y) => (x - 30) * (x - 30) + (y - 30) * (y - 30) < 400,
      );
      expect(tiltDegrees(round), isNull);
    });
  });

  group('light correction', () {
    StudioBuffer gradient(
      int from,
      int to, {
      List<int> tint = const [0, 0, 0],
    }) {
      final b = StudioBuffer.blank(64, 64);
      for (var i = 0; i < b.pixels; i++) {
        final v = from + ((to - from) * (i % 64) / 63).round();
        b.rgba
          ..[i * 4] = (v + tint[0]).clamp(0, 255)
          ..[i * 4 + 1] = (v + tint[1]).clamp(0, 255)
          ..[i * 4 + 2] = (v + tint[2]).clamp(0, 255)
          ..[i * 4 + 3] = 255;
      }
      return b;
    }

    double meanL(StudioBuffer b) {
      var t = 0.0;
      for (var i = 0; i < b.pixels; i++) {
        t += Lab.fromRgb(b.rgba[i * 4], b.rgba[i * 4 + 1], b.rgba[i * 4 + 2]).l;
      }
      return t / b.pixels;
    }

    test('a dark photo gets brighter, within the ΔE cap', () {
      final dark = gradient(30, 140);
      final out = correctLight(dark);
      expect(meanL(out), greaterThan(meanL(dark)));
      expect(meanDeltaE(dark, out), lessThanOrEqualTo(maxMeanDeltaE + 0.5));
    });

    test('a bright photo is not pushed further than the cap', () {
      final bright = gradient(120, 250);
      final out = correctLight(bright);
      expect(meanDeltaE(bright, out), lessThanOrEqualTo(maxMeanDeltaE + 0.5));
    });

    test('a white shirt on white stays white', () {
      final white = gradient(225, 250);
      final out = correctLight(white);
      expect(meanL(out), greaterThan(85));
      expect(meanDeltaE(white, out), lessThanOrEqualTo(maxMeanDeltaE + 0.5));
    });

    test('white balance is a weak, bounded pull', () {
      final c = measureLight(gradient(100, 200, tint: const [30, 0, -30]))!;
      for (final g in c.gains) {
        expect(g, inInclusiveRange(1 - maxWhiteBalance, 1 + maxWhiteBalance));
      }
      expect(c.gains[0], lessThan(1)); // too red → less red
      expect(c.gains[2], greaterThan(1));
    });

    test('a saturated garment keeps its hue', () {
      final red = _shape(40, 40, (x, y) => true, rgb: const [180, 30, 40]);
      final out = correctLight(red);
      final before = Lab.fromRgb(180, 30, 40);
      final p = _px(out, 10, 10);
      final after = Lab.fromRgb(p[0], p[1], p[2]);
      expect((before.hue - after.hue).abs(), lessThan(5));
    });
  });

  group('canvas', () {
    test('centres the garment on a 4:5 canvas at 85%', () {
      final b = _shape(
        200,
        200,
        (x, y) => x >= 50 && x < 150 && y >= 20 && y < 180,
      );
      final out = placeOnCanvas(b)!;
      expect(out.width / out.height, closeTo(canvasAspect, 0.01));
      // Limiting side: height 160 → canvas height 160 / 0.85.
      expect(out.height, closeTo(160 / garmentFill, 3));
      // Centred: equal transparent margins left and right.
      final row = out.height ~/ 2;
      var left = 0;
      while (out.alphaAt(row * out.width + left) == 0) {
        left++;
      }
      var right = 0;
      while (out.alphaAt(row * out.width + out.width - 1 - right) == 0) {
        right++;
      }
      expect((left - right).abs(), lessThanOrEqualTo(1));
    });

    test('large cut-outs are scaled down to the edge limit', () {
      final b = _shape(1400, 1400, (x, y) => true);
      final out = placeOnCanvas(b)!;
      expect(math.max(out.width, out.height), lessThanOrEqualTo(maxCanvasEdge));
    });

    test('an empty cut-out gives null', () {
      expect(placeOnCanvas(StudioBuffer.blank(10, 10)), isNull);
    });
  });

  group('polishCutout', () {
    test('a dull, tilted shirt with a pinhole and a halo comes out clean', () {
      const deg = 7.0;
      const t = deg * math.pi / 180;
      final image = img.Image(width: 200, height: 220, numChannels: 4);
      for (final p in image) {
        final dx = p.x - 100.0, dy = p.y - 110.0;
        final u = dx * math.cos(t) + dy * math.sin(t);
        final v = -dx * math.sin(t) + dy * math.cos(t);
        if (u.abs() < 50 && v.abs() < 80) {
          p
            ..r = 70
            ..g = 80
            ..b = 95
            ..a = 255;
        } else if (u.abs() < 53 && v.abs() < 83) {
          // Halo: background grey at half alpha.
          p
            ..r = 200
            ..g = 200
            ..b = 200
            ..a = 128;
        }
      }
      image.getPixel(100, 110).a = 0; // pinhole

      final out = StudioBuffer.fromImage(polishCutout(image)!);

      expect(out.width / out.height, closeTo(canvasAspect, 0.01));
      expect(tiltDegrees(out)!.abs(), lessThan(1.5));
      // No background grey left at the edges: every visible pixel is close
      // to the garment colour (after the bounded light correction).
      final garment = Lab.fromRgb(70, 80, 95);
      var worst = 0.0;
      for (var i = 0; i < out.pixels; i++) {
        if (out.alphaAt(i) < 40) continue;
        final d = garment.distanceTo(
          Lab.fromRgb(
            out.rgba[i * 4],
            out.rgba[i * 4 + 1],
            out.rgba[i * 4 + 2],
          ),
        );
        worst = math.max(worst, d);
      }
      expect(worst, lessThan(maxPixelDeltaE + 8));
      // The pinhole is gone: the centre is opaque.
      expect(out.alphaAt((out.height ~/ 2) * out.width + out.width ~/ 2), 255);
    });

    test('an empty cut-out gives null', () {
      expect(
        polishCutout(img.Image(width: 10, height: 10, numChannels: 4)),
        isNull,
      );
    });
  });
}
