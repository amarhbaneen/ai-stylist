import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../core/database/app_database.dart';
import '../../core/storage/file_store.dart';
import '../model_registry.dart';

/// Where an optional model is in its lifecycle.
enum ModelInstallState {
  notInstalled,

  /// A previous download stopped part-way; installing resumes it.
  partial,
  installed,
}

/// Lets the user stop a running download. The partial file is kept so the
/// next attempt resumes.
final class DownloadCancelToken {
  var _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;
}

typedef DownloadProgress = void Function(int receivedBytes, int totalBytes);

/// Downloads, verifies, installs and removes optional models (FR-09, D-38).
///
/// * Data goes to `model.bin.part` first; an interrupted download resumes
///   with an HTTP `Range` request.
/// * The file must be exactly the manifest's size and SHA-256, otherwise it
///   is deleted and nothing is installed.
/// * Only then is it renamed to `model.bin` (atomic on the same volume) and
///   recorded as INSTALLED; an older version is removed afterwards, so a
///   failed update never leaves the user without the previous model.
/// * Downloaded files are only ever read as model weights, never executed.
final class ModelDownloadManager {
  ModelDownloadManager({
    required AppDatabase database,
    required this._files,
    required this._client,
    required this._clock,
    this.idleTimeout = const Duration(seconds: 30),
  }) : _db = database;

  final AppDatabase _db;
  final FileStore _files;
  final http.Client _client;
  final Clock _clock;

  /// Maximum wait for the response or the next chunk of data.
  final Duration idleTimeout;

  static const userAgent = 'AIStylist/0.1 (Flutter app)';
  static const _installed = 'INSTALLED', _staged = 'STAGED';

  /// POSIX ENOSPC and Windows disk-full codes (as in `LocalFileStore`).
  static const _noSpaceCodes = {28, 112, 39};

  static String relativePathOf(ModelDescriptor m) =>
      'models/${m.id}/${m.version}/model.bin';

  File _file(ModelDescriptor m) => _files.resolve(relativePathOf(m));

  File _part(ModelDescriptor m) => File('${_file(m).path}.part');

  Future<ModelInstallationRow?> _row(ModelDescriptor m) =>
      (_db.select(
            _db.modelInstallations,
          )..where((t) => t.modelId.equals(m.id) & t.version.equals(m.version)))
          .getSingleOrNull();

  Future<ModelInstallState> stateOf(ModelDescriptor m) async {
    final row = await _row(m);
    if (row?.state == _installed && await _file(m).exists()) {
      return ModelInstallState.installed;
    }
    return await _part(m).exists()
        ? ModelInstallState.partial
        : ModelInstallState.notInstalled;
  }

  /// Bytes of an installed model (the registry re-checks the SHA-256).
  Future<Uint8List> readInstalled(ModelDescriptor m) async {
    if (await stateOf(m) != ModelInstallState.installed) {
      throw AssetMissingException('${m.id}@${m.version}');
    }
    return _file(m).readAsBytes();
  }

  Future<Result<void>> install(
    ModelDescriptor m, {
    DownloadProgress? onProgress,
    DownloadCancelToken? cancel,
  }) async {
    final source = m.download;
    if (source == null) {
      return Failure(ValidationFailure('${m.id} is not downloadable'));
    }
    if (await stateOf(m) == ModelInstallState.installed) {
      return const Success(null);
    }
    final part = _part(m);
    try {
      await part.parent.create(recursive: true);
      await _upsert(m, _staged);
      final fetched = await _fetch(m, source, part, onProgress, cancel);
      if (fetched case Failure()) return fetched;
      final verified = await _verify(m, source, part);
      if (verified case Failure()) return verified;
      await part.rename(_file(m).path);
      await _upsert(m, _installed, installedAt: _clock.nowUtc());
      await _removeOtherVersions(m);
      return const Success(null);
    } on FileSystemException catch (e) {
      final code = e.osError?.errorCode;
      if (code != null && _noSpaceCodes.contains(code)) {
        await _deleteQuietly(part);
        return Failure(
          InsufficientStorageFailure('Not enough space for ${m.id}', cause: e),
        );
      }
      return Failure(StorageFailure('Could not save ${m.id}', cause: e));
    }
  }

