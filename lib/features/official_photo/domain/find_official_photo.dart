import 'dart:io' show Directory;
import 'dart:typed_data';

import 'package:wardrobe_domain/wardrobe_domain.dart';

import 'official_photo.dart';

/// Finds official-photo suggestions for a garment (DECISIONS D-43): only
/// when the user turned the feature on, searches with the garment cut-out
/// (no face, no room), then downloads candidates in order until [wanted]
/// usable images are found or [maxTries] have been tried.
///
/// Returns an empty list when nothing usable was found. The caller shows
/// them next to the cut-out; nothing is applied without the user's tap.
final class FindOfficialPhoto {
  const FindOfficialPhoto({
    required this.settings,
    required this.search,
    required this.downloader,
    required this.prepare,
    this.wanted = 3,
    this.maxTries = 8,
  });

  final OfficialPhotoSettings settings;
  final ProductImageSearch search;
  final CandidateDownloader downloader;

  /// The image to send for [imagePath]: the cut-out flattened onto white,
  /// as JPEG. `null` when it cannot be read.
  final Future<Uint8List?> Function(String imagePath) prepare;
  final int wanted;
  final int maxTries;

  /// Downloads go into [dir].
  Future<Result<List<DownloadedCandidate>>> call(
    String imagePath,
    Directory dir,
  ) async {
    final enabled = await settings.isEnabled();
    if (enabled case Failure(:final failure)) return Failure(failure);
    if (enabled case Success(value: false)) {
      return const Failure(
        ValidationFailure('Automatic official photos are turned off.'),
      );
    }
    final jpeg = await prepare(imagePath);
    if (jpeg == null) {
      return const Failure(
        UnsupportedImageFailure('The cut-out could not be read'),
      );
    }
    final found = await search.search(jpeg);
    final List<OfficialPhotoCandidate> candidates;
    switch (found) {
      case Failure(:final failure):
        return Failure(failure);
      case Success(:final value):
        candidates = value;
    }

    final out = <DownloadedCandidate>[];
    for (final c in candidates.take(maxTries)) {
      if (out.length == wanted) break;
      // A candidate that fails to download is skipped, not fatal.
      if (await downloader.download(c, dir) case Success(:final value)) {
        out.add(value);
      }
    }
    return Success(out);
  }
}
