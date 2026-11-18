import 'package:material_ui/material_ui.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

String _pct(double v) => '${(v * 100).round()}%';

/// Explains a model suggestion for one single-choice attribute (category,
/// type or pattern): how sure the model is, and tappable alternatives when
/// it is unsure or the user picked something else. Transparent about
/// uncertainty (REQUIREMENTS §4); never changes the form by itself.
class AttributeSuggestionNote<T> extends StatelessWidget {
  const AttributeSuggestionNote({
    required this.suggestion,
    required this.policy,
    required this.current,
    required this.labelOf,
    required this.noun,
    required this.onPick,
    super.key,
  });

  final Suggestion<T>? suggestion;
  final ConfidencePolicy policy;

  /// The value currently selected in the form.
  final T? current;
  final String Function(T) labelOf;

  /// For example "category", "type" or "pattern".
  final String noun;
  final ValueChanged<T> onPick;

  @override
  Widget build(BuildContext context) {
    final s = suggestion;
    if (s == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final level = policy.levelOf(s.confidence);
    final showingSuggestion = current == s.value;
    final hints = [
      if (!showingSuggestion) (s.value, s.confidence),
      ...s.alternatives.where((a) => a.$1 != current),
    ].take(3).toList();

    final (icon, color, text) = switch ((level, showingSuggestion)) {
      (SuggestionLevel.prefill, true) => (
        Icons.center_focus_strong_outlined,
        scheme.primary,
        'Suggested from the photo (${_pct(s.confidence)}).',
      ),
      (SuggestionLevel.confirm, true) => (
        Icons.help_outline,
        scheme.tertiary,
        'Please confirm: not sure about this $noun (${_pct(s.confidence)}).',
      ),
      (SuggestionLevel.hint, _) => (
        Icons.help_outline,
        scheme.tertiary,
        'Not sure about the $noun. Possible:',
      ),
      (_, false) => (
        Icons.center_focus_strong_outlined,
        scheme.outline,
        'The photo suggested:',
      ),
    };
    final showHints =
        hints.isNotEmpty &&
        (level != SuggestionLevel.prefill || !showingSuggestion);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(text, style: Theme.of(context).textTheme.bodySmall),
              ),
            ],
          ),
          if (showHints)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final (value, conf) in hints)
                    ActionChip(
                      label: Text('${labelOf(value)} ${_pct(conf)}'),
                      onPressed: () => onPick(value),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