  /// Streams the (remaining) bytes into [part].
  Future<Result<void>> _fetch(
    ModelDescriptor m,
    ModelDownload source,
    File part,
    DownloadProgress? onProgress,
    DownloadCancelToken? cancel,
  ) async {
    var offset = await part.exists() ? await part.length() : 0;
    if (offset > source.sizeBytes) {
      await part.delete();
      offset = 0;
    }
    if (offset == source.sizeBytes) return const Success(null);

    final request = http.Request('GET', source.url)
      ..followRedirects = true
      ..headers['User-Agent'] = userAgent;
    if (offset > 0) request.headers['Range'] = 'bytes=$offset-';

    IOSink? sink;
    try {
      final response = await _client.send(request).timeout(idleTimeout);
      final resumed = offset > 0 && response.statusCode == 206;
      if (response.statusCode != 200 && !resumed) {
        // e.g. 416 after the file changed upstream: start clean next time.
        if (response.statusCode == 416) await _deleteQuietly(part);
        unawaited(response.stream.drain<void>().catchError((_) {}));
        return Failure(NetworkFailure('HTTP ${response.statusCode}'));
      }
      var received = resumed ? offset : 0;
      final out = sink = part.openWrite(
        mode: resumed ? FileMode.append : FileMode.write,
      );
      onProgress?.call(received, source.sizeBytes);
      await for (final chunk in response.stream.timeout(idleTimeout)) {
        if (cancel?.isCancelled ?? false) {
          return const Failure(CancelledFailure('Download paused'));
        }
        received += chunk.length;
        if (received > source.sizeBytes) {
          sink = null;
          await out.close();
          await _deleteQuietly(part);
          return Failure(
            ModelCorruptFailure('${m.id} is larger than the manifest says'),
          );
        }
        out.add(chunk);
        onProgress?.call(received, source.sizeBytes);
      }
      return const Success(null);
    } on TimeoutException catch (e) {
      return Failure(NetworkFailure('Download timed out', cause: e));
    } on SocketException catch (e) {
      return Failure(NetworkFailure('No connection', cause: e));
    } on http.ClientException catch (e) {
      return Failure(NetworkFailure('Download failed', cause: e));
    } on HttpException catch (e) {
      return Failure(NetworkFailure('Download failed', cause: e));
    } finally {
      await sink?.close();
    }
  }

  Future<Result<void>> _verify(
    ModelDescriptor m,
    ModelDownload source,
    File part,
  ) async {
    final size = await part.length();
    final ok =
        size == source.sizeBytes &&
        (await sha256.bind(part.openRead()).first).toString() == m.sha256;
    if (ok) return const Success(null);
    await _deleteQuietly(part);
    await (_db.update(_db.modelInstallations)
          ..where((t) => t.modelId.equals(m.id) & t.version.equals(m.version)))
        .write(const ModelInstallationsCompanion(state: Value('FAILED')));
    return Failure(
      ModelCorruptFailure(
        size == source.sizeBytes
            ? '${m.id} failed its integrity check'
            : '${m.id} download is incomplete',
      ),
    );
  }

  /// Deletes every version of the model, including partial downloads.
  Future<Result<void>> remove(ModelDescriptor m) async {
    try {
      await _deleteDir(_file(m).parent.parent); // models/<id>
      await (_db.delete(
        _db.modelInstallations,
      )..where((t) => t.modelId.equals(m.id))).go();
      return const Success(null);
    } on FileSystemException catch (e) {
      return Failure(StorageFailure('Could not remove ${m.id}', cause: e));
    }
  }

  /// Startup clean-up: forget installs whose file vanished, and drop
  /// leftovers for versions the manifest no longer lists.
  Future<void> recover(List<ModelDescriptor> known) async {
    final rows = await _db.select(_db.modelInstallations).get();
    for (final row in rows) {
      final file = _files.resolve(row.relativePath);
      final listed = known.any(
        (m) => m.id == row.modelId && m.version == row.version,
      );
      if (!listed) {
        await _deleteDir(file.parent);
      }
      if (!listed || (row.state == _installed && !await file.exists())) {
        await (_db.delete(_db.modelInstallations)..where(
              (t) =>
                  t.modelId.equals(row.modelId) & t.version.equals(row.version),
            ))
            .go();
      }
    }
  }

  Future<void> _removeOtherVersions(ModelDescriptor m) async {
    final others =
        await (_db.select(_db.modelInstallations)..where(
              (t) => t.modelId.equals(m.id) & t.version.isNotValue(m.version),
            ))
            .get();
    for (final row in others) {
      await _deleteDir(_files.resolve(row.relativePath).parent);
    }
    await (_db.delete(_db.modelInstallations)..where(
          (t) => t.modelId.equals(m.id) & t.version.isNotValue(m.version),
        ))
        .go();
  }

  Future<void> _upsert(
    ModelDescriptor m,
    String state, {
    DateTime? installedAt,
  }) => _db
      .into(_db.modelInstallations)
      .insertOnConflictUpdate(
        ModelInstallationsCompanion.insert(
          modelId: m.id,
          version: m.version,
          relativePath: relativePathOf(m),
          sha256: m.sha256,
          byteSize: m.download!.sizeBytes,
          license: m.license,
          state: state,
          installedAt: Value(
            installedAt == null ? null : toEpochMillisUtc(installedAt),
          ),
        ),
      );

  static Future<void> _deleteDir(Directory dir) async {
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  static Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // Best effort: a leftover .part file is harmless and retried later.
    }
  }
}
