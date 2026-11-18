import 'dart:typed_data';

import 'package:flutter_litert/flutter_litert.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../model_registry.dart';
import 'garment_segmenter.dart';
import 'segmentation_labels.dart';

/// Manifest task of the garment segmentation model.
const segmentationTask = 'garment-segmentation';

/// [SegmentationSession] on LiteRT (`flutter_litert`, bundled runtime, no
/// Play services; DECISIONS D-07). Inference runs on a dedicated isolate.
///
/// The model has one float32 input `[1, S, S, 3]` (RGB) and one float32
/// output `[1, S, S, C]` of per-pixel values: class probabilities for the
/// garment model, a person probability (C = 1) for the person model.
final class LiteRtSegmentationSession implements SegmentationSession {
  LiteRtSegmentationSession._(this._interpreter, this._isolate, this._length);

  final Interpreter _interpreter;
  final IsolateInterpreter _isolate;
  final int _length;
  var _closed = false;

  /// Loads verified model bytes and checks the tensors are `[1, size,
  /// size, 3]` in and `[1, size, size, channels]` out.
  static Future<Result<LiteRtSegmentationSession>> open(
    Uint8List modelBytes, {
    required int size,
    required int channels,
    String debugName = 'GarmentSegmenter',
    int threads = 2,
  }) async {
    final Interpreter interpreter;
    try {
      interpreter = Interpreter.fromBuffer(
        modelBytes,
        options: InterpreterOptions()..threads = threads,
      )..allocateTensors();
    } on Object catch (e) {
      return Failure(
        ModelCorruptFailure('Model could not be loaded', cause: e),
      );
    }

    final s = size;
    final c = channels;
    final input = interpreter.getInputTensors();
    final output = interpreter.getOutputTensors();
    final ok =
        input.length == 1 &&
        output.length == 1 &&
        input.single.type == TensorType.float32 &&
        output.single.type == TensorType.float32 &&
        _sameShape(input.single.shape, [1, s, s, 3]) &&
        _sameShape(output.single.shape, [1, s, s, c]);
    if (!ok) {
      interpreter.close();
      return const Failure(
        ModelCorruptFailure('Model tensors do not have the expected shape'),
      );
    }

    try {
      final isolate = await IsolateInterpreter.create(
        address: interpreter.address,
        debugName: debugName,
      );
      return Success(
        LiteRtSegmentationSession._(interpreter, isolate, s * s * c),
      );
    } on Object catch (e) {
      interpreter.close();
      return Failure(
        ModelUnavailableFailure('Inference isolate failed to start', cause: e),
      );
    }
  }

  static bool _sameShape(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Future<Float32List> run(Float32List rgb) async {
    if (_closed) throw StateError('Session closed');
    final out = Float32List(_length);
    await _isolate.runForMultipleInputs(
      [rgb.buffer.asUint8List(rgb.offsetInBytes, rgb.lengthInBytes)],
      {0: out},
    );
    return out;
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _isolate.close();
    _interpreter.close();
  }
}

/// Finds the segmentation model in [registry], checks its SHA-256 and label
/// table, and starts a LiteRT session. Every problem is a typed failure.
Future<Result<(SegmentationSession, SegmentationLabels)>> openSegmentationModel(
  ModelRegistry registry,
) async {
  final model = registry.forTask(segmentationTask);
  if (model == null) {
    return const Failure(ModelUnavailableFailure('No segmentation model'));
  }
  final labelsKey = model.labelsAsset;
  if (labelsKey == null) {
    return Failure(ModelCorruptFailure('${model.id} has no label table'));
  }
  final SegmentationLabels labels;
  switch (await registry.loadText(labelsKey)) {
    case Failure(:final failure):
      return Failure(failure);
    case Success(:final value):
      final parsed = SegmentationLabels.tryParse(value);
      if (parsed == null) {
        return Failure(
          ModelCorruptFailure('${model.id} label table is invalid'),
        );
      }
      labels = parsed;
  }
  switch (await registry.loadVerified(model)) {
    case Failure(:final failure):
      return Failure(failure);
    case Success(value: final bytes):
      return switch (await LiteRtSegmentationSession.open(
        bytes,
        size: labels.inputSize,
        channels: labels.classes.length,
      )) {
        Success(value: final session) => Success((session, labels)),
        Failure(:final failure) => Failure(failure),
      };
  }
}
