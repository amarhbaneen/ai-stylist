import 'dart:convert';

import 'package:material_ui/material_ui.dart';

import 'benchmark.dart';

/// M3 spike: proves LiteRT (flutter_litert) loads and runs a model on-device,
/// and measures init time, latency and memory. Not part of the product.
///
/// Results are printed as `SPIKE_RESULT {json}` lines so they can be read
/// with `adb logcat`, and shown on screen.
void main() => runApp(const SpikeApp());

const _image = 'assets/images/synthetic_tee.jpg';
const _models = [
  'assets/models/efficientnet_lite0_int8.tflite',
  'assets/models/efficientnet_lite0_float32.tflite',
];

class SpikeApp extends StatefulWidget {
  const SpikeApp({super.key});

  @override
  State<SpikeApp> createState() => _SpikeAppState();
}

class _SpikeAppState extends State<SpikeApp> {
  final _lines = <String>[];
  var _running = true;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    for (final model in _models) {
      try {
        final result = await benchmarkModel(
          modelAsset: model,
          imageAsset: _image,
        );
        final json = jsonEncode(result.toJson());
        // ignore: avoid_print
        print('SPIKE_RESULT $json');
        setState(
          () => _lines.add(
            '${result.model}\n'
            'init ${result.initMs.toStringAsFixed(1)} ms, '
            'p50 ${result.percentile(50).toStringAsFixed(1)} ms, '
            'p95 ${result.percentile(95).toStringAsFixed(1)} ms\n'
            'top1 #${result.top5.first.$1} '
            '(${result.top5.first.$2.toStringAsFixed(2)}), '
            'max RSS ${result.maxRssMb.toStringAsFixed(0)} MB',
          ),
        );
      } on Object catch (e, s) {
        // ignore: avoid_print
        print('SPIKE_ERROR $model $e\n$s');
        setState(() => _lines.add('$model FAILED: $e'));
      }
    }
    // ignore: avoid_print
    print('SPIKE_DONE');
    setState(() => _running = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('LiteRT spike')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_running) const LinearProgressIndicator(),
            for (final line in _lines)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(line),
              ),
          ],
        ),
      ),
    );
  }
}
