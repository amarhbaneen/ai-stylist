import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../../shared/taxonomy_labels.dart';
import '../../../shared/widgets/chip_selectors.dart';
import '../favorites_providers.dart';

/// Shows what was learned from likes and dislikes, separately from the
/// explicit preferences above it, and lets the user reset it (FR-08).
class LearnedPreferencesSection extends ConsumerWidget {
  const LearnedPreferencesSection({super.key});

  /// Weights smaller than this are not worth showing as a tendency.
  static const _threshold = 0.02;

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset what was learned?'),
        content: const Text(
          'The stylist forgets what it learned from your likes and dislikes. '
          'Your saved outfits, history and the preferences above are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref.read(resetPersonalizationProvider).call();
    messenger.showSnackBar(
      SnackBar(
        content: Text(switch (result) {
          Success() => 'Learning reset',
          Failure(:final failure) => failureMessage(failure),
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learned = ref.watch(learnedPreferencesProvider).value;
    final weights = learned?.weights ?? const <String, double>{};
    final colors = [
      for (final e in weights.entries)
        if (e.key.startsWith('color:'))
          if (ColorFamily.tryFromCode(e.key.substring(6)) case final c?)
            (c, e.value),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    final liked = [
      for (final (c, w) in colors)
        if (w >= _threshold) c,
    ].take(4).toList();
    final avoided = [
      for (final (c, w) in colors.reversed)
        if (w <= -_threshold) c,
    ].take(4).toList();
    final items = weights.keys.where((k) => k.startsWith('item:')).length;
    final pairs = weights.keys.where((k) => k.startsWith('pair:')).length;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 40),
        Text('Learned from your feedback', style: text.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Based on outfits you liked or disliked, and kept separate from '
          'the choices above. It only adjusts rankings a little.',
          style: text.bodySmall,
        ),
        if (weights.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Nothing learned yet. Like or dislike outfits in the Stylist '
              'to teach it.',
            ),
          )
        else ...[
          if (liked.isNotEmpty) ...[
            const FieldLabel('You tend to like'),
            _Colors(colors: liked),
          ],
          if (avoided.isNotEmpty) ...[
            const FieldLabel('You tend to skip'),
            _Colors(colors: avoided),
          ],
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Adjusted: $items garment${items == 1 ? '' : 's'}, '
              '$pairs pairing${pairs == 1 ? '' : 's'}.',
              style: text.bodySmall,
            ),
          ),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: weights.isEmpty ? null : () => _reset(context, ref),
          icon: const Icon(Icons.restart_alt),
          label: const Text('Reset learning'),
        ),
      ],
    );
  }
}

class _Colors extends StatelessWidget {
  const _Colors({required this.colors});

  final List<ColorFamily> colors;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 4,
    children: [
      for (final c in colors)
        Chip(avatar: ColorDot(Labels.swatch(c)), label: Text(Labels.color(c))),
    ],
  );
}
