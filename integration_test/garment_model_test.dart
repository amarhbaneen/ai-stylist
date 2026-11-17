// On-device check of the bundled garment classifier (D-38). Runs the real
// LiteRT runtime and model; nothing is sent over the network.
//
//   flutter test integration_test/garment_model_test.dart -d <device>
import 'dart:io';

import 'package:ai_stylist/ai/garment/garment_classifier.dart';
import 'package:ai_stylist/ai/garment/garment_model_loader.dart';
import 'package:ai_stylist/ai/model_registry.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

final class _Clock implements Clock {
  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}

/// A plain red T-shirt silhouette on a light backdrop (synthetic: this
/// checks the runtime, not accuracy).
List<int> _tee() {
  final image = img.Image(width: 320, height: 320);
  img.fill(image, color: img.ColorRgb8(236, 236, 231));
  img.fillRect(
    image,
    x1: 100,
    y1: 70,
    x2: 220,
    y2: 290,
    color: img.ColorRgb8(190, 30, 40),
  );
  img.fillRect(
    image,
    x1: 50,
    y1: 70,
    x2: 270,
    y2: 130,
    color: img.ColorRgb8(190, 30, 40),
  );
  return img.encodeJpg(image, quality: 90);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the bundled garment model loads and runs on this device', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final registry = await ModelRegistry.fromManifest((key) async {
        final data = await rootBundle.load(key);
        return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      });
      final dir = await Directory.systemTemp.createTemp('garment');
      final photo = File('${dir.path}/tee.jpg')..writeAsBytesSync(_tee());

      final openWatch = Stopwatch()..start();
      var openMs = 0;
      final classifier = GarmentClassifier(
        open: () async {
          final r = await openGarmentModel(registry);
          openMs = openWatch.elapsedMilliseconds;
          return r;
        },
        clock: _Clock(),
      );
      final input = AnalysisInput(
        itemId: 'device-check',
        imagePath: photo.path,
      );

      final first = await classifier.analyze(input);
      expect(first, isA<Success<ClothingAnalysis>>(), reason: '$first');
      final latencies = <int>[];
      for (var i = 0; i < 10; i++) {
        final w = Stopwatch()..start();
        final r = await classifier.analyze(input);
        latencies.add(w.elapsedMilliseconds);
        expect(r, isA<Success<ClothingAnalysis>>());
      }
      latencies.sort();
      final a = (first as Success<ClothingAnalysis>).value;
      expect(a.category, isNotNull);
      expect(a.pattern, isNotNull);
      final total =
          a.category!.confidence +
          a.category!.alternatives.fold<double>(0, (s, e) => s + e.$2);
      expect(total, inInclusiveRange(0.5, 1.0001));

      // ignore: avoid_print
      print(
        'DEVICE_CHECK openMs=$openMs '
        'p50Ms=${latencies[latencies.length ~/ 2]} maxMs=${latencies.last} '
        'category=${a.category!.value.code}@${a.category!.confidence.toStringAsFixed(2)} '
        'type=${a.subcategory?.value.code} '
        'pattern=${a.pattern!.value.code}@${a.pattern!.confidence.toStringAsFixed(2)}',
      );
      await classifier.close();
      await dir.delete(recursive: true);
    });
  });
}
