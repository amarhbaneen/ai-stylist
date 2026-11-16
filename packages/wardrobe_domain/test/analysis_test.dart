import 'package:test/test.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

const _source = AnalysisSource(modelId: 'test-model', modelVersion: '1');
final _at = DateTime.utc(2026, 11, 16);

Suggestion<ColorFamily> _color(ColorFamily c, double conf) =>
    Suggestion(value: c, confidence: conf, source: _source, analyzedAt: _at);

final class _FakeAnalyzer implements ClothingAnalyzer {
  _FakeAnalyzer(this.result);

  Result<ClothingAnalysis> result;
  var calls = 0;

  @override
  Future<Result<ClothingAnalysis>> analyze(AnalysisInput input) async {
    calls++;
    return result;
  }
}

final class _FakeRepo implements AnalysisRepository {
  final stored = <String, ClothingAnalysis>{};
  Map<AnalyzedAttribute, Set<String>>? kept;

  @override
  Future<Result<ClothingAnalysis?>> load(String itemId) async =>
      Success(stored[itemId]);

  @override
  Future<Result<void>> save(String itemId, ClothingAnalysis analysis) async {
    stored[itemId] = analysis;
    return const Success(null);
  }

  @override
  Future<Result<void>> markConfirmed(
    String itemId,
    Map<AnalyzedAttribute, Set<String>> keptCodes,
  ) async {
    kept = keptCodes;
    return const Success(null);
  }
}

void main() {
  group('ConfidencePolicy (D-09)', () {
    const policy = ConfidencePolicy();

    test('maps confidence to how the suggestion is shown', () {
      expect(policy.levelOf(0.95), SuggestionLevel.prefill);
      expect(policy.levelOf(0.80), SuggestionLevel.prefill);
      expect(policy.levelOf(0.79), SuggestionLevel.confirm);
      expect(policy.levelOf(0.50), SuggestionLevel.confirm);
      expect(policy.levelOf(0.49), SuggestionLevel.hint);
      expect(policy.levelOf(0), SuggestionLevel.hint);
    });

    test('thresholds are configurable', () {
      const strict = ConfidencePolicy(prefillAt: 0.9, confirmAt: 0.7);
      expect(strict.levelOf(0.85), SuggestionLevel.confirm);
    });
  });

  group('Suggestion', () {
    test('confidence is clamped to 0..1', () {
      expect(_color(ColorFamily.red, 1.7).confidence, 1);
      expect(_color(ColorFamily.red, -0.2).confidence, 0);
    });
  });

  group('ClothingAnalysis', () {
    test('merge keeps existing values and fills gaps', () {
      final colours = ClothingAnalysis(
        primaryColor: _color(ColorFamily.navy, 0.9),
      );
      final category = ClothingAnalysis(
        category: Suggestion(
          value: GarmentCategory.top,
          confidence: 0.7,
          source: _source,
          analyzedAt: _at,
        ),
        primaryColor: _color(ColorFamily.red, 0.99),
      );
      final merged = colours.mergedWith(category);
      expect(merged.primaryColor!.value, ColorFamily.navy);
      expect(merged.category!.value, GarmentCategory.top);
      expect(ClothingAnalysis.empty.isEmpty, isTrue);
    });
  });

  group('OutputValidator', () {
    const validator = OutputValidator();
    const labels = {
      'tshirt': 'TOP',
      'shirt': 'TOP',
      'jeans': 'BOTTOM',
      'sneaker': 'FOOTWEAR',
      'mystery': 'SPACESUIT', // maps to a code the taxonomy does not know
    };

    Suggestion<GarmentCategory>? run(Map<String, double> raw) =>
        validator.validate<GarmentCategory>(
          rawScores: raw,
          labelToCode: labels,
          parse: (c) => switch (GarmentCategory.fromCode(c)) {
            GarmentCategory.unknown => null,
            final v => v,
          },
          source: _source,
          analyzedAt: _at,
        );

    test('maps labels to taxonomy and sums labels of the same value', () {
      final s = run({'tshirt': 0.4, 'shirt': 0.3, 'jeans': 0.3})!;
      expect(s.value, GarmentCategory.top);
      expect(s.confidence, closeTo(0.7, 1e-9));
      expect(s.alternatives.single.$1, GarmentCategory.bottom);
      expect(s.source, _source);
    });

    test('drops NaN, infinite, negative and unmapped scores', () {
      final s = run({
        'tshirt': double.nan,
        'jeans': -1,
        'sneaker': double.infinity,
        'unlabelled': 0.9,
        'shirt': 0.05,
      })!;
      expect(s.value, GarmentCategory.top);
      // Scores already sum to ≤ 1, so they are kept as probabilities: mass on
      // the unmapped label stays "unknown" and keeps confidence honest-low.
      expect(s.confidence, closeTo(0.05, 1e-9));
    });

    test('never invents a value the taxonomy does not have', () {
      expect(run({'mystery': 0.99}), isNull);
      expect(run({}), isNull);
      expect(run({'tshirt': 0}), isNull);
    });

    test('normalises scores that sum above 1 (e.g. logits)', () {
      final s = run({'tshirt': 3, 'jeans': 1})!;
      expect(s.confidence, closeTo(0.75, 1e-9));
    });
  });

  group('AnalyzeClothingItem', () {
    const input = AnalysisInput(itemId: 'i1', imagePath: '/tmp/t.jpg');

    test('runs once, then serves the stored result', () async {
      final analyzer = _FakeAnalyzer(
        Success(ClothingAnalysis(primaryColor: _color(ColorFamily.navy, 0.9))),
      );
      final repo = _FakeRepo();
      final analyze = AnalyzeClothingItem(analyzer, repo);

      await analyze(input);
      final second = await analyze(input);

      expect(analyzer.calls, 1);
      expect(second.valueOrNull!.primaryColor!.value, ColorFamily.navy);
    });

    test('failures are returned, not thrown, and not cached', () async {
      final analyzer = _FakeAnalyzer(
        const Failure(InferenceFailure('model crashed')),
      );
      final repo = _FakeRepo();
      final result = await AnalyzeClothingItem(analyzer, repo)(input);
      expect((result as Failure).failure, isA<InferenceFailure>());
      expect(repo.stored, isEmpty);
    });
  });

  test('ConfirmAnalysis reports what the user kept', () async {
    final repo = _FakeRepo();
    await ConfirmAnalysis(repo)(
      'i1',
      ClothingAttributes(
        category: GarmentCategory.top,
        primaryColor: ColorFamily.navy,
        secondaryColors: {ColorFamily.white},
      ),
    );
    expect(repo.kept![AnalyzedAttribute.primaryColor], {'NAVY'});
    expect(repo.kept![AnalyzedAttribute.secondaryColor], {'WHITE'});
    expect(repo.kept![AnalyzedAttribute.category], {'TOP'});
  });
}
