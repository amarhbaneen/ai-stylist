import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// An RGBA image as plain bytes (row-major, 4 bytes per pixel), the working
/// format of the studio steps (DECISIONS D-44). Pure Dart and isolate-safe.
final class StudioBuffer {
  StudioBuffer(this.width, this.height, this.rgba)
    : assert(rgba.length == width * height * 4, 'size mismatch');

  StudioBuffer.blank(this.width, this.height)
    : rgba = Uint8List(width * height * 4);

  factory StudioBuffer.fromImage(img.Image image) {
    final src = image.convert(format: img.Format.uint8, numChannels: 4);
    // Raw bytes in RGBA order: no per-pixel objects.
    final bytes = src.getBytes(order: img.ChannelOrder.rgba);
    return StudioBuffer(src.width, src.height, Uint8List.fromList(bytes));
  }

  final int width;
  final int height;
  final Uint8List rgba;

  int get pixels => width * height;

  int alphaAt(int i) => rgba[i * 4 + 3];

  img.Image toImage() => img.Image.fromBytes(
    width: width,
    height: height,
    bytes: rgba.buffer,
    bytesOffset: rgba.offsetInBytes,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );

  StudioBuffer copy() => StudioBuffer(width, height, Uint8List.fromList(rgba));
}

/// Alpha at or above this counts as garment for masks and statistics.
const solidAlpha = 128;

/// `1` where the pixel is garment (alpha ≥ [solidAlpha]), else `0`.
Uint8List solidMask(StudioBuffer b) {
  final m = Uint8List(b.pixels);
  for (var i = 0; i < b.pixels; i++) {
    if (b.alphaAt(i) >= solidAlpha) m[i] = 1;
  }
  return m;
}
