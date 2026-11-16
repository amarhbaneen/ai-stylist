import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ai_stylist/ai/download/model_download_manager.dart';
import 'package:ai_stylist/ai/model_registry.dart';
import 'package:ai_stylist/core/database/app_database.dart';
import 'package:ai_stylist/core/storage/file_store.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../support/fakes.dart';

/// A local HTTP server standing in for the model host (no real network).
final class _Host {
  late HttpServer _server;
  final requests = <HttpRequest>[];
  final headers = <Map<String, String?>>[];

  /// Handles the next request; default serves [body] with Range support.
  late Future<void> Function(HttpRequest) handler;
  Uint8List body = Uint8List(0);

  Uri get url => Uri.parse('http://127.0.0.1:${_server.port}/model.bin');

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    handler = serve;
    _server.listen((r) {
      requests.add(r);
      headers.add({
        'range': r.headers.value('range'),
        'user-agent': r.headers.value('user-agent'),
      });
      unawaited(handler(r));
    });
  }

  Future<void> serve(HttpRequest r) async {
    final range = r.headers.value('range');
    final start = range == null
        ? 0
        : int.parse(RegExp(r'bytes=(\d+)-').firstMatch(range)!.group(1)!);
    r.response
      ..statusCode = range == null ? 200 : 206
      ..contentLength = body.length - start
      ..add(body.sublist(start));
    await r.response.close();
  }

  /// Sends the first [bytes] of [body], then drops the connection.
  Future<void> dropAfter(HttpRequest r, int bytes) async {
    r.response.contentLength = body.length;
    final socket = await r.response.detachSocket();
    socket.add(body.sublist(0, bytes));
    await socket.flush();
    socket.destroy();
  }

  Future<void> stop() => _server.close(force: true);
}

Uint8List _bytes(int n, {int seed = 1}) =>
    Uint8List.fromList(List.generate(n, (i) => (i * 31 + seed) % 256));

