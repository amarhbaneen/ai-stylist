import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../domain/official_photo.dart';

/// Downloads candidate images over HTTPS (DECISIONS D-43).
///
/// A file is kept only if it is an image of at most [maxBytes] that decodes
/// and is at least [minEdge] pixels on its shorter side. Files are only
/// ever decoded as images, never opened or run any other way. Callers own
/// the folder and clear it.
final class HttpCandidateDownloader implements CandidateDownloader {
  HttpCandidateDownloader({
    required this.client,
    this.timeout = const Duration(seconds: 15),
    this.maxBytes = 8 * 1024 * 1024,
    this.minEdge = 200,
  });

  final http.Client client;
  final Duration timeout;
  final int maxBytes;
  final int minEdge;

  var _count = 0;

  @override
  Future<Result<DownloadedCandidate>> download(
    OfficialPhotoCandidate c,
    Directory dir,
  ) async {
    if (c.image.scheme != 'https') {
      return const Failure(ValidationFailure('Only https images are used'));
    }
    final Uint8List bytes;
    try {
      final request = http.Request('GET', c.image)
        ..headers['Accept'] = 'image/jpeg,image/png,image/webp,image/*;q=0.8';
      final response = await client.send(request).timeout(timeout);
      if (response.statusCode != 200) {
        return Failure(
          NetworkFailure('Image request failed (${response.statusCode})'),
        );
      }
      final type = response.headers['content-type'] ?? '';
      if (!type.startsWith('image/')) {
        return const Failure(UnsupportedImageFailure('Not an image'));
      }
      final length = response.contentLength;
      if (length != null && length > maxBytes) {
        return const Failure(UnsupportedImageFailure('Image too large'));
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response.stream.timeout(timeout)) {
        builder.add(chunk);
        if (builder.length > maxBytes) {
          return const Failure(UnsupportedImageFailure('Image too large'));
        }
      }
      bytes = builder.takeBytes();
    } on TimeoutException catch (e) {
      return Failure(NetworkFailure('Image download timed out', cause: e));
    } on SocketException catch (e) {
      return Failure(NetworkFailure('No connection', cause: e));
    } on http.ClientException catch (e) {
      return Failure(NetworkFailure('Image download failed', cause: e));
    }

    final minEdge = this.minEdge;
    final ok = await Isolate.run(() => _isUsableImage(bytes, minEdge));
    if (!ok) {
      return const Failure(UnsupportedImageFailure('Image is not usable'));
    }
    final file = File(p.join(dir.path, 'candidate_${_count++}${_ext(bytes)}'));
    try {
      await dir.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
    } on FileSystemException catch (e) {
      return Failure(StorageFailure('Could not save the image', cause: e));
    }
    return Success(DownloadedCandidate(candidate: c, path: file.path));
  }
}

/// Whether [bytes] decode as an image at least [minEdge] pixels on its
/// shorter side (runs on an isolate).
bool _isUsableImage(Uint8List bytes, int minEdge) {
  try {
    final decoder = img.findDecoderForData(bytes);
    final info = decoder?.startDecode(bytes);
    if (info == null) return false;
    if (info.width < minEdge || info.height < minEdge) return false;
    return img.decodeImage(bytes) != null;
  } on Object {
    // Malformed data from the web: not usable, whatever the error.
    return false;
  }
}

/// File extension from the image's magic bytes (the server's name is not
/// trusted).
String _ext(Uint8List b) {
  if (b.length > 3 && b[0] == 0x89 && b[1] == 0x50) return '.png';
  if (b.length > 2 && b[0] == 0xFF && b[1] == 0xD8) return '.jpg';
  if (b.length > 11 && b[8] == 0x57 && b[9] == 0x45 && b[10] == 0x42) {
    return '.webp';
  }
  return '.img';
}
