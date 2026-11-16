import 'package:material_ui/material_ui.dart';

/// Labelled section heading used in forms.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}

/// Multi-select filter chips over [options].
class MultiChipSelector<T> extends StatelessWidget {
  const MultiChipSelector({
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    this.avatarOf,
    super.key,
  });

  final List<T> options;
  final Set<T> selected;
  final String Function(T) labelOf;
  final Widget? Function(T)? avatarOf;
  final ValueChanged<Set<T>> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 4,
    children: [
      for (final option in options)
        FilterChip(
          label: Text(labelOf(option)),
          avatar: avatarOf?.call(option),
          selected: selected.contains(option),
          onSelected: (on) => onChanged(
            on ? {...selected, option} : ({...selected}..remove(option)),
          ),
        ),
    ],
  );
}

/// Single-select choice chips; tapping the selected chip clears it (null).
class SingleChipSelector<T> extends StatelessWidget {
  const SingleChipSelector({
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    this.avatarOf,
    super.key,
  });

  final List<T> options;
  final T? selected;
  final String Function(T) labelOf;
  final Widget? Function(T)? avatarOf;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 4,
    children: [
      for (final option in options)
        ChoiceChip(
          label: Text(labelOf(option)),
          avatar: avatarOf?.call(option),
          selected: option == selected,
          onSelected: (on) => onChanged(on ? option : null),
        ),
    ],
  );
}

/// Small colour dot used as a chip avatar.
class ColorDot extends StatelessWidget {
  const ColorDot(this.color, {super.key});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 16,
    height: 16,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Theme.of(context).colorScheme.outline),
    ),
  );
}
