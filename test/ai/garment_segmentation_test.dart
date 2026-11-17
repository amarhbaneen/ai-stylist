import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ai_stylist/ai/color/color_extractor.dart';
import 'package:ai_stylist/ai/garment/garment_classifier.dart';
import 'package:ai_stylist/ai/segmentation/cutout_renderer.dart';
import 'package:ai_stylist/ai/segmentation/garment_regions.dart';
import 'package:ai_stylist/ai/segmentation/garment_segmenter.dart';
import 'package:ai_stylist/ai/segmentation/segmentation_labels.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:wardrobe_domain/wardrobe_domain.dart';

/// A tiny 4-class table: background, two TOP classes, one BOTTOM class.
String _labelsJson({
  int size = 4,
  double minAreaShare = 0.1,
  List<Map<String, Object?>>? classes,
}) => jsonEncode({
  'schemaVersion': 1,
  'task': 'garment-segmentation',
  'input': {'name': 'image', 'size': size},
  'minAreaShare': minAreaShare,
  'classes':
      classes ??
      [
        {'index': 0, 'label': 'background'},
        {'index': 1, 'label': 'shirt', 'category': 'TOP'},
        {'index': 2, 'label': 'sweater', 'category': 'TOP'},
        {'index': 3, 'label': 'pants', 'category': 'BOTTOM'},
      ],
});

SegmentationLabels _labels({int size = 4, double minAreaShare = 0.1}) =>
    SegmentationLabels.tryParse(
      _labelsJson(size: size, minAreaShare: minAreaShare),
    )!;

/// Probabilities from a per-pixel class map: [p] for the class, the rest
/// shared equally among the other classes.
Float32List _probs(List<int> classOf, {int channels = 4, double p = 0.9}) {
  final out = Float32List(classOf.length * channels);
  final rest = (1 - p) / (channels - 1);
  for (var i = 0; i < classOf.length; i++) {
    for (var k = 0; k < channels; k++) {
      out[i * channels + k] = k == classOf[i] ? p : rest;
    }
  }
  return out;
}

