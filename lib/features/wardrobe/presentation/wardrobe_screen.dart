import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../../app/routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/taxonomy_labels.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/item_thumbnail.dart';
import '../../../shared/widgets/motion.dart';
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
              AsyncError(:final error) => ErrorState(
                title: "Couldn't load your wardrobe",
                error: error,
                fallback:
                    'Your items are safe on this device. Try again, or '
                    'restart the app.',
                onRetry: () => ref.invalidate(wardrobeItemsProvider),
              ),
              _ => const _GridSkeleton(),
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
      padding: const EdgeInsets.symmetric(
        horizontal: Space.page,
        vertical: Space.sm,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(right: Space.sm),
          child: ChoiceChip(
            label: const Text('All'),
            selected: selected.isEmpty,
            onSelected: (_) => onAll(),
          ),
        ),
        for (final c in GarmentCategory.values)
          if (c != GarmentCategory.unknown)
            Padding(
              padding: const EdgeInsets.only(right: Space.sm),
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

/// Two-up grid of garments on the paper background: no card frames, the
/// photo carries the tile (DECISIONS D-42).
const _gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 220,
  mainAxisSpacing: Space.xl,
  crossAxisSpacing: Space.lg,
  childAspectRatio: 0.66,
);

const _gridPadding = EdgeInsets.fromLTRB(
  Space.page,
  Space.sm,
  Space.page,
  Space.xxxl * 2,
);

class _ItemGrid extends StatelessWidget {
  const _ItemGrid({required this.items});

  final List<ClothingItem> items;

  @override
  Widget build(BuildContext context) => GridView.builder(
    padding: _gridPadding,
    gridDelegate: _gridDelegate,
    itemCount: items.length,
    itemBuilder: (context, i) => FadeSlideIn(
      key: ValueKey(items[i].id),
      index: i,
      child: _ItemTile(item: items[i]),
    ),
  );
}

/// Placeholder tiles while the wardrobe loads.
class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) => GridView.builder(
    padding: _gridPadding,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: _gridDelegate,
    itemCount: 6,
    itemBuilder: (context, i) => const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Skeleton()),
        SizedBox(height: Space.sm),
        Skeleton(width: 96, height: 12),
        SizedBox(height: Space.xs),
        Skeleton(width: 56, height: 10),
      ],
    ),
  );
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item});

  final ClothingItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDraft = item.status == ItemStatus.draft;
    final title = Labels.itemTitle(item);
    final images = item.images;
    // Cut-outs and product photos sit on a backdrop like a shop photo; the
    // user's own photo fills the tile.
    final studio = images != null && images.shown != ItemView.photo;
    return InkWell(
      borderRadius: Radii.all,
      onTap: () => context.push(
        isDraft
            ? AppRoutes.editItem(item.id, confirm: true)
            : AppRoutes.item(item.id),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: Radii.all,
              child: ColoredBox(
                color: colors.surfaceContainerHigh,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: itemPhotoHeroTag(item.id),
                      child: Padding(
                        padding: EdgeInsets.all(studio ? Space.md : 0),
                        child: StoredImage(
                          relativePath: images?.displayThumbnail,
                          cacheWidth: 440,
                          fit: studio ? BoxFit.contain : BoxFit.cover,
                          cutoutShadow: images?.shown == ItemView.cutout,
                          semanticLabel: title,
                        ),
                      ),
                    ),
                    if (item.status != ItemStatus.active)
                      Positioned(
                        left: Space.sm,
                        top: Space.sm,
                        child: _StatusTag(
                          label: Labels.status(item.status),
                          emphasis: isDraft,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: Space.sm),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall,
          ),
          if (Labels.category(item.attributes.category) case final c
              when c != title)
            Text(
              c,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}

/// Small label on a tile: ink for "needs review", quiet for archived.
class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.label, required this.emphasis});

  final String label;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final background = emphasis ? colors.onSurface : colors.surface;
    final foreground = emphasis ? colors.surface : colors.onSurface;
    return DecoratedBox(
      decoration: BoxDecoration(color: background, borderRadius: Radii.all),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.sm,
          vertical: Space.xs,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium!.copyWith(color: foreground),
        ),
      ),
    );
  }
}
