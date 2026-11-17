import 'dart:typed_data';

import 'package:flutter_litert/flutter_litert.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import 'garment_classifier.dart';
import 'garment_labels.dart';

/// [GarmentModelSession] on LiteRT (`flutter_litert`, bundled runtime, no
/// Play services; DECISIONS D-07). Inference runs on a dedicated isolate.
///
/// The exported model has one float32 input `[1, 224, 224, 3]` (RGB 0–255)
/// and two float32 outputs, `type` and `pattern`, holding calibrated
/// probabilities. Output order inside the file is not guaranteed, so the
/// outputs are matched by length against the label table.
final class LiteRtGarmentSession implements GarmentModelSession {
  LiteRtGarmentSession._(
    this._interpreter,
    this._isolate,
    this._typeIndex,
    this._patternIndex,
    this._typeCount,
    this._patternCount,
  );

  final Interpreter _interpreter;
  final IsolateInterpreter _isolate;
  final int _typeIndex;
  final int _patternIndex;
  final int _typeCount;
  final int _patternCount;
  var _closed = false;

  /// Loads verified model bytes and checks the tensors against [labels].
  static Future<Result<LiteRtGarmentSession>> open(
    Uint8List modelBytes,
    GarmentLabels labels, {
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

    final input = interpreter.getInputTensors();
    final outputs = interpreter.getOutputTensors();
    const size = GarmentClassifier.inputSize;
    final typeCount = labels.types.length;
    final patternCount = labels.patterns.length;
    int? typeIndex, patternIndex;
    for (var i = 0; i < outputs.length; i++) {
      final o = outputs[i];
      if (o.type != TensorType.float32 || o.shape.length != 2) continue;
      if (o.shape.last == typeCount) typeIndex ??= i;
      if (o.shape.last == patternCount) patternIndex ??= i;
    }
    final inputOk =
        input.length == 1 &&
        input.single.type == TensorType.float32 &&
        _sameShape(input.single.shape, const [1, size, size, 3]);
    if (!inputOk ||
        outputs.length != 2 ||
        typeIndex == null ||
        patternIndex == null ||
        typeIndex == patternIndex) {
      interpreter.close();
      return const Failure(
        ModelCorruptFailure('Model tensors do not match the label table'),
      );
    }

    try {
      final isolate = await IsolateInterpreter.create(
        address: interpreter.address,
        debugName: 'GarmentClassifier',
      );
      return Success(
        LiteRtGarmentSession._(
          interpreter,
          isolate,
          typeIndex,
          patternIndex,
          typeCount,
          patternCount,
        ),
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
  Future<GarmentScores> run(Float32List rgb) async {
    if (_closed) throw StateError('Session closed');
    final type = Float32List(_typeCount);
    final pattern = Float32List(_patternCount);
    await _isolate.runForMultipleInputs(
      [rgb.buffer.asUint8List(rgb.offsetInBytes, rgb.lengthInBytes)],
      {_typeIndex: type, _patternIndex: pattern},
    );
    return (type: type, pattern: pattern);
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _isolate.close();
    _interpreter.close();
  }
}
