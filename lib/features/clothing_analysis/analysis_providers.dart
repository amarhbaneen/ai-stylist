import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../ai/color/color_tier0_analyzer.dart';
import '../../ai/composite_analyzer.dart';
import '../../ai/download/model_download_manager.dart';
import '../../ai/garment/garment_classifier.dart';
import '../../ai/garment/garment_model_loader.dart';
import '../../ai/model_registry.dart';
import '../../ai/segmentation/garment_segmenter.dart';
import '../../ai/segmentation/litert_segmentation_session.dart';
import '../../ai/segmentation/person_mask.dart';
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

/// Bundled and optional models. Loading a model always goes
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

/// The bundled Tier-1 garment classifier (D-08, D-38). The model is
/// opened on first use and released when the provider is disposed.
@Riverpod(keepAlive: true)
GarmentClassifier garmentClassifier(Ref ref) {
  final classifier = GarmentClassifier(
    open: () async =>
        openGarmentModel(await ref.read(modelRegistryProvider.future)),
    clock: ref.watch(clockProvider),
  );
  ref.onDispose(classifier.close);
  return classifier;
}

/// The bundled garment segmentation model (FR-05, D-39, D-40), with the
/// person model for worn clothes (D-41). Opened on first use and released when the provider is disposed.
@Riverpod(keepAlive: true)
GarmentFinder garmentFinder(Ref ref) {
  final segmenter = GarmentSegmenter(
    open: () async =>
        openSegmentationModel(await ref.read(modelRegistryProvider.future)),
    openPerson: () async =>
        openPersonModel(await ref.read(modelRegistryProvider.future)),
    studioPolish: () async =>
        (await ref.read(studioPolishSettingsProvider).isEnabled())
            .valueOrNull ??
        true,
  );
  ref.onDispose(segmenter.close);
  return segmenter;
}

/// All analyzers available on this device: Tier 0 (colour) and the Tier-1
/// garment classifier (category, type, pattern). Either can fail without
/// blocking the other or manual entry.
@Riverpod(keepAlive: true)
ClothingAnalyzer clothingAnalyzer(Ref ref) => CompositeClothingAnalyzer([
  ColorTier0Analyzer(clock: ref.watch(clockProvider)),
  ref.watch(garmentClassifierProvider),
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
/// off the UI thread from the thumbnail being shown (the cut-out when the
/// background was removed; its unpolished copy when polished, D-44). Errors surface as `AsyncError`;
/// the review screen then simply offers manual entry.
@Riverpod(retry: _noRetry)
Future<ClothingAnalysis> clothingAnalysis(Ref ref, String itemId) async {
  final item = (await ref.read(wardrobeRepositoryProvider).getItem(itemId));
  final thumbnail = switch (item) {
    Success(:final value) => value.images?.analysisThumbnail,
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