void main() {
  late Directory tmp;
  late AppDatabase db;
  late LocalFileStore files;
  late http.Client client;
  late _Host host;
  late ModelDownloadManager manager;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('model_dl');
    db = AppDatabase(NativeDatabase.memory());
    files = LocalFileStore(tmp);
    client = http.Client();
    host = _Host();
    await host.start();
    manager = ModelDownloadManager(
      database: db,
      files: files,
      client: client,
      clock: FixedClock(),
      idleTimeout: const Duration(seconds: 2),
    );
  });

  tearDown(() async {
    client.close();
    await host.stop();
    await db.close();
    await tmp.delete(recursive: true);
  });

  ModelDescriptor model(
    Uint8List body, {
    String version = '1',
    String? sha,
    int? size,
  }) => ModelDescriptor(
    id: 'garments',
    version: version,
    task: 'garment-category',
    sha256: sha ?? sha256.convert(body).toString(),
    license: 'Apache-2.0',
    download: ModelDownload(url: host.url, sizeBytes: size ?? body.length),
  );

  Future<List<ModelInstallationRow>> rows() =>
      db.select(db.modelInstallations).get();

  test('downloads, verifies and installs atomically', () async {
    host.body = _bytes(300000);
    final m = model(host.body);
    final progress = <int>[];

    final result = await manager.install(
      m,
      onProgress: (r, _) => progress.add(r),
    );

    expect(result.isSuccess, isTrue);
    expect(await manager.stateOf(m), ModelInstallState.installed);
    expect(await manager.readInstalled(m), host.body);
    expect(progress.last, host.body.length);
    final file = files.resolve(ModelDownloadManager.relativePathOf(m));
    expect(File('${file.path}.part').existsSync(), isFalse);
    expect((await rows()).single.state, 'INSTALLED');
    expect(host.headers.single['user-agent'], ModelDownloadManager.userAgent);

    // The registry loads it through the same SHA-256 check.
    final registry = ModelRegistry(
      (_) async => throw const AssetMissingException('none'),
      [m],
      loadInstalled: manager.readInstalled,
    );
    expect((await registry.loadVerified(m)).valueOrNull, host.body);
  });

  test('a SHA-256 mismatch installs nothing and deletes the file', () async {
    host.body = _bytes(5000);
    final m = model(host.body, sha: 'a' * 64);

    final result = await manager.install(m);

    expect((result as Failure).failure, isA<ModelCorruptFailure>());
    expect(await manager.stateOf(m), ModelInstallState.notInstalled);
    expect((await rows()).single.state, 'FAILED');
  });

  test('more bytes than the manifest says are rejected', () async {
    host.body = _bytes(5000);
    final m = model(host.body, size: 4000);

    final result = await manager.install(m);

    expect((result as Failure).failure, isA<ModelCorruptFailure>());
    expect(await manager.stateOf(m), ModelInstallState.notInstalled);
  });

  test('server errors become NetworkFailure', () async {
    host
      ..body = _bytes(100)
      ..handler = (r) async {
        r.response.statusCode = 500;
        await r.response.close();
      };
    final result = await manager.install(model(host.body));
    expect((result as Failure).failure, isA<NetworkFailure>());
  });

  test('an interrupted download resumes with a Range request', () async {
    host
      ..body = _bytes(200000)
      ..handler = (r) => host.dropAfter(r, 70000);
    final m = model(host.body);

    final first = await manager.install(m);
    expect((first as Failure).failure, isA<NetworkFailure>());
    expect(await manager.stateOf(m), ModelInstallState.partial);

    host.handler = host.serve;
    final second = await manager.install(m);

    expect(second.isSuccess, isTrue);
    expect(host.headers.last['range'], startsWith('bytes='));
    expect(host.headers.last['range'], isNot('bytes=0-'));
    expect(await manager.readInstalled(m), host.body);
  });

  test('pausing keeps the partial file for later', () async {
    host
      ..body = _bytes(400000)
      ..handler = (r) async {
        r.response.contentLength = host.body.length;
        for (var i = 0; i < host.body.length; i += 50000) {
          r.response.add(host.body.sublist(i, i + 50000));
          await r.response.flush();
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        await r.response.close();
      };
    final m = model(host.body);
    final token = DownloadCancelToken();

    final result = await manager.install(
      m,
      cancel: token,
      onProgress: (r, _) {
        if (r > 0) token.cancel();
      },
    );

    expect((result as Failure).failure, isA<CancelledFailure>());
    expect(await manager.stateOf(m), ModelInstallState.partial);
  });

  test('an update keeps the old version until the new one verifies', () async {
    host.body = _bytes(1000, seed: 1);
    final v1 = model(host.body);
    expect((await manager.install(v1)).isSuccess, isTrue);

    host.body = _bytes(1200, seed: 2);
    final bad = model(host.body, version: '2', sha: 'b' * 64);
    expect((await manager.install(bad)).isSuccess, isFalse);
    expect(await manager.stateOf(v1), ModelInstallState.installed);

    final v2 = model(host.body, version: '2');
    expect((await manager.install(v2)).isSuccess, isTrue);
    expect(await manager.stateOf(v1), ModelInstallState.notInstalled);
    expect(await manager.stateOf(v2), ModelInstallState.installed);
    expect((await rows()).map((r) => r.version), ['2']);
  });

  test('remove deletes files and records', () async {
    host.body = _bytes(1000);
    final m = model(host.body);
    await manager.install(m);

    expect((await manager.remove(m)).isSuccess, isTrue);

    expect(await manager.stateOf(m), ModelInstallState.notInstalled);
    expect(await rows(), isEmpty);
    expect(Directory('${tmp.path}/models/garments').existsSync(), isFalse);
  });

  test('recover forgets missing files and unlisted versions', () async {
    host.body = _bytes(1000);
    final m = model(host.body);
    await manager.install(m);
    await files.resolve(ModelDownloadManager.relativePathOf(m)).delete();

    await manager.recover([m]);
    expect(await rows(), isEmpty);

    await manager.install(m);
    await manager.recover(const []);
    expect(await rows(), isEmpty);
    expect(await manager.stateOf(m), ModelInstallState.notInstalled);
  });

  group('manifest entries for downloads', () {
    Map<String, Object?> entry({
      String id = 'garments',
      String version = '1',
      Object? download = const {
        'url': 'https://models.example.org/g.tflite',
        'sizeBytes': 1000,
      },
      String? asset,
    }) => {
      'id': id,
      'version': version,
      'task': 'garment-category',
      'sha256': 'c' * 64,
      'license': 'Apache-2.0',
      'download': ?download,
      'asset': ?asset,
    };

    test('a valid entry parses', () {
      final m = ModelDescriptor.tryParse(entry())!;
      expect(m.download!.sizeBytes, 1000);
      expect(m.asset, isNull);
    });

    test('unsafe or ambiguous entries are rejected', () {
      final bad = [
        entry(download: {'url': 'http://x.org/g', 'sizeBytes': 1}),
        entry(download: {'url': 'https://x.org/g', 'sizeBytes': 0}),
        entry(
          download: {
            'url': 'https://x.org/g',
            'sizeBytes': ModelDownload.maxBytes + 1,
          },
        ),
        entry(id: '../escape'),
        entry(version: '1/../../x'),
        entry(asset: 'assets/models/g.tflite'),
        entry(download: null),
      ];
      for (final e in bad) {
        expect(ModelDescriptor.tryParse(e), isNull, reason: jsonEncode(e));
      }
    });
  });
}
