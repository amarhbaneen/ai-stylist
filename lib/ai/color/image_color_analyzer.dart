import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:wardrobe_domain/wardrobe_domain.dart';

import 'color_extractor.dart';

export 'color_extractor.dart' show ColorAnalysis;

/// Decodes an image file and runs [ColorExtractor] on a background isolate,
/// so decoding and clustering never block the UI thread.
final class ImageColorAnalyzer {
  const ImageColorAnalyzer({this.sampleSize = 64});

  /// Longest edge, in pixels, the image is reduced to before clustering.
  final int sampleSize;

  /// Analyses the image at [absolutePath] (use the small thumbnail).
  Future<Result<ColorAnalysis>> analyzeFile(String absolutePath) {
    final size = sampleSize;
    return Isolate.run(() async {
      final Uint8List bytes;
      try {
        bytes = await File(absolutePath).readAsBytes();
      } on FileSystemException catch (e) {
        return Failure<ColorAnalysis>(
          StorageFailure('Could not read image for colour analysis', cause: e),
        );
      }
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        return const Failure<ColorAnalysis>(
          UnsupportedImageFailure('Image could not be decoded'),
        );
      }
      final scaled = decoded.width >= decoded.height
          ? img.copyResize(decoded, width: size)
          : img.copyResize(decoded, height: size);
      final rgb = Uint8List(scaled.width * scaled.height * 3);
      var o = 0;
      for (final p in scaled) {
        rgb[o++] = p.r.toInt();
        rgb[o++] = p.g.toInt();
        rgb[o++] = p.b.toInt();
      }
      return Success(
        const ColorExtractor().analyzeRgb(rgb, scaled.width, scaled.height),
      );
    });
  }
}