void main() {
  group('SegmentationLabels', () {
    test('parses the bundled table', () {
      final labels = SegmentationLabels.tryParse(
        File('assets/models/garment-seg.labels.json').readAsStringSync(),
      )!;
      expect(labels.inputSize, 256);
      expect(labels.minAreaShare, 0.01);
      expect(labels.classes, hasLength(24));
      expect(labels.classes.first.category, isNull);
      expect(labels.classes[14].label, 'shoe');
      expect(labels.classes[14].category, GarmentCategory.footwear);
    });

    test('rejects tables it does not match', () {
      final bad = [
        'not json',
        _labelsJson().replaceFirst('garment-segmentation', 'other'),
        _labelsJson(minAreaShare: 0),
        _labelsJson(
          classes: [
            {'index': 0, 'label': 'background'},
            {'index': 2, 'label': 'shirt', 'category': 'TOP'},
          ],
        ),
        _labelsJson(
          classes: [
            {'index': 0, 'label': 'background', 'category': 'TOP'},
            {'index': 1, 'label': 'shirt', 'category': 'TOP'},
          ],
        ),
        _labelsJson(
          classes: [
            {'index': 0, 'label': 'background'},
            {'index': 1, 'label': 'shirt', 'category': 'HATS'},
          ],
        ),
        _labelsJson(
          classes: [
            {'index': 0, 'label': 'background'},
            {'index': 1, 'label': 'shirt', 'category': 'TOP'},
            {'index': 2, 'label': 'shirt', 'category': 'TOP'},
          ],
        ),
      ];
      for (final text in bad) {
        expect(SegmentationLabels.tryParse(text), isNull, reason: text);
      }
    });
  });

  group('findRegions', () {
    test('groups classes by category, largest first', () {
      // Row-major 4x4: a shirt/sweater top half, pants in row 3.
      final regions = findRegions(
        _probs([
          1, 1, 2, 2, //
          1, 2, 2, 0, //
          3, 3, 3, 0, //
          0, 0, 0, 0, //
        ]),
        _labels(),
      );
      expect(regions.map((r) => r.category), [
        GarmentCategory.top,
        GarmentCategory.bottom,
      ]);
      expect(regions[0].areaShare, 7 / 16);
      expect(regions[1].areaShare, 3 / 16);
      // Mixed shirt and sweater pixels form one garment.
      expect(regions[0].alpha[0], closeTo(1 - 0.1 / 3, 1e-6));
      expect(regions[0].alpha[2], closeTo(1 - 0.1 / 3, 1e-6));
      expect(regions[0].alpha[8], 0);
      expect(regions[1].alpha[8], closeTo(1 - 0.1 / 3, 1e-6));
    });

    test('one garment uses everything that is not background', () {
      final regions = findRegions(
        _probs([1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
        _labels(),
      );
      expect(regions, hasLength(1));
      // Background pixels keep a small, soft garment value.
      expect(regions.single.alpha[15], closeTo(0.1, 1e-6));
    });

    test('drops small finds and gives their pixels to a kept one', () {
      // One pants pixel (1/16 < 0.1) inside a top.
      final regions = findRegions(
        _probs([1, 1, 1, 3, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0]),
        _labels(),
      );
      expect(regions.single.category, GarmentCategory.top);
      expect(regions.single.alpha[3], greaterThan(0.9));
    });

    test('removes specks far from the garment', () {
      // 8x8: a 4x4 top in the corner and a lone top pixel far away.
      final map = List.filled(64, 0);
      for (final i in [0, 1, 2, 3, 8, 9, 10, 11, 16, 17, 18, 19, 24, 25, 26]) {
        map[i] = 1;
      }
      map[27] = 2;
      map[63] = 1;
      final region = findRegions(
        _probs(map),
        _labels(size: 8, minAreaShare: 0.05),
      ).single;
      expect(region.alpha[0], greaterThan(0.9));
      expect(region.alpha[63], 0);
      expect(region.areaShare, 16 / 64);
    });

    test('a garment that is small without its specks is dropped', () {
      // 8x8: a 16-pixel top (rows 0-1); pants of one 10-pixel part
      // (rows 6-7, columns 3-7) and a lone pixel. With the speck the pants
      // reach 11/64; without it they fall below, so they are dropped.
      final map = List.filled(64, 0);
      for (var i = 0; i < 16; i++) {
        map[i] = 1;
      }
      for (final row in [6, 7]) {
        for (var col = 3; col < 8; col++) {
          map[row * 8 + col] = 3;
        }
      }
      map[32] = 3;
      final regions = findRegions(
        _probs(map),
        _labels(size: 8, minAreaShare: 11 / 64),
      );
      expect(regions.map((r) => r.category), [GarmentCategory.top]);
      // The lone pixel is gone from the remaining mask too.
      expect(regions.single.alpha[32], 0);
    });

    test('nothing above the threshold finds nothing', () {
      expect(findRegions(_probs(List.filled(16, 0)), _labels()), isEmpty);
    });

    test('rejects output of the wrong size', () {
      expect(
        () => findRegions(Float32List(10), _labels()),
        throwsArgumentError,
      );
    });
  });

  group('renderCutout', () {
    final photo = img.Image(width: 40, height: 40)
      ..clear(img.ColorRgb8(200, 30, 30));
    GarmentRegion region(List<double> alpha) => GarmentRegion(
      category: GarmentCategory.top,
      areaShare: 0.25,
      alpha: Float32List.fromList(alpha),
      size: 4,
    );

    test('crops to the garment and makes the rest transparent', () {
      // Top-left 2x2 of the 4x4 mask.
      final cutout = renderCutout(
        photo,
        region([1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
        margin: 0,
      )!;
      final image = img.decodePng(cutout.image)!;
      expect(image.hasAlpha, isTrue);
      expect((cutout.width, cutout.height), (image.width, image.height));
      expect(image.width, inInclusiveRange(18, 24));
      expect(image.height, inInclusiveRange(18, 24));
      final inside = image.getPixel(2, 2);
      expect((inside.r, inside.g, inside.b, inside.a), (200, 30, 30, 255));
      final edge = image.getPixel(image.width - 1, image.height - 1);
      expect(edge.a, lessThan(255));
      expect(img.decodePng(cutout.thumbnail), isNotNull);
    });

    test('limits the thumbnail size', () {
      final cutout = renderCutout(
        photo,
        region(List.filled(16, 1)),
        thumbnailEdge: 10,
      )!;
      final thumb = img.decodePng(cutout.thumbnail)!;
      expect(thumb.width, 10);
      expect(thumb.height, 10);
    });

    test('an empty mask gives no cut-out', () {
      expect(renderCutout(photo, region(List.filled(16, 0))), isNull);
    });
  });

  group('GarmentSegmenter', () {
    late Directory tmp;
    late String photoPath;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('segmenter_test');
      photoPath = p.join(tmp.path, 'photo.png');
      await File(photoPath).writeAsBytes(
        img.encodePng(
          img.Image(width: 16, height: 12)..clear(img.ColorRgb8(10, 20, 200)),
        ),
      );
    });

    tearDown(() => tmp.delete(recursive: true));

    GarmentSegmenter segmenter(_FakeSession session) =>
        GarmentSegmenter(open: () async => Success((session, _labels())));

    test('finds and cuts out each garment', () async {
      final session = _FakeSession(
        _probs([1, 1, 3, 3, 1, 1, 3, 3, 0, 0, 0, 0, 0, 0, 0, 0]),
      );
      final found = (await segmenter(session).findGarments(photoPath))
          .valueOrNull!;
      expect(found.map((g) => g.category), [
        GarmentCategory.top,
        GarmentCategory.bottom,
      ]);
      expect(img.decodePng(found.first.cutout.image), isNotNull);
      // The model saw the whole photo at its input size.
      expect(session.inputs.single, hasLength(4 * 4 * 3));
    });

    test('a model that cannot open is a typed failure', () async {
      final s = GarmentSegmenter(
        open: () async => const Failure(ModelUnavailableFailure('missing')),
      );
      final result = await s.findGarments(photoPath);
      expect((result as Failure).failure, isA<ModelUnavailableFailure>());
    });

    test('output of the wrong size is a typed failure', () async {
      final result = await segmenter(_FakeSession(Float32List(5)))
          .findGarments(photoPath);
      expect((result as Failure).failure, isA<ModelCorruptFailure>());
    });

    test('an inference error is a typed failure', () async {
      final result = await segmenter(_FakeSession(null))
          .findGarments(photoPath);
      expect((result as Failure).failure, isA<InferenceFailure>());
    });

    test('an unreadable photo is a typed failure', () async {
      final result = await segmenter(_FakeSession(Float32List(4 * 4 * 4)))
          .findGarments(p.join(tmp.path, 'missing.jpg'));
      expect((result as Failure).failure, isA<UnsupportedImageFailure>());
    });

    test('closes the session and refuses later calls', () async {
      final session = _FakeSession(Float32List(4 * 4 * 4));
      final s = segmenter(session);
      await s.findGarments(photoPath);
      await s.close();
      expect(session.closed, isTrue);
      final result = await s.findGarments(photoPath);
      expect((result as Failure).failure, isA<ModelUnavailableFailure>());
    });
  });

  group('transparent cut-outs in analysis', () {
    test('colour ignores transparent pixels', () {
      // Left half red (kept), right half blue (transparent).
      const w = 8, h = 8;
      final rgb = Uint8List(w * h * 3);
      final opaque = Uint8List(w * h);
      for (var i = 0; i < w * h; i++) {
        final left = i % w < w / 2;
        rgb[i * 3] = left ? 220 : 20;
        rgb[i * 3 + 2] = left ? 20 : 220;
        opaque[i] = left ? 1 : 0;
      }
      final result = const ColorExtractor().analyzeRgb(
        rgb,
        w,
        h,
        opaque: opaque,
      );
      expect(result.primary, ColorFamily.red);
      expect(result.shares.keys, [ColorFamily.red]);
      expect(result.backgroundRemoved, isTrue);
    });

    test('the classifier sees transparent pixels as white', () {
      final image = img.Image(width: 2, height: 2, numChannels: 4)
        ..clear(img.ColorRgba8(0, 0, 0, 0))
        ..setPixelRgba(0, 0, 10, 20, 30, 255);
      final pixels = pixelsOf(image, 2);
      expect(pixels.sublist(0, 3), [10, 20, 30]);
      expect(pixels.sublist(9, 12), [255, 255, 255]);
    });
  });
}

/// Returns scripted probabilities, or throws when given `null`.
final class _FakeSession implements SegmentationSession {
  _FakeSession(this.output);

  final Float32List? output;
  final inputs = <Float32List>[];
  var closed = false;

  @override
  Future<Float32List> run(Float32List rgb) async {
    inputs.add(rgb);
    return output ?? (throw StateError('native error'));
  }

  @override
  Future<void> close() async => closed = true;
}
