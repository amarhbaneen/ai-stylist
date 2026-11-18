import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ai_stylist/ai/segmentation/garment_segmenter.dart';
import 'package:ai_stylist/ai/segmentation/person_mask.dart';
import 'package:ai_stylist/ai/segmentation/segmentation_labels.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:wardrobe_domain/wardrobe_domain.dart';

/// Two channels: background and a TOP class, on a [size] × [size] grid.
SegmentationLabels _labels(int size) => SegmentationLabels.tryParse(
  jsonEncode({
    'schemaVersion': 1,
    'task': 'garment-segmentation',
    'input': {'name': 'image', 'size': size},
    'minAreaShare': 0.01,
    'classes': [
      {'index': 0, 'label': 'background'},
      {'index': 1, 'label': 'shirt', 'category': 'TOP'},
    ],
  }),
)!;

/// Garment probability 0.9 where [garment] is true, else 0.05.
Float32List _probs(List<bool> garment) {
  final out = Float32List(garment.length * 2);
  for (var i = 0; i < garment.length; i++) {
    final g = garment[i] ? 0.9 : 0.05;
    out[i * 2] = 1 - g;
    out[i * 2 + 1] = g;
  }
  return out;
}

/// Person-model output (6 channels): "clothes" inside the column range
/// [from, to), background elsewhere, on a square grid.
Float32List _worn(int size, int from, int to) {
  final out = Float32List(size * size * personClasses);
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final base = (y * size + x) * personClasses;
      out[base + (x >= from && x < to ? 4 : 0)] = 1;
    }
  }
  return out;
}

void main() {
  group('wornMask', () {
    const size = 8;

    test('clothes and accessories count as worn; skin and hair do not', () {
      final out = Float32List(size * size * personClasses);
      for (var i = 0; i < size * size; i++) {
        // hair, body skin, face skin, clothes, accessory, background...
        out[i * personClasses + const [1, 2, 3, 4, 5, 0, 4, 4][i % 8]] = 1;
      }
      final mask = wornMask(out, size)!;
      expect(mask.sublist(0, 8), [0, 0, 0, 1, 1, 0, 1, 1]);
    });

    test('no person (a flat-lay): no mask', () {
      final out = Float32List(size * size * personClasses);
      for (var i = 0; i < size * size; i++) {
        out[i * personClasses] = 1;
      }
      out[0] = 0;
      out[4] = 1; // one clothes pixel: under minPersonShare
      expect(wornMask(out, size), isNull);
    });

    test('wrong length is rejected', () {
      expect(() => wornMask(Float32List(5), size), throwsArgumentError);
    });
  });

  group('restrictToWorn', () {
    const size = 16;

    Float32List worn(int from, int to) =>
        wornMask(_worn(size, from, to), size)!;

    test('drops garment pixels away from what is worn (the chair case)', () {
      // The garment model marks the whole width as clothing; the person
      // wears clothes only in columns 4–11.
      final probs = _probs(List.filled(size * size, true));
      final out = restrictToWorn(
        probs,
        size: size,
        classes: 2,
        worn: worn(4, 12),
        wornSize: size,
      );

      double garment(int x, int y) => out[(y * size + x) * 2 + 1];
      double background(int x, int y) => out[(y * size + x) * 2];
      expect(garment(8, 8), closeTo(0.9, 1e-6));
      // Within the grow radius of the edge: kept.
      expect(garment(4 - personGrowRadius, 8), closeTo(0.9, 1e-6));
      // Far away: all background.
      expect(garment(0, 8), 0);
      expect(background(0, 8), closeTo(1, 1e-6));
    });

    test('unsure worn pixels are dropped, sure ones kept', () {
      final probs = _probs(List.filled(size * size, true));
      double at(double w) => restrictToWorn(
        probs,
        size: size,
        classes: 2,
        worn: Float32List(size * size)..fillRange(0, size * size, w),
        wornSize: size,
      )[1];
      expect(at(wornLow), 0);
      expect(at(wornHigh), closeTo(0.9, 1e-6));
      expect(at(0.5), closeTo(0.45, 1e-6));
    });

    test('probabilities still sum to one', () {
      final probs = _probs([for (var i = 0; i < size * size; i++) i.isEven]);
      final w = Float32List.fromList([
        for (var i = 0; i < size * size; i++) (i % 7) / 6,
      ]);
      final out = restrictToWorn(
        probs,
        size: size,
        classes: 2,
        worn: w,
        wornSize: size,
      );
      for (var i = 0; i < size * size; i++) {
        expect(out[i * 2] + out[i * 2 + 1], closeTo(1, 1e-5));
      }
    });

    test('a mask of another size is scaled to the garment grid', () {
      final probs = _probs(List.filled(size * size, true));
      final out = restrictToWorn(
        probs,
        size: size,
        classes: 2,
        worn: wornMask(_worn(8, 0, 4), 8)!,
        wornSize: 8,
      );
      expect(out[(8 * size + 2) * 2 + 1], closeTo(0.9, 1e-6));
      expect(out[(8 * size + 15) * 2 + 1], 0);
    });

    test('wrong lengths are rejected', () {
      expect(
        () => restrictToWorn(
          Float32List(3),
          size: size,
          classes: 2,
          worn: Float32List(size * size),
          wornSize: size,
        ),
        throwsArgumentError,
      );
    });
  });

  group('GarmentSegmenter with a person model', () {
    const size = 16;
    late Directory tmp;
    late String photo;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('person_mask_test');
      photo = p.join(tmp.path, 'photo.png');
      await File(photo).writeAsBytes(
        img.encodePng(
          img.Image(width: 32, height: 32)..clear(img.ColorRgb8(200, 200, 200)),
        ),
      );
    });

    tearDown(() => tmp.delete(recursive: true));

    GarmentSegmenter segmenter(Result<PersonModel> person) => GarmentSegmenter(
      open: () async => Success((
        _Session(_probs(List.filled(size * size, true))),
        _labels(size),
      )),
      openPerson: () async => person,
    );

    test('the cut-out covers only the person', () async {
      final person = _Session(_worn(size, 4, 12));
      final found = (await segmenter(
        Success((person, size)),
      ).findGarments(photo)).valueOrNull!;

      final g = found.single;
      // Columns 2–13 of 16 (worn plus grow radius), not the full width.
      expect(g.areaShare, closeTo(12 / 16, 0.01));
      // The person model gets RGB scaled to 0–1.
      expect(person.inputs.single.every((v) => v >= 0 && v <= 1), isTrue);
      expect(person.inputs.single.first, closeTo(200 / 255, 0.01));
    });

    test('a person model that fails is ignored', () async {
      final found = (await segmenter(
        const Failure(ModelUnavailableFailure('missing')),
      ).findGarments(photo)).valueOrNull!;
      expect(found.single.areaShare, closeTo(1, 0.01));
    });

    test('a person model that throws is ignored', () async {
      final found = (await segmenter(
        Success((_Session(null), size)),
      ).findGarments(photo)).valueOrNull!;
      expect(found.single.areaShare, closeTo(1, 0.01));
    });

    test('closing closes both sessions', () async {
      final person = _Session(_worn(size, 0, size));
      final s = segmenter(Success((person, size)));
      await s.findGarments(photo);
      await s.close();
      expect(person.closed, isTrue);
    });
  });
}

/// Returns scripted output, or throws when given `null`.
final class _Session implements SegmentationSession {
  _Session(this.output);

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
