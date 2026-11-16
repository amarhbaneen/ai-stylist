import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

/// One bundled model, described by the in-app manifest. The manifest ships
/// inside the app, so it is trusted metadata: a model file is only used if
/// its bytes match the SHA-256 recorded here (FR-09, D-16).
@immutable
final class ModelDescriptor {
  ModelDescriptor({
    required this.id,
    required this.version,
    required this.task,
    required this.asset,
    required this.sha256,
    required this.license,
    Map<String, String> labels = const {},
  }) : labels = Map.unmodifiable(labels);

  final String id;
  final String version;

  /// For example `garment-category`.
  final String task;

  /// Asset key of the model file.
  final String asset;

  /// Lower-case hex SHA-256 of the model file.
  final String sha256;
  final String license;

  /// Model output label → taxonomy code (see `OutputValidator`).
  final Map<String, String> labels;

  AnalysisSource get source =>
      AnalysisSource(modelId: id, modelVersion: version);

  static final _hex64 = RegExp(r'^[0-9a-f]{64}$');

  /// Strict parse: any missing or malformed field rejects the entry.
  static ModelDescriptor? tryParse(Object? json) {
    if (json is! Map<String, Object?>) return null;
    String? str(String key) => switch (json[key]) {
      final String s when s.trim().isNotEmpty => s,
      _ => null,
    };
    final id = str('id'), version = str('version'), task = str('task');
    final asset = str('asset'), license = str('license');
    final sha = str('sha256')?.toLowerCase();
    if ([id, version, task, asset, license, sha].contains(null)) return null;
    if (!_hex64.hasMatch(sha!)) return null;
    final rawLabels = json['labels'];
    final labels = <String, String>{
      if (rawLabels is Map<String, Object?>)
        for (final e in rawLabels.entries)
          if (e.value case final String code) e.key: code,
    };
    return ModelDescriptor(
      id: id!,
      version: version!,
      task: task!,
      asset: asset!,
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

/// Known models and integrity-checked loading.
final class ModelRegistry {
  ModelRegistry(this._load, List<ModelDescriptor> models)
    : models = List.unmodifiable(models);

  static const manifestAsset = 'assets/models/manifest.json';
  static const supportedSchema = 1;

  final AssetLoader _load;
  final List<ModelDescriptor> models;

  /// Reads the bundled manifest. A missing or malformed manifest yields an
  /// empty registry (AI simply unavailable), never a crash.
  static Future<ModelRegistry> fromManifest(AssetLoader load) async {
    try {
      final json = jsonDecode(utf8.decode(await load(manifestAsset)));
      if (json is! Map<String, Object?> ||
          json['schemaVersion'] != supportedSchema ||
          json['models'] is! List) {
        return ModelRegistry(load, const []);
      }
      return ModelRegistry(load, [
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

  /// The model's bytes, only if they match the manifest's SHA-256.
  Future<Result<Uint8List>> loadVerified(ModelDescriptor model) async {
    final Uint8List bytes;
    try {
      bytes = await _load(model.asset);
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
