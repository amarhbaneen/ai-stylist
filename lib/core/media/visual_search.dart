import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../logging/app_logger.dart';

/// Hands an item's image to a visual search app the user picks, such as
/// Google Lens, so they can find the official product photo (DECISIONS
/// D-41).
///
/// This app makes no network request: the image is passed to Google Lens,
/// or through the share sheet to the app the user chooses, only when they
/// tap the button.
abstract interface class VisualSearch {
  /// Opens the share sheet with [imagePath]. Succeeds once the sheet has
  /// been shown, whatever the user then picks; [CancelledFailure] when it
  /// could not be shown.
  Future<Result<void>> search(String imagePath);
}

/// [VisualSearch] that opens Google Lens directly on Android when the
/// Google app is installed, and otherwise the system share sheet
/// (`share_plus`), where the user picks a search app.
///
/// Transparent cut-outs are first flattened onto white, as a product photo
/// would be, because search apps treat transparency as black. The JPEG is
/// written to [tempDir] and replaced on the next search. On Android,
/// [tempDir] must be `<filesDir>/visual_search`, the only folder the app's
/// file provider shares.
final class ShareSheetVisualSearch implements VisualSearch {
  ShareSheetVisualSearch({required this.tempDir});

  final Directory tempDir;

  static const _channel = MethodChannel('ai_stylist/visual_search');

  static const fileName = 'visual_search.jpg';

  @override
  Future<Result<void>> search(String imagePath) async {
    final Uint8List? jpeg;
    try {
      jpeg = await Isolate.run(() => flattenForSearch(imagePath));
    } on Exception catch (e) {
      return Failure(
        UnsupportedImageFailure('Could not prepare the image', cause: e),
      );
    }
    if (jpeg == null) {
      return const Failure(UnsupportedImageFailure('Could not read the image'));
    }
    final file = File(p.join(tempDir.path, fileName));
    try {
      await tempDir.create(recursive: true);
      await file.writeAsBytes(jpeg, flush: true);
      if (await _openLens(file.path)) return const Success(null);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path, mimeType: 'image/jpeg')]),
      );
      return const Success(null);
    } on Exception catch (e, s) {
      AppLogger.error('Share sheet failed', e, s);
      return Failure(
        StorageFailure('Could not open the share sheet', cause: e),
      );
    }
  }
}

/// Opens Google Lens with [path] on Android. `false` when it is not
/// installed or this is not Android, so the share sheet is used instead.
Future<bool> _openLens(String path) async {
  if (!Platform.isAndroid) return false;
  try {
    return await ShareSheetVisualSearch._channel.invokeMethod<bool>(
          'openLens',
          {'path': path},
        ) ??
        false;
  } on PlatformException catch (e) {
    AppLogger.error('Could not open Google Lens', e);
    return false;
  } on MissingPluginException {
    return false;
  }
}

/// JPEG of the image at [path], with transparency flattened onto white and
/// a small white margin (runs on an isolate). `null` if it cannot be read.
Uint8List? flattenForSearch(String path) {
  final source = img.decodeImage(File(path).readAsBytesSync());
  if (source == null) return null;
  final margin =
      (source.width > source.height ? source.width : source.height) ~/ 20;
  final canvas = img.Image(
    width: source.width + 2 * margin,
    height: source.height + 2 * margin,
  )..clear(img.ColorRgb8(255, 255, 255));
  img.compositeImage(canvas, source, dstX: margin, dstY: margin);
  return img.encodeJpg(canvas, quality: 90);
}
