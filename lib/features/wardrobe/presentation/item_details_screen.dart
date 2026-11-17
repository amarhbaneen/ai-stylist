import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../../app/routes.dart';
import '../../../shared/taxonomy_labels.dart';
import '../../../shared/widgets/empty_state.dart';
import '../wardrobe_providers.dart';
import 'item_photo.dart';

/// Read-only view of an item with edit, archive/restore and delete.
class ItemDetailsScreen extends ConsumerWidget {
  const ItemDetailsScreen({required this.itemId, super.key});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(clothingItemProvider(itemId));
    return switch (item) {
      AsyncData(value: final ClothingItem value) => _Details(item: value),
      AsyncData() => const _Message(
        icon: Icons.search_off,
        title: 'Item not found',
        message: 'It may have been deleted.',
      ),
      AsyncError() => const _Message(
        icon: Icons.error_outline,
        title: 'Could not open this item',
        message: 'Please go back and try again.',
      ),
      _ => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: EmptyState(icon: icon, title: title, message: message),
  );
}

enum _MenuAction { archive, restore, delete }

class _Details extends ConsumerWidget {
  const _Details({required this.item});

  final ClothingItem item;

  void _snack(BuildContext context, String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _onMenu(
    BuildContext context,
    WidgetRef ref,
    _MenuAction action,
  ) async {
    switch (action) {
      case _MenuAction.archive:
        final r = await ref.read(archiveClothingItemProvider).call(item.id);
        if (!context.mounted) return;
        _snack(context, switch (r) {
          Success() => 'Archived. It will not be used in new outfits.',
          Failure(:final failure) => failureMessage(failure),
        });
      case _MenuAction.restore:
        final r = await ref.read(restoreClothingItemProvider).call(item.id);
        if (!context.mounted) return;
        _snack(context, switch (r) {
          Success() => 'Restored to your wardrobe.',
          Failure(:final failure) => failureMessage(failure),
        });
      case _MenuAction.delete:
        await _confirmDelete(context, ref);
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this item?'),
        content: const Text(
          'Its photo and details will be removed from this device. '
          'This cannot be undone. To keep it but stop using it in outfits, '
          'archive it instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    // Capture these first: once the item is deleted its live query emits
    // null and this widget is replaced, so `context` is no longer mounted.
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final r = await ref.read(deleteClothingItemProvider).call(item.id);
    switch (r) {
      case Success():
        router.pop();
        messenger.showSnackBar(const SnackBar(content: Text('Item deleted.')));
      case Failure(:final failure):
        messenger.showSnackBar(
          SnackBar(content: Text(failureMessage(failure))),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = item.attributes;
    final title = Labels.itemTitle(item);
    final rows = <(String, String?)>[
      ('Category', Labels.category(a.category)),
      (
        'Type',
        a.subcategory == null ? null : Labels.subcategory(a.subcategory!),
      ),
      (
        'Main colour',
        a.primaryColor == null ? null : Labels.color(a.primaryColor!),
      ),
      (
        'Other colours',
        a.secondaryColors.isEmpty
            ? null
            : a.secondaryColors.map(Labels.color).join(', '),
      ),
      (
        'Pattern',
        a.pattern == GarmentPattern.unknown ? null : Labels.pattern(a.pattern),
      ),
      (
        'Seasons',
        a.seasons.isEmpty
            ? null
            : Season.values
                  .where(a.seasons.contains)
                  .map(Labels.season)
                  .join(', '),
      ),
      (
        'Formality',
        a.formality == null ? null : Labels.formality(a.formality!),
      ),
      ('Warmth', a.warmth == null ? null : Labels.warmth(a.warmth!)),
      ('Fit', a.fit == GarmentFit.unknown ? null : Labels.fit(a.fit)),
      ('Brand', a.brand),
      ('Notes', a.notes),
      ('Status', Labels.status(item.status)),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(AppRoutes.editItem(item.id)),
          ),
          PopupMenuButton<_MenuAction>(
            onSelected: (a) => _onMenu(context, ref, a),
            itemBuilder: (context) => [
              if (item.status == ItemStatus.active)
                const PopupMenuItem(
                  value: _MenuAction.archive,
                  child: Text('Archive'),
                ),
              if (item.status == ItemStatus.archived)
                const PopupMenuItem(
                  value: _MenuAction.restore,
                  child: Text('Restore'),
                ),
              const PopupMenuItem(
                value: _MenuAction.delete,
                child: Text('Delete'),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ItemPhoto(item: item, semanticLabel: title),
          const SizedBox(height: 8),
          for (final (label, value) in rows)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(label),
              subtitle: Text(value ?? 'Not set'),
            ),
        ],
      ),
    );
  }
}
