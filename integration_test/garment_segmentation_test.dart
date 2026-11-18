// On-device check of the bundled garment and person segmentation models
// (D-40, D-41). Runs the real LiteRT runtime and models; nothing is sent
// over the network.
//
//   flutter test integration_test/garment_segmentation_test.dart -d <device>
import 'dart:io';

import 'package:ai_stylist/ai/model_registry.dart';
import 'package:ai_stylist/ai/segmentation/garment_segmenter.dart';
import 'package:ai_stylist/ai/segmentation/litert_segmentation_session.dart';
import 'package:ai_stylist/ai/segmentation/person_mask.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

/// A red T-shirt silhouette on a light backdrop, at the app's working size
/// (synthetic: this checks the runtime and timing, not accuracy).
List<int> _tee() {
  final image = img.Image(width: 1024, height: 768);
  img.fill(image, color: img.ColorRgb8(236, 236, 231));
  final red = img.ColorRgb8(190, 30, 40);
  img.fillRect(image, x1: 400, y1: 170, x2: 624, y2: 690, color: red);
  img.fillRect(image, x1: 280, y1: 170, x2: 744, y2: 320, color: red);
  return img.encodeJpg(image, quality: 90);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the bundled segmentation model loads and runs on this device', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final registry = await ModelRegistry.fromManifest((key) async {
        final data = await rootBundle.load(key);
        return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      });
      final dir = await Directory.systemTemp.createTemp('segmentation');
      final photo = File('${dir.path}/tee.jpg')..writeAsBytesSync(_tee());

      final openWatch = Stopwatch()..start();
      var openMs = 0;
      var personOpened = false;
      final segmenter = GarmentSegmenter(
        open: () async {
          final r = await openSegmentationModel(registry);
          openMs = openWatch.elapsedMilliseconds;
          return r;
        },
        openPerson: () async {
          final r = await openPersonModel(registry);
          personOpened = r.isSuccess;
          return r;
        },
      );

      final first = await segmenter.findGarments(photo.path);
      expect(first, isA<Success<List<FoundGarment>>>(), reason: '$first');
      // The person model must load with the bundled runtime (no MediaPipe
      // custom ops, D-41).
      expect(personOpened, isTrue);
      final latencies = <int>[];
      for (var i = 0; i < 5; i++) {
        final w = Stopwatch()..start();
        final r = await segmenter.findGarments(photo.path);
        latencies.add(w.elapsedMilliseconds);
        expect(r, isA<Success<List<FoundGarment>>>());
      }
      latencies.sort();

      final found = (first as Success<List<FoundGarment>>).value;
      final summary = [
        for (final g in found)
          '${g.category.code}@${g.areaShare.toStringAsFixed(3)}'
              '(${g.cutout.width}x${g.cutout.height})',
      ].join(',');
      for (final g in found) {
        final png = img.decodePng(g.cutout.image);
        expect(png, isNotNull);
        expect(png!.hasAlpha, isTrue);
      }

      // ignore: avoid_print
      print(
        'DEVICE_CHECK_SEG openMs=$openMs personModel=$personOpened '
        'p50Ms=${latencies[latencies.length ~/ 2]} maxMs=${latencies.last} '
        'garments=[$summary]',
      );
      await segmenter.close();
      await dir.delete(recursive: true);
    });
  });
}
