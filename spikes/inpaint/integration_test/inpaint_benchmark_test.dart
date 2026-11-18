// Inpainting spike: runs each candidate on the local test photos on a real
// device or emulator and prints one INPAINT_RESULT line per run (and a
// small composite as INPAINT_IMG for review). Nothing leaves the device.
//
//   pwsh tool/fetch_models.ps1
//   flutter drive --profile --driver=test_driver/integration_test.dart \
//     --target=integration_test/inpaint_benchmark_test.dart -d <device>
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:inpaint_spike/inpaint_bench.dart';
import 'package:integration_test/integration_test.dart';

Future<Uint8List> _asset(String key) async {
  final data = await rootBundle.load(key);
  return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}

Future<List<InpaintCase>> _cases() async {
  final cases = <InpaintCase>[];
  for (final photo in ['jersey', 'selfie']) {
    final image = img.decodePng(await _asset('assets/images/$photo.png'))!;
    for (final occluder in ['arm', 'phone']) {
      final m = img.decodePng(
        await _asset('assets/images/${photo}_${occluder}_mask.png'),
      )!;
      final hidden = Uint8List(InpaintCase.size * InpaintCase.size);
      for (final p in m) {
        if (p.r > 127) hidden[p.y * InpaintCase.size + p.x] = 1;
      }
      cases.add(InpaintCase('${photo}_$occluder', image, hidden));
    }
  }
  return cases;
}

void _report(InpaintResult r, Map<String, Object> extra) {
  // ignore: avoid_print
  print(
    'INPAINT_RESULT ${jsonEncode({
      'model': r.model,
      'case': r.caseName,
      'p50Ms': r.p50.round(),
      'runsMs': [for (final l in r.latenciesMs) l.round()],
      'maeHidden': double.parse(r.maeHidden.toStringAsFixed(1)),
      'psnrHidden': double.parse(r.psnrHidden.toStringAsFixed(1)),
      ...extra,
    })}',
  );
  final small = img.copyResize(r.output, width: 256);
  final data = base64Encode(img.encodeJpg(small, quality: 80));
  // Android's log truncates long lines: print the image in chunks.
  const chunk = 700;
  for (var i = 0; i * chunk < data.length; i++) {
    final end = (i + 1) * chunk;
    // ignore: avoid_print
    print(
      'INPAINT_IMG ${r.model}|${r.caseName}|$i '
      '${data.substring(i * chunk, end < data.length ? end : data.length)}',
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('inpainting candidates', (tester) async {
    final cases = await _cases();

    final baseline = PushPullInpainter();
    for (final c in cases) {
      _report(benchmark(baseline, c), {'initMs': 0});
    }

    for (final (file, make) in <(String, Inpainter Function(dynamic))>[
      ('migan_fp16.tflite', (i) => MiGanInpainter(i)),
      ('lama_dilated.tflite', (i) => LamaInpainter(i)),
    ]) {
      final bytes = await _asset('assets/models/$file');
      final rssBefore = rssMb();
      final Inpainter inpainter;
      final double initMs;
      try {
        final (interpreter, ms) = openModel(bytes);
        initMs = ms;
        // ignore: avoid_print
        print(
          'INPAINT_MODEL $file ${bytes.length} B; ${describe(interpreter)}',
        );
        inpainter = make(interpreter);
      } on Object catch (e) {
        // ignore: avoid_print
        print('INPAINT_FAIL $file open: $e');
        continue;
      }
      for (final c in cases) {
        try {
          _report(benchmark(inpainter, c), {
            'initMs': initMs.round(),
            'rssBeforeMb': rssBefore.round(),
            'rssAfterMb': rssMb().round(),
            'maxRssMb': maxRssMb().round(),
          });
        } on Object catch (e) {
          // ignore: avoid_print
          print('INPAINT_FAIL $file ${c.name}: $e');
        }
      }
      inpainter.close();
    }
  });
}
