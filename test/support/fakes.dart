import 'dart:io';
import 'dart:typed_data';

import 'package:ai_stylist/core/media/image_processor.dart';
import 'package:ai_stylist/core/media/media_picker.dart';
import 'package:ai_stylist/core/storage/file_store.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

final class FixedClock implements Clock {
  FixedClock([DateTime? now]) : now = now ?? DateTime.utc(2026, 11, 16, 9);

  DateTime now;

  @override
  DateTime nowUtc() => now;
}

/// Deterministic, readable IDs: id-1, id-2, ...
final class SequentialIds implements IdGenerator {
  var _next = 1;

  @override
  String newId() => 'id-${_next++}';
}

/// Returns small fake JPEG bytes, or `null` to simulate an undecodable file.
final class FakeImageProcessor implements ImageProcessor {
  bool fail = false;
  final calls = <(String, int)>[];

  @override
  Future<Uint8List?> downscaleToJpeg(
    String sourcePath, {
    required int maxEdge,
    required int quality,
  }) async {
    calls.add((sourcePath, maxEdge));
    if (fail) return null;
    return Uint8List.fromList([0xFF, 0xD8, maxEdge & 0xFF, 0xFF, 0xD9]);
  }
}

/// Scripted picker: returns queued results in order.
final class FakeMediaPicker implements MediaPicker {
  final results = <Result<String>>[];
  String? lost;
  final requested = <MediaSourceKind>[];

  @override
  Future<Result<String>> pick(MediaSourceKind source) async {
    requested.add(source);
    return results.isEmpty
        ? const Failure(CancelledFailure())
        : results.removeAt(0);
  }

  @override
  Future<String?> recoverLostPick() async {
    final value = lost;
    lost = null;
    return value;
  }
}

/// Wraps a [FileStore] and fails writes whose path contains [failOn].
final class FlakyFileStore implements FileStore {
  FlakyFileStore(this.inner);

  final FileStore inner;
  String? failOn;

  @override
  Future<Result<void>> writeBytes(String relativePath, Uint8List bytes) {
    if (failOn != null && relativePath.contains(failOn!)) {
      return Future.value(
        const Failure(InsufficientStorageFailure('Disk full (simulated)')),
      );
    }
    return inner.writeBytes(relativePath, bytes);
  }

  @override
  Future<Result<void>> copyIn(File source, String relativePath) =>
      inner.copyIn(source, relativePath);

  @override
  Future<Result<Uint8List>> readBytes(String relativePath) =>
      inner.readBytes(relativePath);

  @override
  Future<bool> exists(String relativePath) => inner.exists(relativePath);

  @override
  Future<Result<void>> delete(String relativePath) =>
      inner.delete(relativePath);

  @override
  Future<Result<List<String>>> list(String relativeDir) =>
      inner.list(relativeDir);

  @override
  File resolve(String relativePath) => inner.resolve(relativePath);
}

/// Analyzer returning a scripted result (default: nothing suggested).
final class FakeClothingAnalyzer implements ClothingAnalyzer {
  Result<ClothingAnalysis> result = Success(ClothingAnalysis.empty);
  var calls = 0;

  @override
  Future<Result<ClothingAnalysis>> analyze(AnalysisInput input) async {
    calls++;
    return result;
  }
}

/// Writes a fake photo with distinct bytes into [dir].
Future<String> writePhoto(Directory dir, String name, {int seed = 1}) async {
  final file = File('${dir.path}${Platform.pathSeparator}$name');
  await file.writeAsBytes(List<int>.generate(64, (i) => (i * seed) & 0xFF));
  return file.path;
}
