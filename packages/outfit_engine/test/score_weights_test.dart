import 'package:outfit_engine/outfit_engine.dart';
import 'package:test/test.dart';

double _sum(Map<ScoreComponent, double> m) => m.values.fold(0, (a, b) => a + b);

void main() {
  group('ScoreWeights', () {
    test('defaults sum to 1 with weather', () {
      final w = ScoreWeights.defaults().normalized(weatherAvailable: true);
      expect(_sum(w), closeTo(1.0, 1e-9));
      expect(w[ScoreComponent.color], closeTo(0.25, 1e-9));
      expect(w[ScoreComponent.weather], closeTo(0.15, 1e-9));
    });

    test('weather is omitted, not scored as zero, when unavailable', () {
      final w = ScoreWeights.defaults().normalized(weatherAvailable: false);
      expect(w.containsKey(ScoreComponent.weather), isFalse);
      expect(_sum(w), closeTo(1.0, 1e-9));
      // Remaining weights keep their relative proportions (0.25 / 0.85).
      expect(w[ScoreComponent.color], closeTo(0.25 / 0.85, 1e-9));
    });

    test('non-normalised input is normalised', () {
      final w = ScoreWeights({ScoreComponent.color: 2, ScoreComponent.style: 2})
          .normalized(weatherAvailable: true);
      expect(w[ScoreComponent.color], closeTo(0.5, 1e-9));
      expect(w[ScoreComponent.variety], 0);
    });

    test('rejects negative or all-zero weights', () {
      expect(
        () => ScoreWeights({ScoreComponent.color: -1}),
        throwsArgumentError,
      );
      expect(
        () => ScoreWeights({ScoreComponent.color: 0}),
        throwsArgumentError,
      );
    });

    test('fails clearly when only weather is weighted and it is missing', () {
      final w = ScoreWeights({ScoreComponent.weather: 1});
      expect(() => w.normalized(weatherAvailable: false), throwsStateError);
    });
  });
}
