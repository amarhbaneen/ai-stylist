import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../logging/app_logger.dart';

/// Produces downscaled JPEG copies of an image file.
///
/// Implementations must apply EXIF orientation and must not copy EXIF
/// metadata (so location tags never reach derived files).
abstract interface class ImageProcessor {
  /// Returns JPEG bytes whose longer edge is at most [maxEdge] pixels, or
  /// `null` when the file cannot be decoded as an image.
  Future<Uint8List?> downscaleToJpeg(
    String sourcePath, {
    required int maxEdge,
    required int quality,
  });
}

/// [ImageProcessor] backed by the platform's native codecs
/// (`flutter_image_compress`), so large photos are not decoded in Dart.
final class NativeImageProcessor implements ImageProcessor {
  const NativeImageProcessor();

  @override
  Future<Uint8List?> downscaleToJpeg(
    String sourcePath, {
    required int maxEdge,
    required int quality,
  }) async {
    try {
      // minWidth/minHeight are aspect-preserving upper bounds; using the same
      // value for both bounds the longer edge whatever the orientation.
      return await FlutterImageCompress.compressWithFile(
        sourcePath,
        minWidth: maxEdge,
        minHeight: maxEdge,
        quality: quality,
      );
    } on PlatformException catch (e, s) {
      AppLogger.error('Image could not be processed', e, s);
      return null;
    } on UnsupportedError catch (e, s) {
      AppLogger.error('Image format not supported on this device', e, s);
      return null;
    }
  }
}
