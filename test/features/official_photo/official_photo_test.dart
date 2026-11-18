import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ai_stylist/features/official_photo/data/candidate_downloader.dart';
import 'package:ai_stylist/features/official_photo/data/cloud_vision_search.dart';
import 'package:ai_stylist/features/official_photo/domain/find_official_photo.dart';
import 'package:ai_stylist/features/official_photo/domain/official_photo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:wardrobe_domain/wardrobe_domain.dart';

Map<String, Object?> _response(Map<String, Object?> detection) => {
  'responses': [
    {'webDetection': detection},
  ],
};

Uint8List _png(int w, int h) => img.encodePng(
  img.Image(width: w, height: h)..clear(img.ColorRgb8(200, 30, 30)),
);

OfficialPhotoCandidate _c(
  String url, [
  CandidateMatch m = CandidateMatch.exact,
]) => OfficialPhotoCandidate(image: Uri.parse(url), match: m);

void main() {
  group('parseWebDetection', () {
    test('ranks exact, then partial, then similar; https only; no repeats', () {
      final list = parseWebDetection(
        _response({
          'visuallySimilarImages': [
            {'url': 'https://b.com/similar.jpg'},
            {'url': 'https://shop.com/full.jpg'},
          ],
          'partialMatchingImages': [
            {'url': 'https://c.com/partial.jpg'},
          ],
          'fullMatchingImages': [
            {'url': 'http://insecure.com/x.jpg'},
            {'url': 'https://a.com/full.jpg'},
          ],
          'pagesWithMatchingImages': [
            {
              'url': 'https://www.shop.com/kit',
              'pageTitle': '<b>Home</b> shirt &amp; more',
              'fullMatchingImages': [
                {'url': 'https://shop.com/full.jpg'},
              ],
            },
          ],
        }),
      );
      expect(list.map((c) => c.image.toString()), [
        'https://shop.com/full.jpg',
        'https://a.com/full.jpg',
        'https://c.com/partial.jpg',
        'https://b.com/similar.jpg',
      ]);
      expect(list.map((c) => c.match), [
        CandidateMatch.exact,
        CandidateMatch.exact,
        CandidateMatch.partial,
        CandidateMatch.similar,
      ]);
      expect(list.first.pageTitle, 'Home shirt & more');
      expect(list.first.source, 'shop.com');
    });

    test('malformed or empty responses give nothing, never throw', () {
      for (final json in <Object?>[
        null,
        'x',
        {'responses': <Object?>[]},
        {
          'responses': [<String, Object?>{}],
        },
        _response({
          'fullMatchingImages': 'nope',
          'visuallySimilarImages': [
            1,
            {'url': 5},
            {'url': 'not a url'},
          ],
        }),
      ]) {
        expect(parseWebDetection(json), isEmpty, reason: '$json');
      }
    });
  });

  group('CloudVisionSearch', () {
    CloudVisionSearch search(
      MockClient client, {
      String? key = 'k',
      AndroidIdentity? identity,
    }) => CloudVisionSearch(
      client: client,
      apiKey: () async => key,
      androidIdentity: () async => identity,
    );

    test('sends the image with the key in a header, never the URL', () async {
      late http.Request sent;
      final client = MockClient((r) async {
        sent = r;
        return http.Response(
          jsonEncode(
            _response({
              'fullMatchingImages': [
                {'url': 'https://a.com/x.jpg'},
              ],
            }),
          ),
          200,
        );
      });
      final result = await search(
        client,
        identity: (package: 'p.k', sha1: 'AB12'),
      ).search(Uint8List.fromList([1, 2, 3]));

      expect(result.valueOrNull!.single.image.host, 'a.com');
      expect(sent.url.toString(), CloudVisionSearch.endpoint.toString());
      expect(sent.url.query, isEmpty);
      expect(sent.headers['X-goog-api-key'], 'k');
      expect(sent.headers['X-Android-Package'], 'p.k');
      expect(sent.headers['X-Android-Cert'], 'AB12');
      final body = jsonDecode(sent.body) as Map<String, Object?>;
      expect(body, {
        'requests': [
          {
            'image': {
              'content': base64Encode([1, 2, 3]),
            },
            'features': [
              {'type': 'WEB_DETECTION', 'maxResults': 20},
            ],
          },
        ],
      });
    });

    test('no key: nothing is sent', () async {
      var calls = 0;
      final client = MockClient((r) async {
        calls++;
        return http.Response('{}', 200);
      });
      final result = await search(client, key: '  ').search(Uint8List(3));
      expect((result as Failure).failure, isA<ValidationFailure>());
      expect(calls, 0);
    });

    test('a rejected key and a used-up quota are explained', () async {
      for (final (status, text) in [(403, 'API key'), (429, 'limit')]) {
        final client = MockClient(
          (r) async => http.Response(
            jsonEncode({
              'error': {'message': 'API key not valid'},
            }),
            status,
          ),
        );
        final result = await search(client).search(Uint8List(3));
        final failure = (result as Failure).failure;
        expect(failure, isA<ValidationFailure>());
        expect(failure.message, contains(text));
      }
    });

    test('network problems are typed failures', () async {
      for (final error in <Exception>[
        const SocketException('offline'),
        http.ClientException('reset'),
        TimeoutException('slow'),
      ]) {
        final client = MockClient((r) async => throw error);
        final result = await search(client).search(Uint8List(3));
        expect((result as Failure).failure, isA<NetworkFailure>());
      }
    });

    test('an oversized image is not sent', () async {
      final client = MockClient((r) async => fail('must not send'));
      final result = await search(client)
          .search(Uint8List(CloudVisionSearch.maxImageBytes + 1));
      expect((result as Failure).failure, isA<UnsupportedImageFailure>());
    });
  });

  group('HttpCandidateDownloader', () {
    late Directory dir;
    setUp(() async => dir = await Directory.systemTemp.createTemp('cands'));
    tearDown(() => dir.delete(recursive: true));

    HttpCandidateDownloader downloader(MockClient client) =>
        HttpCandidateDownloader(client: client, maxBytes: 64 * 1024);

    MockClient serve(List<int> bytes, {String type = 'image/png'}) =>
        MockClient(
          (r) async =>
              http.Response.bytes(bytes, 200, headers: {'content-type': type}),
        );

    test('keeps a real image, named by its content', () async {
      final r = await downloader(serve(_png(300, 300)))
          .download(_c('https://a.com/x.php'), dir);
      final path = r.valueOrNull!.path;
      expect(path, endsWith('.png'));
      expect(File(path).existsSync(), isTrue);
    });

    test(
      'rejects http, non-images, small, undecodable and huge files',
      () async {
        final cases = <(MockClient, String)>[
          (serve(_png(300, 300)), 'http://a.com/x.png'),
          (serve(_png(300, 300), type: 'text/html'), 'https://a.com/x'),
          (serve(_png(120, 120)), 'https://a.com/small.png'),
          (serve(List.filled(5000, 7)), 'https://a.com/junk.png'),
          (serve(List.filled(70 * 1024, 7)), 'https://a.com/huge.png'),
        ];
        for (final (client, url) in cases) {
          final r = await downloader(client).download(_c(url), dir);
          expect(r, isA<Failure<DownloadedCandidate>>(), reason: url);
        }
        expect(dir.listSync(), isEmpty);
      },
    );
  });

  group('FindOfficialPhoto', () {
    late Directory dir;
    setUp(() async => dir = await Directory.systemTemp.createTemp('find'));
    tearDown(() => dir.delete(recursive: true));

    FindOfficialPhoto find({
      bool enabled = true,
      required List<OfficialPhotoCandidate> found,
      required Set<String> broken,
      List<String>? tried,
    }) => FindOfficialPhoto(
      settings: _Settings(enabled: enabled),
      search: _Search(found),
      downloader: _Downloader(broken, tried ?? []),
      prepare: (_) async => Uint8List(4),
    );

    test('turned off: no search at all', () async {
      final search = _Search(const []);
      final r = await FindOfficialPhoto(
        settings: _Settings(enabled: false),
        search: search,
        downloader: _Downloader(const {}, []),
        prepare: (_) async => Uint8List(4),
      )('cut.png', dir);
      expect(r, isA<Failure<List<DownloadedCandidate>>>());
      expect(search.calls, 0);
    });

    test('skips broken downloads and stops at three', () async {
      final tried = <String>[];
      final urls = [for (var i = 0; i < 6; i++) 'https://s.com/$i.jpg'];
      final r = await find(
        found: [for (final u in urls) _c(u)],
        broken: {urls[1]},
        tried: tried,
      )('cut.png', dir);
      expect(r.valueOrNull!.map((d) => d.candidate.image.path), [
        '/0.jpg',
        '/2.jpg',
        '/3.jpg',
      ]);
      expect(tried, hasLength(4));
    });

    test('nothing usable: an empty list, not an error', () async {
      final r = await find(
        found: [_c('https://s.com/a.jpg')],
        broken: {'https://s.com/a.jpg'},
      )('cut.png', dir);
      expect(r.valueOrNull, isEmpty);
    });
  });
}

final class _Settings implements OfficialPhotoSettings {
  _Settings({required this.enabled});

  final bool enabled;

  @override
  Future<Result<bool>> isEnabled() async => Success(enabled);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Search implements ProductImageSearch {
  _Search(this.found);

  final List<OfficialPhotoCandidate> found;
  var calls = 0;

  @override
  Future<Result<List<OfficialPhotoCandidate>>> search(Uint8List jpeg) async {
    calls++;
    return Success(found);
  }
}

final class _Downloader implements CandidateDownloader {
  _Downloader(this.broken, this.tried);

  final Set<String> broken;
  final List<String> tried;

  @override
  Future<Result<DownloadedCandidate>> download(
    OfficialPhotoCandidate c,
    Directory dir,
  ) async {
    tried.add(c.image.toString());
    return broken.contains(c.image.toString())
        ? const Failure(NetworkFailure('404'))
        : Success(DownloadedCandidate(candidate: c, path: '${dir.path}/x'));
  }
}
