import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:outfit_engine/outfit_engine.dart';

import '../../../app/routes.dart';
import '../../../shared/outfit_labels.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../stylist/presentation/outfit_card.dart';
import '../favorites_providers.dart';

enum _View { saved, history }

/// Saved outfits and the history of suggestions (REQUIREMENTS §6.5).
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  var _view = _View.saved;

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(
      outfitHistoryProvider(favoritesOnly: _view == _View.saved),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SegmentedButton<_View>(
              segments: const [
                ButtonSegment(
                  value: _View.saved,
                  icon: Icon(Icons.favorite_border),
                  label: Text('Saved'),
                ),
                ButtonSegment(
                  value: _View.history,
                  icon: Icon(Icons.history),
                  label: Text('History'),
                ),
              ],
              selected: {_view},
              onSelectionChanged: (v) => setState(() => _view = v.single),
            ),
          ),
          Expanded(
            child: switch (entries) {
              AsyncData(:final value) when value.isEmpty => _empty(context),
              AsyncData(:final value) => ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: value.length,
                itemBuilder: (context, i) => OutfitCard(
                  saved: value[i].saved,
                  title: _title(context, value[i].saved),
                ),
              ),
              AsyncError() => const EmptyState(
                icon: Icons.error_outline,
                title: 'Could not load your outfits',
                message: 'Please try again.',
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }

  String _title(BuildContext context, SavedOutfit saved) {
    final local = saved.createdAt.toLocal();
    final date = MaterialLocalizations.of(context).formatMediumDate(local);
    return '${OutfitLabels.occasion(saved.occasion)} · $date';
  }

  Widget _empty(BuildContext context) => switch (_view) {
    _View.saved => const EmptyState(
      icon: Icons.favorite_border,
      title: 'No favorites yet',
      message: 'Tap the heart on an outfit to save it here.',
    ),
    _View.history => EmptyState(
      icon: Icons.history,
      title: 'No outfits yet',
      message: 'Outfits you get from the Stylist appear here.',
      action: FilledButton.tonal(
        onPressed: () => context.go(AppRoutes.stylist),
        child: const Text('Go to Stylist'),
      ),
    ),
  };
}
