import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_litert/flutter_litert.dart';
import 'package:image/image.dart' as img;

/// One test case: a 512 × 512 RGB image and a mask of hidden pixels
/// (255 = hidden). The image's own pixels under the mask are the ground
/// truth, since the occlusion is synthetic.
final class InpaintCase {
  InpaintCase(this.name, this.image, this.hidden);

  final String name;
  final img.Image image;
  final Uint8List hidden; // 512 × 512, 1 = hidden

  static const size = 512;
}

/// A model (or the classical baseline) that fills hidden pixels.
abstract interface class Inpainter {
  String get name;

  /// Returns the filled RGB image (512 × 512); only hidden pixels matter.
  img.Image fill(InpaintCase c);

  void close();
}

/// Timing, memory and error for one inpainter on one case.
final class InpaintResult {
  InpaintResult({
    required this.model,
    required this.caseName,
    required this.latenciesMs,
    required this.maeHidden,
    required this.psnrHidden,
    required this.output,
  });

  final String model;
  final String caseName;
  final List<double> latenciesMs;

  /// Mean absolute error (0–255) over hidden pixels, vs. the ground truth.
  final double maeHidden;
  final double psnrHidden;

  /// Composite: original outside the mask, filled inside.
  final img.Image output;

  double get p50 => ([...latenciesMs]..sort())[latenciesMs.length ~/ 2];
}

double rssMb() => ProcessInfo.currentRss / (1024 * 1024);
double maxRssMb() => ProcessInfo.maxRss / (1024 * 1024);

/// Runs [inpainter] [runs] times on [c] and scores it.
InpaintResult benchmark(Inpainter inpainter, InpaintCase c, {int runs = 3}) {
  final latencies = <double>[];
  late img.Image filled;
  for (var i = 0; i < runs; i++) {
    final w = Stopwatch()..start();
    filled = inpainter.fill(c);
    latencies.add(w.elapsedMicroseconds / 1000);
  }
  final out = c.image.clone();
  var abs = 0.0, sq = 0.0, n = 0;
  for (var y = 0; y < InpaintCase.size; y++) {
    for (var x = 0; x < InpaintCase.size; x++) {
      if (c.hidden[y * InpaintCase.size + x] == 0) continue;
      final t = c.image.getPixel(x, y);
      final p = filled.getPixel(x, y);
      out.setPixel(x, y, p);
      for (final (a, b) in [(t.r, p.r), (t.g, p.g), (t.b, p.b)]) {
        final d = (a - b).toDouble();
        abs += d.abs();
        sq += d * d;
        n++;
      }
    }
  }
  final mse = sq / n;
  return InpaintResult(
    model: inpainter.name,
    caseName: c.name,
    latenciesMs: latencies,
    maeHidden: abs / n,
    psnrHidden: mse == 0 ? 99 : 10 * math.log(255 * 255 / mse) / math.ln10,
    output: out,
  );
}

/// The app's classical fill (D-44, push-pull), as the baseline a model must
/// beat.
final class PushPullInpainter implements Inpainter {
  @override
  String get name => 'push-pull (baseline)';

  @override
  img.Image fill(InpaintCase c) {
    const s = InpaintCase.size;
    final levels = <(int, Float32List, Float32List)>[];
    var w = s;
    var data = Float32List(s * s * 3);
    var weight = Float32List(s * s);
    for (var i = 0; i < s * s; i++) {
      if (c.hidden[i] == 1) continue;
      final p = c.image.getPixel(i % s, i ~/ s);
      data[i * 3] = p.r.toDouble();
      data[i * 3 + 1] = p.g.toDouble();
      data[i * 3 + 2] = p.b.toDouble();
      weight[i] = 1;
    }
    levels.add((w, data, weight));
    while (w > 1) {
      final nw = (w + 1) ~/ 2;
      final nd = Float32List(nw * nw * 3), nwt = Float32List(nw * nw);
      for (var y = 0; y < w; y++) {
        for (var x = 0; x < w; x++) {
          final i = y * w + x, j = (y ~/ 2) * nw + x ~/ 2;
          final wt = weight[i];
          if (wt == 0) continue;
          nwt[j] += wt;
          for (var k = 0; k < 3; k++) {
            nd[j * 3 + k] += data[i * 3 + k] * wt;
          }
        }
      }
      for (var j = 0; j < nw * nw; j++) {
        if (nwt[j] == 0) continue;
        for (var k = 0; k < 3; k++) {
          nd[j * 3 + k] /= nwt[j];
        }
        nwt[j] = 1;
      }
      w = nw;
      data = nd;
      weight = nwt;
      levels.add((w, data, weight));
    }
    for (var l = levels.length - 2; l >= 0; l--) {
      final (fw, fd, fwt) = levels[l];
      final (cw, cd, _) = levels[l + 1];
      for (var y = 0; y < fw; y++) {
        for (var x = 0; x < fw; x++) {
          final i = y * fw + x;
          if (fwt[i] > 0) continue;
          final j = (y ~/ 2) * cw + x ~/ 2;
          for (var k = 0; k < 3; k++) {
            fd[i * 3 + k] = cd[j * 3 + k];
          }
          fwt[i] = 1;
        }
      }
    }
    final (_, base, _) = levels.first;
    final out = img.Image(width: s, height: s);
    for (final p in out) {
      final i = p.y * s + p.x;
      p
        ..r = base[i * 3].round().clamp(0, 255)
        ..g = base[i * 3 + 1].round().clamp(0, 255)
        ..b = base[i * 3 + 2].round().clamp(0, 255);
    }
    return out;
  }

