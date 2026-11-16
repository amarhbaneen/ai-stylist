import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_litert/flutter_litert.dart';
import 'package:image/image.dart' as img;

/// Result of benchmarking one model. Serialised to JSON for the report.
final class ModelBenchmark {
  ModelBenchmark({
    required this.model,
    required this.modelBytes,
    required this.runtimeVersion,
    required this.inputType,
    required this.inputShape,
    required this.outputType,
    required this.outputShape,
    required this.initMs,
    required this.isolateStartMs,
    required this.preprocessMs,
    required this.latenciesMs,
    required this.rssBeforeMb,
    required this.rssAfterMb,
    required this.maxRssMb,
    required this.top5,
  });

  final String model;
  final int modelBytes;
  final String runtimeVersion;
  final String inputType;
  final List<int> inputShape;
  final String outputType;
  final List<int> outputShape;
  final double initMs;
  final double isolateStartMs;
  final double preprocessMs;
  final List<double> latenciesMs;
  final double rssBeforeMb;
  final double rssAfterMb;
  final double maxRssMb;

  /// (class index, score in 0..1)
  final List<(int, double)> top5;

  double percentile(double p) {
    final sorted = [...latenciesMs]..sort();
    final rank = (p / 100 * (sorted.length - 1)).round();
    return sorted[rank];
  }

  Map<String, Object> toJson() => {
    'model': model,
    'modelBytes': modelBytes,
    'runtimeVersion': runtimeVersion,
    'input': '$inputType$inputShape',
    'output': '$outputType$outputShape',
    'initMs': _r(initMs),
    'isolateStartMs': _r(isolateStartMs),
    'preprocessMs': _r(preprocessMs),
    'runs': latenciesMs.length,
    'p50Ms': _r(percentile(50)),
    'p95Ms': _r(percentile(95)),
    'minMs': _r(latenciesMs.reduce(math.min)),
    'rssBeforeMb': _r(rssBeforeMb),
    'rssAfterMb': _r(rssAfterMb),
    'maxRssMb': _r(maxRssMb),
    'top5': [
      for (final (i, s) in top5) {'index': i, 'score': _r(s)},
    ],
  };

  static double _r(double v) => (v * 100).round() / 100;
}

double _mb(int bytes) => bytes / (1024 * 1024);

double _ms(Stopwatch w) => w.elapsedMicroseconds / 1000;

/// Loads [modelAsset], runs [runs] timed inferences on [imageAsset] in a
/// background isolate (after [warmup] untimed runs) and reports timings.
///
/// Only files bundled in the app are read; nothing touches the network.
Future<ModelBenchmark> benchmarkModel({
  required String modelAsset,
  required String imageAsset,
  int threads = 4,
  int warmup = 3,
  int runs = 30,
}) async {
  final rssBefore = ProcessInfo.currentRss;
  final modelData = await rootBundle.load(modelAsset);
  final modelBytes = modelData.buffer.asUint8List(
    modelData.offsetInBytes,
    modelData.lengthInBytes,
  );

  final initWatch = Stopwatch()..start();
  final options = InterpreterOptions()..threads = threads;
  final interpreter = Interpreter.fromBuffer(modelBytes, options: options);
  interpreter.allocateTensors();
  initWatch.stop();

  final input = interpreter.getInputTensor(0);
  final output = interpreter.getOutputTensor(0);

  final isolateWatch = Stopwatch()..start();
  final isolate = await IsolateInterpreter.create(address: interpreter.address);
  isolateWatch.stop();

  try {
    final preWatch = Stopwatch()..start();
    final inputBytes = await _preprocess(
      imageAsset,
      shape: input.shape,
      type: input.type,
    );
    preWatch.stop();

    final outputCount = output.shape.fold<int>(1, (a, b) => a * b);
    final Object outputBuffer = output.type == TensorType.float32
        ? Float32List(outputCount)
        : Uint8List(outputCount);

    for (var i = 0; i < warmup; i++) {
      await isolate.run(inputBytes, outputBuffer);
    }
    final latencies = <double>[];
    for (var i = 0; i < runs; i++) {
      final w = Stopwatch()..start();
      await isolate.run(inputBytes, outputBuffer);
      latencies.add(_ms(w..stop()));
    }

    return ModelBenchmark(
      model: modelAsset.split('/').last,
      modelBytes: modelBytes.length,
      runtimeVersion: Interpreter.version,
      inputType: input.type.name,
      inputShape: input.shape,
      outputType: output.type.name,
      outputShape: output.shape,
      initMs: _ms(initWatch),
      isolateStartMs: _ms(isolateWatch),
      preprocessMs: _ms(preWatch),
      latenciesMs: latencies,
      rssBeforeMb: _mb(rssBefore),
      rssAfterMb: _mb(ProcessInfo.currentRss),
      maxRssMb: _mb(ProcessInfo.maxRss),
      top5: _top5(outputBuffer, output.params),
    );
  } finally {
    await isolate.close();
    interpreter.close();
  }
}

/// Decodes, resizes (no crop) and packs the image in the tensor's layout:
/// NHWC RGB, uint8 as-is, or float32 normalised to [-1, 1].
Future<Uint8List> _preprocess(
  String asset, {
  required List<int> shape,
  required TensorType type,
}) async {
  final data = await rootBundle.load(asset);
  final decoded = img.decodeImage(data.buffer.asUint8List())!;
  final h = shape[1];
  final w = shape[2];
  final resized = img.copyResize(decoded, width: w, height: h);
  final rgb = Uint8List(w * h * 3);
  var o = 0;
  for (final pixel in resized) {
    rgb[o++] = pixel.r.toInt();
    rgb[o++] = pixel.g.toInt();
    rgb[o++] = pixel.b.toInt();
  }
  switch (type) {
    case TensorType.uint8:
      return rgb;
    case TensorType.float32:
      final f = Float32List(rgb.length);
      for (var i = 0; i < rgb.length; i++) {
        f[i] = (rgb[i] - 127.5) / 127.5;
      }
      return f.buffer.asUint8List();
    default:
      throw UnsupportedError('Input type $type not handled by the spike');
  }
}

List<(int, double)> _top5(Object output, QuantizationParams params) {
  final scores = switch (output) {
    Float32List f => f.toList(),
    Uint8List u => [
      for (final q in u)
        params.scale == 0 ? q / 255 : (q - params.zeroPoint) * params.scale,
    ],
    _ => throw StateError('Unexpected output buffer'),
  };
  final indexed = [for (var i = 0; i < scores.length; i++) (i, scores[i])]
    ..sort((a, b) => b.$2.compareTo(a.$2));
  return indexed.take(5).toList();
}
