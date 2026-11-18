import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../../shared/taxonomy_labels.dart';
import '../../../shared/widgets/chip_selectors.dart';

String _pct(double v) => '${(v * 100).round()}%';

/// Explains the main-colour suggestion: progress, confidence level, or
/// tappable hints when the analysis is unsure. Transparent about
/// uncertainty (REQUIREMENTS §4).
class PrimaryColorNote extends StatelessWidget {
  const PrimaryColorNote({
    required this.analysis,
    required this.policy,
    required this.current,
    required this.onPick,
    super.key,
  });

  final AsyncValue<ClothingAnalysis> analysis;
  final ConfidencePolicy policy;

  /// The colour currently selected in the form.
  final ColorFamily? current;
  final ValueChanged<ColorFamily> onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (analysis) {
      AsyncData(:final value) => _forData(context, value.primaryColor),
      AsyncError() => _Line(
        icon: Icon(Icons.info_outline, size: 18, color: scheme.outline),
        text: 'Couldn\'t detect colours. Choose them below.',
      ),
      _ => const _Line(
        icon: SizedBox.square(
          dimension: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        text: 'Detecting colours from the photo…',
      ),
    };
  }

  Widget _forData(BuildContext context, Suggestion<ColorFamily>? s) {
    if (s == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final level = policy.levelOf(s.confidence);
    final showingSuggestion = current == s.value;
    final hints = [
      if (!showingSuggestion) (s.value, s.confidence),
      ...s.alternatives.where((a) => a.$1 != current),
    ].take(3).toList();

    final line = switch ((level, showingSuggestion)) {
      (SuggestionLevel.prefill, true) => _Line(
        icon: Icon(
          Icons.center_focus_strong_outlined,
          size: 18,
          color: scheme.primary,
        ),
        text:
            'Suggested from the photo (${_pct(s.confidence)}). '
            'Tap another colour to change it.',
      ),
      (SuggestionLevel.confirm, true) => _Line(
        icon: Icon(Icons.help_outline, size: 18, color: scheme.tertiary),
        text:
            'Please confirm: not sure about this colour '
            '(${_pct(s.confidence)}).',
      ),
      (SuggestionLevel.hint, _) => _Line(
        icon: Icon(Icons.help_outline, size: 18, color: scheme.tertiary),
        text: 'Not sure about the colour. Possible:',
      ),
      (_, false) => _Line(
        icon: Icon(
          Icons.center_focus_strong_outlined,
          size: 18,
          color: scheme.outline,
        ),
        text: 'The photo suggested:',
      ),
    };
    final showHints =
        hints.isNotEmpty &&
        (level != SuggestionLevel.prefill || !showingSuggestion);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        line,
        if (showHints) _HintChips(hints: hints, onPick: onPick),
      ],
    );
  }
}

/// Offers detected secondary colours as tappable chips (never prefilled).
class SecondaryColorNote extends StatelessWidget {
  const SecondaryColorNote({
    required this.suggestions,
    required this.primary,
    required this.selected,
    required this.onAdd,
    super.key,
  });

  final List<Suggestion<ColorFamily>> suggestions;
  final ColorFamily? primary;
  final Set<ColorFamily> selected;
  final ValueChanged<ColorFamily> onAdd;

  @override
  Widget build(BuildContext context) {
    final offers = [
      for (final s in suggestions)
        if (s.value != primary && !selected.contains(s.value))
          (s.value, s.confidence),
    ];
    if (offers.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Line(
          icon: Icon(
            Icons.center_focus_strong_outlined,
            size: 18,
            color: Theme.of(context).colorScheme.outline,
          ),
          text: 'Also detected in the photo:',
        ),
        _HintChips(hints: offers, onPick: onAdd, adding: true),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final Widget icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        icon,
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    ),
  );
}

class _HintChips extends StatelessWidget {
  const _HintChips({
    required this.hints,
    required this.onPick,
    this.adding = false,
  });

  final List<(ColorFamily, double)> hints;
  final ValueChanged<ColorFamily> onPick;
  final bool adding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final (c, conf) in hints)
          ActionChip(
            avatar: adding
                ? const Icon(Icons.add, size: 18)
                : ColorDot(Labels.swatch(c)),
            label: Text('${Labels.color(c)} ${_pct(conf)}'),
            onPressed: () => onPick(c),
          ),
      ],
    ),
  );
}
