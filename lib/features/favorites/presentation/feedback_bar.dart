import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:outfit_engine/outfit_engine.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../../shared/outfit_labels.dart';
import '../../../shared/taxonomy_labels.dart';
import '../favorites_providers.dart';

/// Like, dislike (with an optional reason) and save for one outfit
/// (REQUIREMENTS §6.5). Tapping an active rating clears it.
class FeedbackBar extends ConsumerWidget {
  const FeedbackBar({required this.outfitId, super.key});

  final String outfitId;

  void _snack(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _rate(
    BuildContext context,
    WidgetRef ref,
    FeedbackKind? current,
    FeedbackKind tapped,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    FeedbackReason? reason;
    String? note;
    var kind = tapped;
    if (current == tapped) {
      kind = FeedbackKind.cleared;
    } else if (tapped == FeedbackKind.dislike) {
      final answer = await showModalBottomSheet<(FeedbackReason?, String?)>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => const _DislikeSheet(),
      );
      if (answer == null) return; // dismissed: nothing recorded
      (reason, note) = answer;
    }
    final result = await ref
        .read(recordFeedbackProvider)
        .call(outfitId: outfitId, kind: kind, reason: reason, note: note);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(switch (result) {
            Failure(:final failure) => failureMessage(failure),
            Success() => switch (kind) {
              FeedbackKind.like => 'Liked. Future ideas will lean this way.',
              FeedbackKind.dislike =>
                reason == FeedbackReason.wornRecently
                    ? 'Noted. This won\'t change your style profile.'
                    : 'Thanks. Future ideas will avoid this.',
              FeedbackKind.cleared => 'Rating removed.',
            },
          }),
        ),
      );
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    WidgetRef ref, {
    required bool favorite,
  }) async {
    final result = await ref
        .read(setFavoriteProvider)
        .call(outfitId, favorite: favorite);
    if (!context.mounted) return;
    _snack(context, switch (result) {
      Failure(:final failure) => failureMessage(failure),
      Success() => favorite ? 'Saved to Favorites' : 'Removed from Favorites',
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(outfitEntryProvider(outfitId)).value;
    final rating = entry?.rating;
    final favorite = entry?.saved.isFavorite ?? false;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        IconButton(
          tooltip: rating == FeedbackKind.like ? 'Remove like' : 'Like',
          isSelected: rating == FeedbackKind.like,
          icon: const Icon(Icons.thumb_up_outlined),
          selectedIcon: Icon(Icons.thumb_up, color: scheme.primary),
          onPressed: entry == null
              ? null
              : () => _rate(context, ref, rating, FeedbackKind.like),
        ),
        IconButton(
          tooltip: rating == FeedbackKind.dislike
              ? 'Remove dislike'
              : 'Dislike',
          isSelected: rating == FeedbackKind.dislike,
          icon: const Icon(Icons.thumb_down_outlined),
          selectedIcon: Icon(Icons.thumb_down, color: scheme.error),
          onPressed: entry == null
              ? null
              : () => _rate(context, ref, rating, FeedbackKind.dislike),
        ),
        const Spacer(),
        IconButton(
          tooltip: favorite ? 'Remove from Favorites' : 'Save to Favorites',
          isSelected: favorite,
          icon: const Icon(Icons.favorite_border),
          selectedIcon: Icon(Icons.favorite, color: scheme.primary),
          onPressed: entry == null
              ? null
              : () => _toggleFavorite(context, ref, favorite: !favorite),
        ),
      ],
    );
  }
}

/// Optional reason and note for a dislike. Returns `(reason, note)`;
/// "Skip" returns `(null, null)`; dismissing returns `null` (cancel).
class _DislikeSheet extends StatefulWidget {
  const _DislikeSheet();

  @override
  State<_DislikeSheet> createState() => _DislikeSheetState();
}

class _DislikeSheetState extends State<_DislikeSheet> {
  FeedbackReason? _reason;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What didn\'t work? (optional)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final r in FeedbackReason.values)
                ChoiceChip(
                  label: Text(OutfitLabels.feedbackReason(r)),
                  selected: _reason == r,
                  onSelected: (on) => setState(() => _reason = on ? r : null),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            maxLength: 300,
            decoration: const InputDecoration(
              labelText: 'Note (stays on this device)',
              border: OutlineInputBorder(),
            ),
          ),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, (null, null)),
                child: const Text('Skip'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.pop(context, (_reason, _note.text)),
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
