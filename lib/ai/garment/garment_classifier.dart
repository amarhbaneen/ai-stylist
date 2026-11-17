import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:wardrobe_domain/wardrobe_domain.dart';

import 'garment_labels.dart';

/// Raw, calibrated probabilities from one inference (one value per label).
typedef GarmentScores = ({Float32List type, Float32List pattern});

/// A loaded garment model. Implementations run inference off the UI thread
/// and must be closed. See `LiteRtGarmentSession`.
abstract interface class GarmentModelSession {
  /// [rgb] is `inputSize × inputSize × 3` floats, RGB, 0–255, row-major.
  Future<GarmentScores> run(Float32List rgb);

  Future<void> close();
}

/// Opens the model: verified bytes, label table and runtime. Returns a
/// typed failure when the model is missing, corrupt or not loadable.
typedef GarmentSessionOpener =
    Future<Result<(GarmentModelSession, GarmentLabels, AnalysisSource)>>
    Function();

/// Tier-1 analyzer (DECISIONS D-08, D-38): suggests category, type and
/// pattern from the item's photo with the bundled garment classifier.
///
/// - The model is opened lazily on first use and kept for later items.
/// - Decoding and resizing run on a background isolate; inference runs on
///   the session's isolate. Nothing leaves the device.
/// - Output goes through [OutputValidator]; a type is only suggested when it
///   belongs to the suggested category.
/// - Never throws: failures are typed results, and manual entry stays
///   available (CLAUDE.md #8).
final class GarmentClassifier implements ClothingAnalyzer {
  GarmentClassifier({
    required this._open,
    required this._clock,
    this.validator = const OutputValidator(),
  });

  final GarmentSessionOpener _open;
  final Clock _clock;
  final OutputValidator validator;

  /// Model input size (the exported `image` tensor is `[1, 224, 224, 3]`).
  static const inputSize = 224;

  /// A type below this confidence is noise rather than a useful hint.
  static const minSubcategoryConfidence = 0.15;

  Future<Result<(GarmentModelSession, GarmentLabels, AnalysisSource)>>?
  _opening;
  var _closed = false;

  @override
  Future<Result<ClothingAnalysis>> analyze(AnalysisInput input) async {
    if (_closed) {
      return const Failure(ModelUnavailableFailure('Classifier was closed'));
    }
    final opened = await (_opening ??= _open());
    if (opened case Failure(:final failure)) return Failure(failure);
    final (
      session,
      labels,
      source,
    ) = (opened
            as Success<(GarmentModelSession, GarmentLabels, AnalysisSource)>)
        .value;

    final Float32List rgb;
    try {
      rgb = await Isolate.run(() => preprocess(input.imagePath, inputSize));
    } on Exception catch (e) {
      return Failure(
        UnsupportedImageFailure('Could not read the photo', cause: e),
      );
    }

    final GarmentScores scores;
    try {
      scores = await session.run(rgb);
    } on Object catch (e) {
      // Native and isolate errors are not always Exceptions; contain them.
      return Failure(InferenceFailure('Garment model failed', cause: e));
    }
    if (scores.type.length != labels.types.length ||
        scores.pattern.length != labels.patterns.length) {
      return const Failure(
        ModelCorruptFailure('Garment model output does not match its labels'),
      );
    }
    return Success(toAnalysis(scores, labels, source, _clock.nowUtc()));
  }

  /// Maps probabilities to suggestions (pure; tested directly).
  ClothingAnalysis toAnalysis(
    GarmentScores scores,
    GarmentLabels labels,
    AnalysisSource source,
    DateTime at,
  ) {
    final typeScores = {
      for (var i = 0; i < labels.types.length; i++)
        labels.types[i].label: scores.type[i].toDouble(),
    };
    final category = validator.validate<GarmentCategory>(
      rawScores: typeScores,
      labelToCode: labels.categoryCodes,
      parse: (c) {
        final v = GarmentCategory.fromCode(c);
        return v == GarmentCategory.unknown ? null : v;
      },
      source: source,
      analyzedAt: at,
    );
    var subcategory = validator.validate<GarmentSubcategory>(
      rawScores: typeScores,
      labelToCode: labels.subcategoryCodes,
      parse: GarmentSubcategory.tryFromCode,
      source: source,
      analyzedAt: at,
    );
    if (subcategory != null &&
        (category == null ||
            subcategory.value.category != category.value ||
            subcategory.confidence < minSubcategoryConfidence)) {
      subcategory = null;
    }
    if (subcategory != null && category != null) {
      // Alternatives from another category would contradict the category.
      subcategory = Suggestion(
        value: subcategory.value,
        confidence: subcategory.confidence,
        source: source,
        analyzedAt: at,
        alternatives: [
          for (final a in subcategory.alternatives)
            if (a.$1.category == category.value &&
                a.$2 >= minSubcategoryConfidence)
              a,
        ],
      );
    }
    final pattern = validator.validate<GarmentPattern>(
      rawScores: {
        for (var i = 0; i < labels.patterns.length; i++)
          labels.patterns[i].code: scores.pattern[i].toDouble(),
      },
      labelToCode: labels.patternCodes,
      parse: (c) {
        final v = GarmentPattern.fromCode(c);
        return v == GarmentPattern.unknown ? null : v;
      },
      source: source,
      analyzedAt: at,
    );
    return ClothingAnalysis(
      category: category,
      subcategory: subcategory,
      pattern: pattern,
    );
  }

  /// Releases the model. Later calls return a typed failure.
  Future<void> close() async {
    _closed = true;
    final opening = _opening;
    _opening = null;
    if (opening == null) return;
    if (await opening case Success(value: (final session, _, _))) {
      await session.close();
    }
  }
}

/// Decodes [path] and resizes the whole photo (no crop) to [size]², as the
/// model was evaluated in `training/` (`data._center`). Runs on an isolate.
Float32List preprocess(String path, int size) =>
    pixelsOf(img.decodeImage(File(path).readAsBytesSync()), size, path);

/// Exposed for tests with in-memory images.
Float32List pixelsOf(img.Image? image, int size, [String what = 'image']) {
  if (image == null) throw UnsupportedImageException(what);
  // Cut-outs (FR-05) are transparent PNGs: composite them onto white, like
  // a product photo, so hidden background pixels never reach the model.
  final hasAlpha = image.hasAlpha;
  final resized = img.copyResize(
    image.convert(format: img.Format.uint8, numChannels: hasAlpha ? 4 : 3),
    width: size,
    height: size,
    interpolation: img.Interpolation.linear,
  );
  final out = Float32List(size * size * 3);
  var o = 0;
  for (final p in resized) {
    final a = hasAlpha ? p.a / 255 : 1.0;
    final white = 255 * (1 - a);
    out[o++] = p.r * a + white;
    out[o++] = p.g * a + white;
    out[o++] = p.b * a + white;
  }
  return out;
}

/// The photo could not be decoded.
final class UnsupportedImageException implements Exception {
  const UnsupportedImageException(this.what);

  final String what;

  @override
  String toString() => 'UnsupportedImageException: $what';
}
