import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:meta/meta.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../garment/garment_classifier.dart'
    show UnsupportedImageException, preprocess;
import 'cutout_renderer.dart';
import 'garment_regions.dart';
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
/// - Never throws. On any failure the caller keeps the original photo, so
///   adding an item is never blocked.
final class GarmentSegmenter implements GarmentFinder {
  GarmentSegmenter({required this._open});

  final SegmentationSessionOpener _open;

  Future<Result<(SegmentationSession, SegmentationLabels)>>? _opening;
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

    try {
      return Success(
        await Isolate.run(() => cutOut(imagePath, probabilities, labels)),
      );
    } on Exception catch (e) {
      return Failure(
        UnsupportedImageFailure('Could not cut out the garments', cause: e),
      );
    }
  }

  /// Releases the model. Later calls return a typed failure.
  Future<void> close() async {
    _closed = true;
    final opening = _opening;
    _opening = null;
    if (opening == null) return;
    if (await opening case Success(value: (final session, _))) {
      await session.close();
    }
  }
}

/// Regions → cut-outs for the photo at [imagePath] (runs on an isolate).
List<FoundGarment> cutOut(
  String imagePath,
  Float32List probabilities,
  SegmentationLabels labels,
) {
  final regions = findRegions(probabilities, labels);
  if (regions.isEmpty) return const [];
  final photo = img.decodeImage(File(imagePath).readAsBytesSync());
  if (photo == null) throw UnsupportedImageException(imagePath);
  return [
    for (final r in regions)
      if (renderCutout(photo, r) case final cutout?)
        FoundGarment(
          category: r.category,
          areaShare: r.areaShare,
          cutout: cutout,
        ),
  ];
}
