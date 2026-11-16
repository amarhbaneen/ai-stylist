import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:outfit_engine/outfit_engine.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../../app/routes.dart';
import '../../../shared/outfit_labels.dart';
import '../../../shared/taxonomy_labels.dart';
import '../../../shared/widgets/empty_state.dart';
import 'outfit_card.dart';
import 'stylist_controller.dart';
import 'stylist_form.dart';

/// Choose an occasion (and optionally style and weather), then get up to
/// three outfits built only from ACTIVE wardrobe items (REQUIREMENTS §6.4).
class StylistScreen extends ConsumerStatefulWidget {
  const StylistScreen({super.key});

  @override
  ConsumerState<StylistScreen> createState() => _StylistScreenState();
}

class _StylistScreenState extends ConsumerState<StylistScreen> {
  final _form = StylistFormState();
  final _scroll = ScrollController();
  final _resultsKey = GlobalKey();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    await ref.read(stylistResultsProvider.notifier).generate(_form.toQuery());
    // Bring the results into view once they have been laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _resultsKey.currentContext;
      if (target != null && target.mounted) {
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 300),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(stylistResultsProvider);
    final loading = results is AsyncLoading;
    return Scaffold(
      appBar: AppBar(title: const Text('Stylist')),
      body: ListView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          StylistForm(state: _form, onChanged: () => setState(() {})),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: loading ? null : _generate,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Suggest outfits'),
          ),
          const SizedBox(height: 16),
          KeyedSubtree(
            key: _resultsKey,
            child: switch (results) {
              null => const SizedBox.shrink(),
              AsyncLoading() => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              AsyncError(:final error) => _Message(
                icon: Icons.error_outline,
                title: 'Could not make outfits',
                message: error is AppFailure
                    ? failureMessage(error)
                    : 'Please try again.',
              ),
              AsyncData(:final value) => _Results(
                outcome: value,
                occasion: _form.occasion,
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.outcome, required this.occasion});

  final GenerationOutcome outcome;
  final Occasion occasion;

  @override
  Widget build(BuildContext context) {
    if (outcome.outfits.isEmpty) {
      if (outcome.activeItemCount == 0) {
        return _Message(
          icon: Icons.checkroom_outlined,
          title: 'Your wardrobe is empty',
          message: 'Outfits are built only from clothes you add.',
          action: FilledButton.tonal(
            onPressed: () => context.go(AppRoutes.wardrobe),
            child: const Text('Go to Wardrobe'),
          ),
        );
      }
      // De-duplicate across templates; show each fix once.
      final fixes = {
        for (final m in outcome.missing) OutfitLabels.missing(m, occasion),
      };
      return _Message(
        icon: Icons.search_off,
        title: 'No complete outfit yet',
        message: [
          'To get outfits for this occasion, you could:',
          for (final f in fixes) '• $f',
        ].join('\n'),
        action: FilledButton.tonal(
          onPressed: () => context.go(AppRoutes.wardrobe),
          child: const Text('Go to Wardrobe'),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, saved) in outcome.outfits.indexed)
          OutfitCard(saved: saved, title: 'Idea ${i + 1}'),
        if (outcome.outfits.length < 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Only ${outcome.outfits.length} complete outfit'
              '${outcome.outfits.length == 1 ? '' : 's'} could be made from '
              'your wardrobe for this occasion.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 320,
    child: EmptyState(
      icon: icon,
      title: title,
      message: message,
      action: action,
    ),
  );
}
