import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../domain/official_photo.dart';

/// Package name and signing-certificate SHA-1 of this app, sent so that an
/// API key restricted to the Android app is accepted.
typedef AndroidIdentity = ({String package, String sha1});

/// [ProductImageSearch] with Google Cloud Vision Web Detection
/// (`images:annotate`, feature `WEB_DETECTION`; DECISIONS D-43).
///
/// - Sends only the image it is given (the garment cut-out on white), with
///   the user's own API key in the `X-goog-api-key` header, never in the
///   URL. Nothing else about the user or wardrobe is sent.
/// - Every problem is a typed failure; nothing throws.
final class CloudVisionSearch implements ProductImageSearch {
  CloudVisionSearch({
    required this.client,
    required this.apiKey,
    this.androidIdentity,
    this.timeout = const Duration(seconds: 20),
  });

  final http.Client client;

  /// Reads the saved key each time, so a new key applies at once.
  final Future<String?> Function() apiKey;

  /// Present on Android when the identity could be read.
  final Future<AndroidIdentity?> Function()? androidIdentity;
  final Duration timeout;

  static final endpoint = Uri.https(
    'vision.googleapis.com',
    '/v1/images:annotate',
  );

  /// The API's limit is a 10 MB JSON request; base64 adds a third.
  static const maxImageBytes = 6 * 1024 * 1024;
  static const maxResults = 20;

  @override
  Future<Result<List<OfficialPhotoCandidate>>> search(Uint8List jpeg) async {
    final key = (await apiKey())?.trim();
    if (key == null || key.isEmpty) {
      return const Failure(
        ValidationFailure(
          'Add your Google Cloud API key in Style preferences to find '
          'official photos.',
        ),
      );
    }
    if (jpeg.isEmpty || jpeg.length > maxImageBytes) {
      return const Failure(
        UnsupportedImageFailure('The image is too large to search'),
      );
    }
    final identity = await androidIdentity?.call();
    final body = jsonEncode({
      'requests': [
        {
          'image': {'content': base64Encode(jpeg)},
          'features': [
            {'type': 'WEB_DETECTION', 'maxResults': maxResults},
          ],
        },
      ],
    });

    final http.Response response;
    try {
      response = await client
          .post(
            endpoint,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'X-goog-api-key': key,
              if (identity != null) ...{
                'X-Android-Package': identity.package,
                'X-Android-Cert': identity.sha1,
              },
            },
            body: body,
          )
          .timeout(timeout);
    } on TimeoutException catch (e) {
      return Failure(NetworkFailure('Search timed out', cause: e));
    } on SocketException catch (e) {
      return Failure(NetworkFailure('No connection', cause: e));
    } on http.ClientException catch (e) {
      return Failure(NetworkFailure('Request failed', cause: e));
    }

    switch (response.statusCode) {
      case 200:
        break;
      case 400 || 401 || 403:
        final detail = _errorMessage(response.body);
        return Failure(
          ValidationFailure(
            'Google did not accept the API key. Check that it is correct and '
            'that the Cloud Vision API is enabled for it.'
            '${detail == null ? '' : ' ($detail)'}',
          ),
        );
      case 429:
        return const Failure(
          ValidationFailure(
            'The monthly search limit for this API key was reached.',
          ),
        );
      default:
        return Failure(
          NetworkFailure(
            'Search failed (${response.statusCode})',
            cause: _errorMessage(response.body),
          ),
        );
    }

    final Object? json;
    try {
      json = jsonDecode(response.body);
    } on FormatException catch (e) {
      return Failure(NetworkFailure('Unreadable search response', cause: e));
    }
    return Success(parseWebDetection(json));
  }

  static String? _errorMessage(String body) {
    try {
      final json = jsonDecode(body);
      if (json case {'error': {'message': final String message}}) {
        return message;
      }
    } on FormatException {
      // Not JSON: there is no message to keep.
    }
    return null;
  }
}

/// Candidates from an `images:annotate` response (pure; tested directly).
///
/// Order: exact matches (anywhere in the response), then partial matches,
/// then visually similar images. Only `https` image addresses are kept,
/// each once. Malformed parts are skipped, never fatal.
List<OfficialPhotoCandidate> parseWebDetection(Object? json) {
  final detection = switch (json) {
    {'responses': [{'webDetection': final Map<String, Object?> d}, ...]} => d,
    _ => null,
  };
  if (detection == null) return const [];

  final seen = <String>{};
  final out = <OfficialPhotoCandidate>[];
  void add(Object? image, CandidateMatch match, {Object? page, Object? title}) {
    final url = switch (image) {
      {'url': final String u} => u,
      _ => null,
    };
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return;
    if (!seen.add(uri.toString())) return;
    final pageUri = page is String ? Uri.tryParse(page) : null;
    out.add(
      OfficialPhotoCandidate(
        image: uri,
        match: match,
        page: pageUri != null && pageUri.scheme.startsWith('http')
            ? pageUri
            : null,
        pageTitle: title is String ? _plain(title) : null,
      ),
    );
  }

  List<Object?> list(Object? v) => v is List ? v : const [];
  final pages = [
    for (final p in list(detection['pagesWithMatchingImages']))
      if (p is Map) p,
  ];

  for (final match in [CandidateMatch.exact, CandidateMatch.partial]) {
    final field = match == CandidateMatch.exact
        ? 'fullMatchingImages'
        : 'partialMatchingImages';
    // Images with a known page first: they come with a shop name.
    for (final p in pages) {
      for (final i in list(p[field])) {
        add(i, match, page: p['url'], title: p['pageTitle']);
      }
    }
    for (final i in list(detection[field])) {
      add(i, match);
    }
  }
  for (final i in list(detection['visuallySimilarImages'])) {
    add(i, CandidateMatch.similar);
  }
  return out;
}

/// Page titles may contain HTML markup; keep the text.
String? _plain(String html) {
  final text = html
      .replaceAll(RegExp('<[^>]*>'), '')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return text.isEmpty ? null : text;
}
