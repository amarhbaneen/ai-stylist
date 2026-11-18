import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:meta/meta.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../garment/garment_classifier.dart'
    show UnsupportedImageException, preprocess;
import '../studio/studio_polish.dart';
import 'cutout_renderer.dart';
import 'garment_regions.dart';
import 'person_mask.dart';
import 'segmentation_labels.dart';

/// A loaded segmentation model. Implementations run inference off the UI
/// thread and must be closed. See `LiteRtSegmentationSession`.
abstract interface class SegmentationSession {
  /// [rgb] is `size × size × 3` floats, RGB 0–255, row-major. Returns
  /// `size × size × classes` probabilities, row-major, class last.
  Future<Float32List> run(Float32List rgb);

  Future<void> close();
}

/// Opens the model: verified bytes, label table and runtime.
typedef SegmentationSessionOpener =
    Future<Result<(SegmentationSession, SegmentationLabels)>> Function();

/// A garment found in a photo, ready to become a wardrobe item.
@immutable
final class FoundGarment {
  const FoundGarment({
    required this.category,
    required this.areaShare,
    required this.cutout,
  });

  /// The segmentation model's category, used only to label the choice.
  final GarmentCategory category;

  /// Share of the photo it covers (0–1).
  final double areaShare;
  final CutoutImages cutout;
}

/// Finds the garments in a photo and cuts each one out.
abstract interface class GarmentFinder {
  /// Garments in the photo at [imagePath], largest first. Empty when none
  /// covers enough of the photo. Never throws.
  Future<Result<List<FoundGarment>>> findGarments(String imagePath);
}

/// Finds garments in a photo and cuts each one out (FR-05, DECISIONS D-39,
/// D-40), with the bundled segmentation model.
///
/// - Opened lazily on first use and kept for later photos.
/// - Decoding, mask processing and PNG encoding run on background isolates;
///   inference runs on the session's isolate. Nothing leaves the device.
/// - With [openPerson], a person model limits garments to the person in
///   photos of worn clothes (D-41). It is optional: if it is missing or
///   fails, the garment model is used alone.
/// - Never throws. On any failure the caller keeps the original photo, so
///   adding an item is never blocked.
final class GarmentSegmenter implements GarmentFinder {
  GarmentSegmenter({required this._open, this._openPerson, this._studioPolish});

  final SegmentationSessionOpener _open;
  final PersonModelOpener? _openPerson;

  /// Whether to polish cut-outs (the user's setting, read per photo).
  final Future<bool> Function()? _studioPolish;

  Future<Result<(SegmentationSession, SegmentationLabels)>>? _opening;
  Future<Result<PersonModel>>? _openingPerson;
  var _closed = false;

  @override
  Future<Result<List<FoundGarment>>> findGarments(String imagePath) async {
    if (_closed) {
      return const Failure(ModelUnavailableFailure('Segmenter was closed'));
    }
    final opened = await (_opening ??= _open());
    if (opened case Failure(:final failure)) return Failure(failure);
    final (session, labels) =
        (opened as Success<(SegmentationSession, SegmentationLabels)>).value;

    final size = labels.inputSize;
    final Float32List rgb;
    try {
      rgb = await Isolate.run(() => preprocess(imagePath, size));
    } on Exception catch (e) {
      return Failure(
        UnsupportedImageFailure('Could not read the photo', cause: e),
      );
    }

    final Float32List probabilities;
    try {
      probabilities = await session.run(rgb);
    } on Object catch (e) {
      // Native and isolate errors are not always Exceptions; contain them.
      return Failure(InferenceFailure('Segmentation model failed', cause: e));
    }
    if (probabilities.length != size * size * labels.classes.length) {
      return const Failure(
        ModelCorruptFailure('Segmentation output does not match its labels'),
      );
    }

    final masked = await _withPerson(imagePath, rgb, probabilities, labels);
    final polish = await _studioPolish?.call() ?? false;
    try {
      return Success(
        await Isolate.run(
          () => cutOut(imagePath, masked, labels, polish: polish),
        ),
      );
    } on Exception catch (e) {
      return Failure(
        UnsupportedImageFailure('Could not cut out the garments', cause: e),
      );
    }
  }

  /// [probabilities] limited to what the person wears, or unchanged when
  /// there is no person model, it fails, or the photo shows too little of
  /// a person.
  Future<Float32List> _withPerson(
    String imagePath,
    Float32List rgb,
    Float32List probabilities,
    SegmentationLabels labels,
  ) async {
    final open = _openPerson;
    if (open == null) return probabilities;
    final opened = await (_openingPerson ??= open());
    if (opened is! Success<PersonModel>) return probabilities;
    final (session, personSize) = opened.value;
    final size = labels.inputSize;
    final classes = labels.classes.length;
    try {
      final input = personSize == size
          ? rgb
          : await Isolate.run(() => preprocess(imagePath, personSize));
      final output = await session.run(personInput(input));
      return await Isolate.run(() {
        final worn = wornMask(output, personSize);
        return worn == null
            ? probabilities
            : restrictToWorn(
                probabilities,
                size: size,
                classes: classes,
                worn: worn,
                wornSize: personSize,
              );
      });
    } on Object {
      // Optional refinement: native and isolate errors are not always
      // Exceptions, and any of them only means the garment model is used
      // alone.
      return probabilities;
    }
  }

  /// Releases the models. Later calls return a typed failure.
  Future<void> close() async {
    _closed = true;
    final opening = _opening;
    final openingPerson = _openingPerson;
    _opening = null;
    _openingPerson = null;
    if (opening != null) {
      if (await opening case Success(value: (final session, _))) {
        await session.close();
      }
    }
    if (openingPerson != null) {
      if (await openingPerson case Success(value: (final session, _))) {
        await session.close();
      }
    }
  }
}

/// Regions → cut-outs for the photo at [imagePath] (runs on an isolate).
/// With [polish], each cut-out also goes through the studio polish (D-44)
/// and keeps its raw copy; if polish fails, the plain cut-out is used.
List<FoundGarment> cutOut(
  String imagePath,
  Float32List probabilities,
  SegmentationLabels labels, {
  bool polish = false,
}) {
  final regions = findRegions(probabilities, labels);
  if (regions.isEmpty) return const [];
  final photo = img.decodeImage(File(imagePath).readAsBytesSync());
  if (photo == null) throw UnsupportedImageException(imagePath);
  final found = <FoundGarment>[];
  for (final r in regions) {
    final raw = renderCutoutImage(photo, r);
    if (raw == null) continue;
    final polished = polish ? _tryPolish(raw) : null;
    found.add(
      FoundGarment(
        category: r.category,
        areaShare: r.areaShare,
        cutout: polished == null
            ? encodeCutout(raw)
            : encodeCutout(polished, raw: raw),
      ),
    );
  }
  return found;
}

/// Studio polish, or `null` if it fails for any reason: polish is optional
/// and must never block the cut-out.
img.Image? _tryPolish(img.Image raw) {
  try {
    return polishCutout(raw);
  } on Object {
    // Malformed or extreme input; the raw cut-out is used instead.
    return null;
  }
}
