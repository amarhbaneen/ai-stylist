import 'dart:io';
import 'dart:typed_data';

import 'package:ai_stylist/ai/color/color_extractor.dart';
import 'package:ai_stylist/ai/color/color_naming.dart';
import 'package:ai_stylist/ai/color/color_space.dart';
import 'package:ai_stylist/ai/color/image_color_analyzer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:wardrobe_domain/wardrobe_domain.dart';

typedef Rgb = (int, int, int);

/// Synthetic 64x64 image: [background] with a centred garment-shaped block
/// filled by [paint] (given x, y inside the block).
Uint8List _garment(Rgb background, Rgb Function(int x, int y) paint) {
  const size = 64;
  final rgb = Uint8List(size * size * 3);
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final inside = x >= 14 && x < 50 && y >= 10 && y < 58;
      final (r, g, b) = inside ? paint(x - 14, y - 10) : background;
      final o = (y * size + x) * 3;
      rgb[o] = r;
      rgb[o + 1] = g;
      rgb[o + 2] = b;
    }
  }
  return rgb;
}

const _offWhite = (236, 236, 231);
const _extractor = ColorExtractor();

void main() {
  group('nameColor', () {
    // Representative sRGB values for each family.
    const cases = <(Rgb, ColorFamily)>[
      ((10, 10, 10), ColorFamily.black),
      ((250, 250, 245), ColorFamily.white),
      ((128, 128, 128), ColorFamily.grey),
      ((245, 245, 220), ColorFamily.beige),
      ((210, 180, 140), ColorFamily.beige),
      ((139, 69, 19), ColorFamily.brown),
      ((0, 0, 128), ColorFamily.navy),
      ((31, 42, 74), ColorFamily.navy),
      ((0, 0, 255), ColorFamily.blue),
      ((135, 206, 235), ColorFamily.blue),
      ((0, 128, 0), ColorFamily.green),
      ((85, 107, 47), ColorFamily.olive),
      ((128, 128, 0), ColorFamily.olive),
      ((255, 255, 0), ColorFamily.yellow),
      ((255, 165, 0), ColorFamily.orange),
      ((255, 0, 0), ColorFamily.red),
      ((220, 20, 60), ColorFamily.red),
      ((128, 0, 0), ColorFamily.burgundy),
      ((128, 0, 32), ColorFamily.burgundy),
      ((255, 192, 203), ColorFamily.pink),
      ((255, 105, 180), ColorFamily.pink),
      ((128, 0, 128), ColorFamily.purple),
    ];
    for (final ((r, g, b), family) in cases) {
      test('rgb($r,$g,$b) is ${family.name}', () {
        expect(nameColor(Lab.fromRgb(r, g, b)), family);
      });
    }
  });

  group('ColorExtractor', () {
    test('solid navy garment on a plain background', () {
      final result = _extractor.analyzeRgb(
        _garment(_offWhite, (_, _) => (31, 42, 74)),
        64,
        64,
      );
      expect(result.primary, ColorFamily.navy);
      expect(result.secondary, isEmpty);
      expect(result.backgroundRemoved, isTrue);
      expect(result.confidence, greaterThan(0.9));
    });

    test('red and white stripes give red primary, white secondary', () {
      final result = _extractor.analyzeRgb(
        // Wider red stripes so red dominates.
        _garment((60, 60, 60), (_, y) => y % 5 < 3 ? (200, 30, 40) : _offWhite),
        64,
        64,
      );
      expect(result.primary, ColorFamily.red);
      expect(result.secondary, contains(ColorFamily.white));
    });

    test('many equal colours are reported as multicolour', () {
      const palette = <Rgb>[
        (220, 30, 40),
        (30, 140, 60),
        (40, 80, 220),
        (250, 210, 30),
      ];
      final result = _extractor.analyzeRgb(
        _garment(_offWhite, (x, y) => palette[(x ~/ 9 + y ~/ 12) % 4]),
        64,
        64,
      );
      expect(result.primary, ColorFamily.multicolor);
      expect(result.secondary.length, greaterThanOrEqualTo(3));
    });

    test('a garment the same colour as the background is still measured', () {
      final result = _extractor.analyzeRgb(
        _garment(_offWhite, (_, _) => _offWhite),
        64,
        64,
      );
      expect(result.primary, ColorFamily.white);
      expect(result.backgroundRemoved, isFalse);
    });

    test('a busy background is not removed', () {
      final rgb = _garment((0, 0, 0), (_, _) => (139, 69, 19));
      // Make the border non-uniform.
      for (var x = 0; x < 64; x += 2) {
        rgb[x * 3] = 255;
        rgb[x * 3 + 1] = 255;
        rgb[x * 3 + 2] = 255;
      }
      final result = _extractor.analyzeRgb(rgb, 64, 64);
      expect(result.backgroundRemoved, isFalse);
      expect(result.shares.keys, contains(ColorFamily.brown));
    });

    test('is deterministic', () {
      final rgb = _garment(
        _offWhite,
        (x, y) => (x * 7 % 256, y * 5 % 256, (x + y) * 3 % 256),
      );
      final a = _extractor.analyzeRgb(rgb, 64, 64);
      final b = _extractor.analyzeRgb(rgb, 64, 64);
      expect(a.primary, b.primary);
      expect(a.shares, b.shares);
    });

    test('shares sum to 1 and empty input is handled', () {
      final r = _extractor.analyzeRgb(
        _garment(_offWhite, (x, _) => x < 18 ? (0, 128, 0) : (0, 0, 255)),
        64,
        64,
      );
      expect(
        r.shares.values.fold<double>(0, (a, b) => a + b),
        closeTo(1, 1e-9),
      );
      expect(_extractor.analyzeRgb(Uint8List(0), 0, 0).primary, isNull);
    });
  });

  group('ImageColorAnalyzer', () {
    late Directory tmp;
    setUp(() async => tmp = await Directory.systemTemp.createTemp('color'));
    tearDown(() => tmp.delete(recursive: true));

    test('decodes a JPEG file on an isolate and names its colour', () async {
      final image = img.Image(width: 320, height: 400);
      img.fill(image, color: img.ColorRgb8(236, 236, 231));
      img.fillRect(
        image,
        x1: 80,
        y1: 60,
        x2: 240,
        y2: 360,
        color: img.ColorRgb8(46, 139, 87),
      );
      final path = p.join(tmp.path, 'thumb.jpg');
      await File(path).writeAsBytes(img.encodeJpg(image, quality: 85));

      final result = await const ImageColorAnalyzer().analyzeFile(path);

      expect(result.valueOrNull?.primary, ColorFamily.green);
    });

    test('an undecodable file is a typed failure', () async {
      final path = p.join(tmp.path, 'bad.jpg');
      await File(path).writeAsBytes([1, 2, 3]);
      final result = await const ImageColorAnalyzer().analyzeFile(path);
      expect((result as Failure).failure, isA<UnsupportedImageFailure>());
    });

    test('a missing file is a typed failure', () async {
      final result = await const ImageColorAnalyzer().analyzeFile(
        p.join(tmp.path, 'missing.jpg'),
      );
      expect((result as Failure).failure, isA<StorageFailure>());
    });
  });
}
