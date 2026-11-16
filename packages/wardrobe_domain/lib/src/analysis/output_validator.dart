import '../taxonomy/coded_enum.dart';
import 'analysis.dart';

/// Validates raw model output before it can become a [Suggestion]
/// (FR-04: "AI output must be structured and schema-validated").
///
/// - Scores must be finite and non-negative; invalid entries are dropped.
/// - Scores that do not already sum to ≤ 1 are normalised.
/// - Model labels are mapped to taxonomy codes through [labelToCode]; labels
///   with no mapping, or codes the taxonomy does not know, are discarded
///   (they become "unknown", never an invented value).
/// - Several labels mapping to the same code are summed.
final class OutputValidator {
  const OutputValidator();

  /// Returns the best mapped value with up to [maxAlternatives] runners-up,
  /// or `null` when nothing valid remains.
  Suggestion<T>? validate<T extends CodedEnum>({
    required Map<String, double> rawScores,
    required Map<String, String> labelToCode,
    required T? Function(String code) parse,
    required AnalysisSource source,
    required DateTime analyzedAt,
    int maxAlternatives = 3,
  }) {
    final valid = <String, double>{
      for (final e in rawScores.entries)
        if (e.value.isFinite && e.value >= 0) e.key: e.value,
    };
    final total = valid.values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return null;
    final scale = total > 1 + 1e-6 ? 1 / total : 1.0;

    final byValue = <T, double>{};
    for (final e in valid.entries) {
      final code = labelToCode[e.key];
      if (code == null) continue;
      final value = parse(code);
      if (value == null) continue;
      byValue[value] = (byValue[value] ?? 0) + e.value * scale;
    }
    if (byValue.isEmpty) return null;

    final ranked = byValue.entries.toList()
      ..sort((a, b) {
        final c = b.value.compareTo(a.value);
        return c != 0 ? c : a.key.code.compareTo(b.key.code);
      });
    return Suggestion(
      value: ranked.first.key,
      confidence: ranked.first.value,
      source: source,
      analyzedAt: analyzedAt,
      alternatives: [
        for (final e in ranked.skip(1).take(maxAlternatives)) (e.key, e.value),
      ],
    );
  }
}
