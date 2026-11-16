import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../../shared/taxonomy_labels.dart';
import '../../../shared/widgets/chip_selectors.dart';
import '../wardrobe_providers.dart';

/// Colour, season, formality and status filters (REQUIREMENTS §6.3).
class WardrobeFilterSheet extends ConsumerStatefulWidget {
  const WardrobeFilterSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const WardrobeFilterSheet(),
  );

  @override
  ConsumerState<WardrobeFilterSheet> createState() =>
      _WardrobeFilterSheetState();
}

class _WardrobeFilterSheetState extends ConsumerState<WardrobeFilterSheet> {
  late WardrobeFilter _filter = ref.read(wardrobeFilterControllerProvider);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scroll) => Column(
        children: [
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Text('Filters', style: Theme.of(context).textTheme.titleLarge),
                const FieldLabel('Show'),
                MultiChipSelector<ItemStatus>(
                  options: ItemStatus.values,
                  selected: _filter.statuses,
                  labelOf: Labels.status,
                  onChanged: (s) =>
                      setState(() => _filter = _filter.copyWith(statuses: s)),
                ),
                const FieldLabel('Colour'),
                MultiChipSelector<ColorFamily>(
                  options: ColorFamily.values,
                  selected: _filter.colors,
                  labelOf: Labels.color,
                  avatarOf: (c) => ColorDot(Labels.swatch(c)),
                  onChanged: (s) =>
                      setState(() => _filter = _filter.copyWith(colors: s)),
                ),
                const FieldLabel('Season'),
                MultiChipSelector<Season>(
                  options: Season.values,
                  selected: _filter.seasons,
                  labelOf: Labels.season,
                  onChanged: (s) =>
                      setState(() => _filter = _filter.copyWith(seasons: s)),
                ),
                const FieldLabel('Formality'),
                MultiChipSelector<Formality>(
                  options: Formality.values,
                  selected: _filter.formalities,
                  labelOf: Labels.formality,
                  onChanged: (s) => setState(
                    () => _filter = _filter.copyWith(formalities: s),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => setState(
                      () => _filter = WardrobeFilter(
                        categories: _filter.categories,
                        query: _filter.query,
                      ),
                    ),
                    child: const Text('Reset'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      ref
                          .read(wardrobeFilterControllerProvider.notifier)
                          .replace(_filter);
                      Navigator.pop(context);
                    },
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
