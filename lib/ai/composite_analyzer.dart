import 'dart:async';

import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../core/logging/app_logger.dart';

/// Runs every available analyzer and merges their suggestions; earlier
/// analyzers win for the same attribute. One analyzer failing or timing out
/// never blocks the others, and never blocks manual entry.
final class CompositeClothingAnalyzer implements ClothingAnalyzer {
  CompositeClothingAnalyzer(
    List<ClothingAnalyzer> analyzers, {
    this.timeout = const Duration(seconds: 15),
  }) : analyzers = List.unmodifiable(analyzers);

  final List<ClothingAnalyzer> analyzers;
  final Duration timeout;

  @override
  Future<Result<ClothingAnalysis>> analyze(AnalysisInput input) async {
    if (analyzers.isEmpty) {
      return const Failure(ModelUnavailableFailure('No analyzer available'));
    }
    final results = await Future.wait([
      for (final a in analyzers) _runOne(a, input),
    ]);
    var merged = ClothingAnalysis.empty;
    AppFailure? firstFailure;
    for (final r in results) {
      switch (r) {
        case Success(:final value):
          merged = merged.mergedWith(value);
        case Failure(:final failure):
          AppLogger.error('Analyzer failed', failure);
          firstFailure ??= failure;
      }
    }
    // Partial success is success; only report failure when nothing worked.
    if (merged.isEmpty && firstFailure != null) return Failure(firstFailure);
    return Success(merged);
  }

  /// Runs one analyzer with a timeout. Uses `TimeoutException` rather than
  /// `onTimeout`: the analyzer's future may be reified as a narrower type
  /// (e.g. `Future<Success<…>>`), and returning a `Failure` from
  /// `onTimeout` would then throw a type error.
  Future<Result<ClothingAnalysis>> _runOne(
    ClothingAnalyzer analyzer,
    AnalysisInput input,
  ) async {
    try {
      return await analyzer.analyze(input).timeout(timeout);
    } on TimeoutException {
      return Failure(
        InferenceFailure('${analyzer.runtimeType} timed out after $timeout'),
      );
    } on Exception catch (e) {
      // Analyzers must not throw; if one does, contain it as a typed failure
      // so manual entry is never blocked.
      return Failure(
        InferenceFailure('${analyzer.runtimeType} threw', cause: e),
      );
    }
  }
}
