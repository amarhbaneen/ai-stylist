import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../ai/color/color_tier0_analyzer.dart';
import '../../ai/composite_analyzer.dart';
import '../../ai/download/model_download_manager.dart';
import '../../ai/model_registry.dart';
import '../../core/logging/app_logger.dart';
import '../../core/providers.dart';
import '../wardrobe/wardrobe_providers.dart';
import '../weather/weather_providers.dart';
import 'data/drift_analysis_repository.dart';

part 'analysis_providers.g.dart';

/// Thresholds for prefill / confirm / hint (D-09).
@Riverpod(keepAlive: true)
ConfidencePolicy confidencePolicy(Ref ref) => const ConfidencePolicy();

/// Optional model downloads (FR-09). Only runs when the user taps Download.
@Riverpod(keepAlive: true)
ModelDownloadManager modelDownloadManager(Ref ref) => ModelDownloadManager(
  database: ref.watch(appDatabaseProvider),
  files: ref.watch(fileStoreProvider),
  client: ref.watch(httpClientProvider),
  clock: ref.watch(clockProvider),
);

/// Bundled and optional models (none yet). Loading a model always goes
/// through the SHA-256 check in [ModelRegistry.loadVerified].
@Riverpod(keepAlive: true)
Future<ModelRegistry> modelRegistry(Ref ref) async {
  final downloads = ref.watch(modelDownloadManagerProvider);
  final registry = await ModelRegistry.fromManifest((key) async {
    try {
      final data = await rootBundle.load(key);
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } on FlutterError {
      throw AssetMissingException(key);
    }
  }, loadInstalled: downloads.readInstalled);
  // Interrupted or orphaned installs from a previous run. Best effort: a
  // failed clean-up must never make analysis unavailable.
  try {
    await downloads.recover(registry.downloadable);
  } on Exception catch (e, s) {
    AppLogger.error('Model clean-up failed', e, s);
  }
  return registry;
}

/// All analyzers available on this device. Tier 0 (colour) always; a
/// garment classifier joins here once a licensed model ships (D-08).
@Riverpod(keepAlive: true)
ClothingAnalyzer clothingAnalyzer(Ref ref) => CompositeClothingAnalyzer([
  ColorTier0Analyzer(clock: ref.watch(clockProvider)),
]);

@Riverpod(keepAlive: true)
AnalysisRepository analysisRepository(Ref ref) => DriftAnalysisRepository(
  database: ref.watch(appDatabaseProvider),
  ids: ref.watch(idGeneratorProvider),
);

@riverpod
ConfirmAnalysis confirmAnalysis(Ref ref) =>
    ConfirmAnalysis(ref.watch(analysisRepositoryProvider));

/// Riverpod 3 retries failing providers forever by default. A photo that
/// cannot be analysed will not succeed on retry, so fail once and let the
/// user enter details manually.
Duration? _noRetry(int retryCount, Object error) => null;

/// Suggestions for one item: cached if analysed before, otherwise computed
/// from its thumbnail off the UI thread. Errors surface as `AsyncError`;
/// the review screen then simply offers manual entry.
@Riverpod(retry: _noRetry)
Future<ClothingAnalysis> clothingAnalysis(Ref ref, String itemId) async {
  final item = (await ref.read(wardrobeRepositoryProvider).getItem(itemId));
  final thumbnail = switch (item) {
    Success(:final value) => value.images?.thumbnail,
    Failure(:final failure) => throw failure,
  };
  if (thumbnail == null) {
    throw const UnsupportedImageFailure('This item has no photo to analyse');
  }
  final path = ref.read(fileStoreProvider).resolve(thumbnail).path;
  final result = await AnalyzeClothingItem(
    ref.read(clothingAnalyzerProvider),
    ref.read(analysisRepositoryProvider),
  )(AnalysisInput(itemId: itemId, imagePath: path));
  return switch (result) {
    Success(:final value) => value,
    Failure(:final failure) => throw failure,
  };
}
