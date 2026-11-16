import 'package:wardrobe_domain/wardrobe_domain.dart';

import 'image_color_analyzer.dart';

/// Tier-0 analyzer (DECISIONS D-08, D-25): deterministic colour extraction
/// with no model. Suggests the main colour (with alternatives) and secondary
/// colours. Never suggests category, type or pattern.
final class ColorTier0Analyzer implements ClothingAnalyzer {
  const ColorTier0Analyzer({
    this.images = const ImageColorAnalyzer(),
    required this._clock,
  });

  final ImageColorAnalyzer images;
  final Clock _clock;

  /// Recorded with every suggestion (FR-04 provenance).
  static const source = AnalysisSource(
    modelId: 'color-tier0',
    modelVersion: '1.0.0',
  );

  /// Secondary colours below this share are noise, not suggestions.
  static const secondaryMinShare = 0.15;

  @override
  Future<Result<ClothingAnalysis>> analyze(AnalysisInput input) async {
    final result = await images.analyzeFile(input.imagePath);
    final at = _clock.nowUtc();
    return switch (result) {
      Failure(:final failure) => Failure(failure),
      Success(:final value) => Success(_toAnalysis(value, at)),
    };
  }

  ClothingAnalysis _toAnalysis(ColorAnalysis c, DateTime at) {
    final primary = c.primary;
    if (primary == null) return ClothingAnalysis.empty;
    final others = [
      for (final e in c.shares.entries)
        if (e.key != primary) (e.key, e.value),
    ];
    return ClothingAnalysis(
      primaryColor: Suggestion(
        value: primary,
        confidence: c.confidence,
        source: source,
        analyzedAt: at,
        alternatives: others.take(3).toList(),
      ),
      secondaryColors: [
        for (final (color, share) in others)
          if (share >= secondaryMinShare)
            Suggestion(
              value: color,
              confidence: share,
              source: source,
              analyzedAt: at,
            ),
      ],
    );
  }
}
