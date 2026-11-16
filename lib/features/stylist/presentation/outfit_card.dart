import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:outfit_engine/outfit_engine.dart';

import '../../../app/routes.dart';
import '../../../shared/outfit_labels.dart';
import '../../../shared/taxonomy_labels.dart';
import '../../../shared/widgets/item_thumbnail.dart';
import '../../wardrobe/wardrobe_providers.dart';

/// Compact summary of one suggested outfit.
class OutfitCard extends StatelessWidget {
  const OutfitCard({required this.saved, required this.rank, super.key});

  final SavedOutfit saved;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outfit = saved.outfit;
    final reasons = outfit.reasons
        .where((r) => r != ReasonCode.weatherNotConsidered)
        .take(3);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.outfit(saved.id)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Idea $rank', style: theme.textTheme.titleMedium),
                  const Spacer(),
                  Text(
                    '${(outfit.totalScore * 100).round()}% match',
                    style: theme.textTheme.labelLarge,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 96,
                child: Row(
                  children: [
                    for (final piece in outfit.pieces)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: PieceThumbnail(piece: piece),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              for (final r in reasons) ReasonLine(reason: r),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thumbnail and slot label of one outfit piece.
class PieceThumbnail extends ConsumerWidget {
  const PieceThumbnail({required this.piece, super.key});

  final OutfitPiece piece;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(clothingItemProvider(piece.itemId)).value;
    final label = item == null
        ? OutfitLabels.slot(piece.slot)
        : Labels.itemTitle(item);
    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: double.infinity,
              child: StoredImage(
                relativePath: item?.images?.thumbnail,
                cacheWidth: 240,
                semanticLabel: label,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

/// One explanation line with a positive or caveat icon.
class ReasonLine extends StatelessWidget {
  const ReasonLine({required this.reason, super.key});

  final ReasonCode reason;

  @override
  Widget build(BuildContext context) {
    final caveat = OutfitLabels.isCaveat(reason);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            caveat ? Icons.info_outline : Icons.check_circle_outline,
            size: 18,
            color: caveat ? scheme.tertiary : scheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(OutfitLabels.reason(reason))),
        ],
      ),
    );
  }
}
