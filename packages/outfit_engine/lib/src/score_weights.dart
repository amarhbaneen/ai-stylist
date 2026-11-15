/// Scoring components from REQUIREMENTS FR-07.
enum ScoreComponent { color, style, occasion, weather, preference, variety }

/// Configurable component weights, normalised so they sum to 1.0.
///
/// When weather is not available it is *omitted* and the remaining weights
/// are renormalised (FR-07: missing weather must not count as a bad score).
final class ScoreWeights {
  ScoreWeights(Map<ScoreComponent, double> raw) : _raw = Map.unmodifiable(raw) {
    for (final entry in raw.entries) {
      if (entry.value.isNaN || entry.value < 0) {
        throw ArgumentError.value(
          entry.value,
          entry.key.name,
          'Weights must be finite and non-negative',
        );
      }
    }
    if (_sum(raw.values) <= 0) {
      throw ArgumentError('At least one weight must be positive');
    }
  }

  /// FR-07 initial weights.
  factory ScoreWeights.defaults() => ScoreWeights(const {
    ScoreComponent.color: 0.25,
    ScoreComponent.style: 0.20,
    ScoreComponent.occasion: 0.20,
    ScoreComponent.weather: 0.15,
    ScoreComponent.preference: 0.15,
    ScoreComponent.variety: 0.05,
  });

  final Map<ScoreComponent, double> _raw;

  /// Returns weights normalised to sum to 1.0. Components missing from the
  /// configuration get 0. When [weatherAvailable] is false, weather is
  /// removed from the result entirely.
  Map<ScoreComponent, double> normalized({required bool weatherAvailable}) {
    final active = <ScoreComponent, double>{
      for (final c in ScoreComponent.values)
        if (weatherAvailable || c != ScoreComponent.weather) c: _raw[c] ?? 0,
    };
    final total = _sum(active.values);
    if (total <= 0) {
      throw StateError('No positive weights remain after omitting weather');
    }
    return Map.unmodifiable({
      for (final e in active.entries) e.key: e.value / total,
    });
  }

  static double _sum(Iterable<double> values) =>
      values.fold(0, (sum, v) => sum + v);
}