  @override
  void close() {}
}

/// Loads a LiteRT model and reports what its tensors look like.
(Interpreter, double) openModel(Uint8List bytes, {int threads = 4}) {
  final w = Stopwatch()..start();
  final options = InterpreterOptions()..threads = threads;
  final interpreter = Interpreter.fromBuffer(bytes, options: options)
    ..allocateTensors();
  return (interpreter, w.elapsedMicroseconds / 1000);
}

String describe(Interpreter i) => [
  for (final t in i.getInputTensors()) 'in ${t.name} ${t.type} ${t.shape}',
  for (final t in i.getOutputTensors()) 'out ${t.name} ${t.type} ${t.shape}',
].join('; ');

/// MI-GAN (Picsart, MIT), LiteRT fp16 build: input `[1,4,512,512]` NCHW =
/// concat(mask − 0.5, rgb · mask) with rgb in [−1, 1] and mask 1 = keep;
/// output `[1,3,512,512]` in [−1, 1] (model card).
final class MiGanInpainter implements Inpainter {
  MiGanInpainter(this._interpreter);

  final Interpreter _interpreter;

  @override
  String get name => 'MI-GAN 512 fp16';

  @override
  img.Image fill(InpaintCase c) {
    const s = InpaintCase.size, plane = s * s;
    final x = Float32List(4 * plane);
    for (var i = 0; i < plane; i++) {
      final keep = c.hidden[i] == 1 ? 0.0 : 1.0;
      final p = c.image.getPixel(i % s, i ~/ s);
      x[i] = keep - 0.5;
      x[plane + i] = (p.r / 127.5 - 1) * keep;
      x[2 * plane + i] = (p.g / 127.5 - 1) * keep;
      x[3 * plane + i] = (p.b / 127.5 - 1) * keep;
    }
    final out = Float32List(3 * plane);
    _interpreter.runForMultipleInputs(
      [x.buffer.asUint8List()],
      {0: out.buffer.asUint8List()},
    );
    final image = img.Image(width: s, height: s);
    for (final p in image) {
      final i = p.y * s + p.x;
      int v(int ch) =>
          ((out[ch * plane + i] + 1) * 127.5).round().clamp(0, 255);
      p
        ..r = v(0)
        ..g = v(1)
        ..b = v(2);
    }
    return image;
  }

  @override
  void close() => _interpreter.close();
}

/// LaMa-Dilated (LaMa authors, Apache-2.0; LiteRT fp32 build): inputs image
/// `[1,512,512,3]` and mask `[1,512,512,1]` (1 = fill), both in [0, 1];
/// output `[1,512,512,3]` (model card).
final class LamaInpainter implements Inpainter {
  LamaInpainter(this._interpreter) {
    final inputs = _interpreter.getInputTensors();
    _maskIndex = inputs.indexWhere((t) => t.shape.last == 1);
    _imageIndex = 1 - _maskIndex;
  }

  final Interpreter _interpreter;
  late final int _maskIndex;
  late final int _imageIndex;

  @override
  String get name => 'LaMa-Dilated fp32';

  @override
  img.Image fill(InpaintCase c) {
    const s = InpaintCase.size, plane = s * s;
    final image = Float32List(plane * 3), mask = Float32List(plane);
    for (var i = 0; i < plane; i++) {
      final p = c.image.getPixel(i % s, i ~/ s);
      image[i * 3] = p.r / 255;
      image[i * 3 + 1] = p.g / 255;
      image[i * 3 + 2] = p.b / 255;
      mask[i] = c.hidden[i].toDouble();
    }
    final inputs = List<Object>.filled(2, Uint8List(0));
    inputs[_imageIndex] = image.buffer.asUint8List();
    inputs[_maskIndex] = mask.buffer.asUint8List();
    final out = Float32List(plane * 3);
    _interpreter.runForMultipleInputs(inputs, {0: out.buffer.asUint8List()});
    final result = img.Image(width: s, height: s);
    // Some exports return [0, 255]; detect the range once.
    var max = 0.0;
    for (final v in out) {
      if (v > max) max = v;
    }
    final scale = max > 2 ? 1.0 : 255.0;
    for (final p in result) {
      final i = (p.y * s + p.x) * 3;
      p
        ..r = (out[i] * scale).round().clamp(0, 255)
        ..g = (out[i + 1] * scale).round().clamp(0, 255)
        ..b = (out[i + 2] * scale).round().clamp(0, 255);
    }
    return result;
  }

  @override
  void close() => _interpreter.close();
}
