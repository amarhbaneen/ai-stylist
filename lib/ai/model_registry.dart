import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

/// Where an optional model can be downloaded from (FR-09, D-38).
@immutable
final class ModelDownload {
  const ModelDownload({required this.url, required this.sizeBytes});

  /// HTTPS only.
  final Uri url;

  /// Exact expected size; anything else is rejected.
  final int sizeBytes;

  /// Upper bound for a single model (guards against a bad manifest entry).
  static const maxBytes = 200 * 1024 * 1024;

  static ModelDownload? tryParse(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final url = Uri.tryParse(json['url'] as String? ?? '');
    final size = json['sizeBytes'];
    if (url == null || url.scheme != 'https' || url.host.isEmpty) return null;
    if (size is! int || size <= 0 || size > maxBytes) return null;
    return ModelDownload(url: url, sizeBytes: size);
  }
}

/// One model, described by the in-app manifest. The manifest ships inside
/// the app, so it is trusted metadata: a model file is only used if its bytes
/// match the SHA-256 recorded here (FR-09, D-16). A model is either bundled
/// ([asset]) or optional and downloaded on request ([download]).
@immutable
final class ModelDescriptor {
  ModelDescriptor({
    required this.id,
    required this.version,
    required this.task,
    required this.sha256,
    required this.license,
    this.asset,
    this.download,
    this.title,
    this.labelsAsset,
    Map<String, String> labels = const {},
  }) : assert((asset == null) != (download == null), 'asset XOR download'),
       labels = Map.unmodifiable(labels);

  final String id;
  final String version;

  /// For example `garment-category`.
  final String task;

  /// Asset key of a bundled model file.
  final String? asset;

  /// Download source of an optional model.
  final ModelDownload? download;

  /// Short human-readable name for the model manager.
  final String? title;

  /// Asset key of a bundled label table, for models whose outputs need more
  /// than [labels] (for example `garment-tier1`, see `GarmentLabels`).
  final String? labelsAsset;

  /// Lower-case hex SHA-256 of the model file.
  final String sha256;
  final String license;

  /// Model output label → taxonomy code (see `OutputValidator`).
  final Map<String, String> labels;

  AnalysisSource get source =>
      AnalysisSource(modelId: id, modelVersion: version);

  static final _hex64 = RegExp(r'^[0-9a-f]{64}$');

  /// IDs and versions become folder names: no separators or `..`.
  static final _safeSegment = RegExp(r'^[a-z0-9][a-z0-9_.-]{0,63}$');

  /// Strict parse: any missing or malformed field rejects the entry.
  static ModelDescriptor? tryParse(Object? json) {
    if (json is! Map<String, Object?>) return null;
    String? str(String key) => switch (json[key]) {
      final String s when s.trim().isNotEmpty => s,
      _ => null,
    };
    final id = str('id'), version = str('version'), task = str('task');
    final license = str('license');
    final sha = str('sha256')?.toLowerCase();
    if ([id, version, task, license, sha].contains(null)) return null;
    if (!_hex64.hasMatch(sha!)) return null;
    if (!_safeSegment.hasMatch(id!) || !_safeSegment.hasMatch(version!)) {
      return null;
    }
    if (version.contains('..')) return null;
    final asset = str('asset');
    final download = json.containsKey('download')
        ? ModelDownload.tryParse(json['download'])
        : null;
    if (json.containsKey('download') && download == null) return null;
    if ((asset == null) == (download == null)) return null;
    final rawLabels = json['labels'];
    final labels = <String, String>{
      if (rawLabels is Map<String, Object?>)
        for (final e in rawLabels.entries)
          if (e.value case final String code) e.key: code,
    };
    return ModelDescriptor(
      id: id,
      version: version,
      task: task!,
      asset: asset,
      download: download,
      title: str('title'),
      labelsAsset: str('labelsAsset'),
      sha256: sha,
      license: license!,
      labels: labels,
    );
  }
}

/// Loads asset bytes (Flutter's `rootBundle` in the app, a map in tests).
/// Must throw [AssetMissingException] for unknown keys.
typedef AssetLoader = Future<Uint8List> Function(String key);

/// A requested asset is not bundled.
final class AssetMissingException implements Exception {
  const AssetMissingException(this.key);

  final String key;

  @override
  String toString() => 'AssetMissingException: $key';
}

/// Reads an installed (downloaded) model's bytes. Must throw if the model
/// is not installed.
typedef InstalledModelLoader = Future<Uint8List> Function(ModelDescriptor m);

Future<Uint8List> _notInstalled(ModelDescriptor m) =>
    throw AssetMissingException('${m.id}@${m.version}');

/// Known models and integrity-checked loading.
final class ModelRegistry {
  ModelRegistry(
    this._load,
    List<ModelDescriptor> models, {
    this._loadInstalled = _notInstalled,
  }) : models = List.unmodifiable(models);

  static const manifestAsset = 'assets/models/manifest.json';
  static const supportedSchema = 1;

  final AssetLoader _load;
  final InstalledModelLoader _loadInstalled;
  final List<ModelDescriptor> models;

  /// Models the user can download on request.
  List<ModelDescriptor> get downloadable => [
    for (final m in models)
      if (m.download != null) m,
  ];

  /// Reads the bundled manifest. A missing or malformed manifest yields an
  /// empty registry (AI simply unavailable), never a crash.
  static Future<ModelRegistry> fromManifest(
    AssetLoader load, {
    InstalledModelLoader loadInstalled = _notInstalled,
  }) async {
    try {
      final json = jsonDecode(utf8.decode(await load(manifestAsset)));
      if (json is! Map<String, Object?> ||
          json['schemaVersion'] != supportedSchema ||
          json['models'] is! List) {
        return ModelRegistry(load, const []);
      }
      return ModelRegistry(load, loadInstalled: loadInstalled, [
        for (final entry in json['models']! as List<Object?>)
          ?ModelDescriptor.tryParse(entry),
      ]);
    } on Exception {
      // Missing manifest (AssetMissingException), malformed JSON, bad UTF-8.
      return ModelRegistry(load, const []);
    }
  }

  ModelDescriptor? forTask(String task) {
    for (final m in models) {
      if (m.task == task) return m;
    }
    return null;
  }

  /// A bundled text asset, such as a model's label table.
  Future<Result<String>> loadText(String key) async {
    try {
      return Success(utf8.decode(await _load(key)));
    } on Exception catch (e) {
      return Failure(ModelUnavailableFailure('Missing asset $key', cause: e));
    }
  }

  /// The model's bytes, only if they match the manifest's SHA-256.
  Future<Result<Uint8List>> loadVerified(ModelDescriptor model) async {
    final Uint8List bytes;
    try {
      final asset = model.asset;
      bytes = asset != null ? await _load(asset) : await _loadInstalled(model);
    } on Exception catch (e) {
      return Failure(
        ModelUnavailableFailure('Model ${model.id} is not installed', cause: e),
      );
    }
    if (sha256.convert(bytes).toString() != model.sha256) {
      return Failure(
        ModelCorruptFailure('Model ${model.id} failed its integrity check'),
      );
    }
    return Success(bytes);
  }
}
