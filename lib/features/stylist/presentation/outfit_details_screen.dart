import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:outfit_engine/outfit_engine.dart';

import '../../../app/routes.dart';
import '../../../shared/outfit_labels.dart';
import '../../../shared/taxonomy_labels.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/item_thumbnail.dart';
import '../../favorites/presentation/feedback_bar.dart';
import '../../wardrobe/wardrobe_providers.dart';
import '../stylist_providers.dart';
import 'outfit_card.dart';

/// Full view of one outfit: its pieces, why it was suggested and the score
/// breakdown with the weights that produced it (FR-06 explainability).
class OutfitDetailsScreen extends ConsumerWidget {
  const OutfitDetailsScreen({required this.outfitId, super.key});

  final String outfitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedOutfitProvider(outfitId));
    return Scaffold(
      appBar: AppBar(title: const Text('Outfit')),
      body: switch (saved) {
        AsyncData(value: final SavedOutfit value) => _Body(saved: value),
        AsyncData() => const EmptyState(
          icon: Icons.search_off,
          title: 'Outfit not found',
          message: 'It may have been removed.',
        ),
        AsyncError(:final error) => ErrorState(
          title: 'This outfit did not open',
          error: error,
          fallback: 'Go back and open it again.',
          onRetry: () => ref.invalidate(savedOutfitProvider(outfitId)),
        ),
        _ => const LoadingState(),
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.saved});

  final SavedOutfit saved;

  @override
  Widget build(BuildContext context) {
    final outfit = saved.outfit;
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${OutfitLabels.occasion(saved.occasion)} · '
          '${(outfit.totalScore * 100).round()}% match',
          style: text.titleMedium,
        ),
        FeedbackBar(outfitId: saved.id),
        for (final piece in outfit.pieces) _PieceTile(piece: piece),
        const SizedBox(height: 16),
        Text('Why this outfit', style: text.titleSmall),
        // Missing weather is explained below the breakdown instead.
        for (final r in outfit.reasons)
          if (r != ReasonCode.weatherNotConsidered) ReasonLine(reason: r),
        const SizedBox(height: 16),
        Text('Score breakdown', style: text.titleSmall),
        const SizedBox(height: 4),
        for (final c in ScoreComponent.values)
          if (outfit.breakdown[c] case final score?)
            _ComponentBar(
              label: OutfitLabels.component(c),
              score: score,
              weight: outfit.weights[c] ?? 0,
            ),
        if (!outfit.weatherConsidered)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Weather was not included, so its weight was shared among the '
              'other factors.',
              style: text.bodySmall,
            ),
          ),
      ],
    );
  }
}

class _PieceTile extends ConsumerWidget {
  const _PieceTile({required this.piece});

  final OutfitPiece piece;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(clothingItemProvider(piece.itemId)).value;
    final title = item == null
        ? 'No longer in your wardrobe'
        : Labels.itemTitle(item);
    final slot = OutfitLabels.slot(piece.slot);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox.square(
          dimension: 56,
          child: StoredImage(
            relativePath: item?.images?.displayThumbnail,
            cacheWidth: 168,
          ),
        ),
      ),
      title: Text(title),
      // Avoid "Top / Top" when the item has no name of its own.
      subtitle: slot == title ? null : Text(slot),
      onTap: item == null
          ? null
          : () => context.push(AppRoutes.item(piece.itemId)),
    );
  }
}

class _ComponentBar extends StatelessWidget {
  const _ComponentBar({
    required this.label,
    required this.score,
    required this.weight,
  });

  final String label;
  final double score;
  final double weight;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              '${(score * 100).round()}%  ·  weight ${(weight * 100).round()}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        // The default semantics value already announces the percentage.
        LinearProgressIndicator(value: score, semanticsLabel: '$label score'),
      ],
    ),
  );
}
