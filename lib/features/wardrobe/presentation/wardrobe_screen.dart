import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../../app/routes.dart';
import '../../../shared/taxonomy_labels.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/item_thumbnail.dart';
import '../wardrobe_providers.dart';
import 'add_clothing_flow.dart';
import 'wardrobe_filter_sheet.dart';

class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  var _searching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AddClothingFlow.recoverLostPick(context, ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(wardrobeFilterControllerProvider);
    final controller = ref.read(wardrobeFilterControllerProvider.notifier);
    final items = ref.watch(wardrobeItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search name, notes or brand',
                  border: InputBorder.none,
                ),
                onChanged: controller.setQuery,
              )
            : const Text('Wardrobe'),
        actions: [
          IconButton(
            tooltip: _searching ? 'Close search' : 'Search',
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () {
              if (_searching) controller.setQuery('');
              setState(() => _searching = !_searching);
            },
          ),
          IconButton(
            tooltip: 'Filters',
            icon: Badge(
              isLabelVisible:
                  filter.refinementCount > 0 ||
                  filter.statuses.contains(ItemStatus.archived),
              label: Text('${filter.refinementCount}'),
              child: const Icon(Icons.tune),
            ),
            onPressed: () => WardrobeFilterSheet.show(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddClothingFlow.start(context, ref),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Add'),
      ),
      body: Column(
        children: [
          _CategoryBar(
            selected: filter.categories,
            onToggle: controller.toggleCategory,
            onAll: controller.clearCategories,
          ),
          Expanded(
            child: switch (items) {
              AsyncData(:final value) when value.isEmpty =>
                filter == WardrobeFilter()
                    ? const EmptyState(
                        icon: Icons.checkroom_outlined,
                        title: 'Your wardrobe is empty',
                        message:
                            'Tap Add to photograph a garment or choose one '
                            'from your photos. Everything stays on this '
                            'device.',
                      )
                    : EmptyState(
                        icon: Icons.filter_alt_off_outlined,
                        title: 'No matching items',
                        message: 'Try removing some filters.',
                        action: TextButton(
                          onPressed: () => controller.replace(WardrobeFilter()),
                          child: const Text('Clear filters'),
                        ),
                      ),
              AsyncData(:final value) => _ItemGrid(items: value),
              AsyncError() => const EmptyState(
                icon: Icons.error_outline,
                title: 'Could not load your wardrobe',
                message: 'Please restart the app. Your items are safe.',
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.selected,
    required this.onToggle,
    required this.onAll,
  });

  final Set<GarmentCategory> selected;
  final ValueChanged<GarmentCategory> onToggle;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: const Text('All'),
            selected: selected.isEmpty,
            onSelected: (_) => onAll(),
          ),
        ),
        for (final c in GarmentCategory.values)
          if (c != GarmentCategory.unknown)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(Labels.category(c)),
                selected: selected.contains(c),
                onSelected: (_) => onToggle(c),
              ),
            ),
      ],
    ),
  );
}

class _ItemGrid extends StatelessWidget {
  const _ItemGrid({required this.items});

  final List<ClothingItem> items;

  @override
  Widget build(BuildContext context) => GridView.builder(
    padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 180,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.78,
    ),
    itemCount: items.length,
    itemBuilder: (context, i) => _ItemCard(item: items[i]),
  );
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item});

  final ClothingItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDraft = item.status == ItemStatus.draft;
    final title = Labels.itemTitle(item);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.push(
          isDraft
              ? AppRoutes.editItem(item.id, confirm: true)
              : AppRoutes.item(item.id),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  StoredImage(
                    relativePath: item.images?.displayThumbnail,
                    cacheWidth: 360,
                    semanticLabel: title,
                  ),
                  if (item.status != ItemStatus.active)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Chip(
                        label: Text(Labels.status(item.status)),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: isDraft
                            ? theme.colorScheme.tertiaryContainer
                            : theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
