import 'dart:math' as math;
import 'dart:typed_data';

import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../model_registry.dart';
import 'garment_segmenter.dart';
import 'litert_segmentation_session.dart';

/// Manifest task of the person model (DECISIONS D-41).
const personSegmentationTask = 'person-segmentation';

/// Input size of the bundled person model (MediaPipe Selfie Multiclass
/// Segmentation, 256 × 256).
const personInputSize = 256;

/// Output channels of the person model: background, hair, body skin, face
/// skin, clothes, other (accessories).
const personClasses = 6;

/// Channels counted as something worn.
const personWornChannels = [4, 5];

/// A photo counts as worn clothing when at least this share of it is not
/// background in the person model. Below it (flat-lays, hangers) the person
/// model is not used.
const minPersonShare = 0.05;

/// Worn pixels are grown by this many model pixels before masking, so
/// garment edges the person model trims are kept.
const personGrowRadius = 2;

/// The person model's input from RGB 0–255 (the garment model's input).
Float32List personInput(Float32List rgb) {
  final out = Float32List(rgb.length);
  for (var i = 0; i < rgb.length; i++) {
    out[i] = rgb[i] / 255;
  }
  return out;
}

/// A loaded person model and its square input size.
typedef PersonModel = (SegmentationSession, int);

/// Opens the person model: verified bytes and runtime.
typedef PersonModelOpener = Future<Result<PersonModel>> Function();

/// Per-pixel "worn" probability (clothes + accessories) from the person
/// model's `size × size × 6` output, or `null` when the photo has too little
/// of a person in it (pure; tested directly).
Float32List? wornMask(Float32List output, int size) {
  if (output.length != size * size * personClasses) {
    throw ArgumentError.value(output.length, 'output');
  }
  final mask = Float32List(size * size);
  var person = 0;
  for (var i = 0; i < mask.length; i++) {
    final base = i * personClasses;
    if (output[base] < 0.5) person++;
    var worn = 0.0;
    for (final c in personWornChannels) {
      worn += output[base + c];
    }
    mask[i] = worn;
  }
  return person / mask.length < minPersonShare ? null : mask;
}

/// Keeps garment pixels only where the person wears something (pure;
/// tested directly). See DECISIONS D-41.
///
/// In a photo of worn clothes the garment model sometimes takes the
/// background for clothing (a mesh chair behind the shoulders, things on a
/// shelf). The person model knows what is worn, so every garment
/// probability is scaled by the (slightly grown) worn probability and the
/// rest goes to the background.
///
/// [probabilities] is `size × size × classes`, class 0 the background;
/// [worn] is `wornSize × wornSize`.
Float32List restrictToWorn(
  Float32List probabilities, {
  required int size,
  required int classes,
  required Float32List worn,
  required int wornSize,
}) {
  if (probabilities.length != size * size * classes) {
    throw ArgumentError.value(probabilities.length, 'probabilities');
  }
  if (worn.length != wornSize * wornSize) {
    throw ArgumentError.value(worn.length, 'worn');
  }
  final grown = _grow(worn, wornSize, personGrowRadius);
  final out = Float32List(probabilities.length);
  for (var y = 0; y < size; y++) {
    final wy = math.min(wornSize - 1, y * wornSize ~/ size);
    for (var x = 0; x < size; x++) {
      final wx = math.min(wornSize - 1, x * wornSize ~/ size);
      final keep = _ramp(grown[wy * wornSize + wx]);
      final base = (y * size + x) * classes;
      out[base] = 1 - (1 - probabilities[base]) * keep;
      for (var k = 1; k < classes; k++) {
        out[base + k] = probabilities[base + k] * keep;
      }
    }
  }
  return out;
}

/// Worn probability below [wornLow] removes a pixel; above [wornHigh] keeps
/// it fully. The ramp between keeps edges soft, while pixels the person
/// model is unsure about (the chair just behind a shoulder) are not kept
/// half-visible.
const wornLow = 0.35;
const wornHigh = 0.65;

double _ramp(double w) =>
    ((w - wornLow) / (wornHigh - wornLow)).clamp(0.0, 1.0);

/// Maximum over a square of side `2r + 1` (separable: rows, then columns).
Float32List _grow(Float32List mask, int size, int r) {
  final rows = Float32List(mask.length);
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      var m = 0.0;
      for (var dx = math.max(0, x - r); dx <= math.min(size - 1, x + r); dx++) {
        m = math.max(m, mask[y * size + dx]);
      }
      rows[y * size + x] = m;
    }
  }
  final out = Float32List(mask.length);
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      var m = 0.0;
      for (var dy = math.max(0, y - r); dy <= math.min(size - 1, y + r); dy++) {
        m = math.max(m, rows[dy * size + x]);
      }
      out[y * size + x] = m;
    }
  }
  return out;
}

/// Finds the person model in [registry], checks its SHA-256, and starts a
/// LiteRT session. Every problem is a typed failure.
Future<Result<PersonModel>> openPersonModel(ModelRegistry registry) async {
  final model = registry.forTask(personSegmentationTask);
  if (model == null) {
    return const Failure(ModelUnavailableFailure('No person model'));
  }
  switch (await registry.loadVerified(model)) {
    case Failure(:final failure):
      return Failure(failure);
    case Success(value: final bytes):
      return switch (await LiteRtSegmentationSession.open(
        bytes,
        size: personInputSize,
        channels: personClasses,
        debugName: 'PersonMask',
      )) {
        Success(value: final session) => Success((session, personInputSize)),
        Failure(:final failure) => Failure(failure),
      };
  }
}
