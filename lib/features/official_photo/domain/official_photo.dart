import 'dart:io' show Directory;
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

/// How a web image relates to the searched garment (DECISIONS D-43).
enum CandidateMatch {
  /// The same image found on the web.
  exact,

  /// An image containing the garment, cropped or edited.
  partial,

  /// An image that only looks alike.
  similar,
}

/// A web image that may be the garment's official product photo.
@immutable
final class OfficialPhotoCandidate {
  const OfficialPhotoCandidate({
    required this.image,
    required this.match,
    this.page,
    this.pageTitle,
  });

  /// HTTPS address of the image.
  final Uri image;
  final CandidateMatch match;

  /// The page the image was found on, when known.
  final Uri? page;

  /// Plain-text title of that page, when known.
  final String? pageTitle;

  /// The shop or site name, shown as "from `host`".
  String get source => (page ?? image).host.replaceFirst(RegExp('^www\\.'), '');
}

/// A candidate downloaded and checked: a decodable image on the device.
@immutable
final class DownloadedCandidate {
  const DownloadedCandidate({required this.candidate, required this.path});

  final OfficialPhotoCandidate candidate;

  /// Absolute path of the downloaded image in the app's temporary folder.
  final String path;
}

/// Finds web images that look like a garment. The only implementation
/// sends the image to Google Cloud Vision, and only after the user turned
/// the feature on (D-43).
abstract interface class ProductImageSearch {
  /// Candidates for [jpeg] (the garment cut-out on white), best first.
  Future<Result<List<OfficialPhotoCandidate>>> search(Uint8List jpeg);
}

/// Downloads one candidate image into [dir], checking it is a real,
/// sensibly sized image before it is kept.
abstract interface class CandidateDownloader {
  Future<Result<DownloadedCandidate>> download(
    OfficialPhotoCandidate c,
    Directory dir,
  );
}

/// The user's choice to search automatically, and their own API key.
abstract interface class OfficialPhotoSettings {
  Future<Result<bool>> isEnabled();
  Future<Result<void>> setEnabled({required bool enabled});

  /// `null` when no key is saved.
  Future<Result<String?>> apiKey();

  /// Saves [key], or removes it when `null`.
  Future<Result<void>> setApiKey(String? key);
}
