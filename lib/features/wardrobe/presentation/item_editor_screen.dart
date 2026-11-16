import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../../app/routes.dart';
import '../../../shared/taxonomy_labels.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/item_thumbnail.dart';
import '../wardrobe_providers.dart';
import 'clothing_attributes_form.dart';

/// Review a newly imported photo ([confirm] = true) or edit an existing item.
///
/// A new item becomes ACTIVE only when the user taps "Add to wardrobe"
/// (REQUIREMENTS §6.2.8). Leaving keeps it as "Needs review".
class ItemEditorScreen extends ConsumerStatefulWidget {
  const ItemEditorScreen({
    required this.itemId,
    required this.confirm,
    super.key,
  });

  final String itemId;
  final bool confirm;

  @override
  ConsumerState<ItemEditorScreen> createState() => _ItemEditorScreenState();
}

class _ItemEditorScreenState extends ConsumerState<ItemEditorScreen> {
  AttributesDraft? _draft;
  var _saving = false;
  var _showCategoryError = false;

  @override
  void dispose() {
    _draft?.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null) return;
    final attributes = draft.build();
    setState(() {
      _showCategoryError =
          widget.confirm && attributes.category == GarmentCategory.unknown;
      _saving = !_showCategoryError;
    });
    if (_showCategoryError) {
      // The inline error may be scrolled out of view; say it here too.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a category to add this item.')),
      );
      return;
    }

    final result = await ref
        .read(saveClothingItemProvider)
        .call(widget.itemId, attributes, confirm: widget.confirm);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Success(:final value):
        if (widget.confirm) {
          context.pushReplacement(AppRoutes.item(value.id));
        } else {
          context.pop();
        }
      case Failure(:final failure):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failureMessage(failure))));
    }
  }

  Future<void> _discard() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard this photo?'),
        content: const Text('It will be removed from the app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final result = await ref
        .read(deleteClothingItemProvider)
        .call(widget.itemId);
    if (!mounted) return;
    if (result case Failure(:final failure)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failureMessage(failure))));
      return;
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final item = ref.watch(clothingItemProvider(widget.itemId));
    final title = widget.confirm ? 'Review item' : 'Edit item';

    return switch (item) {
      AsyncData(value: final ClothingItem value) => _buildForm(title, value),
      AsyncData() => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const EmptyState(
          icon: Icons.search_off,
          title: 'Item not found',
          message: 'It may have been deleted.',
        ),
      ),
      AsyncError() => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const EmptyState(
          icon: Icons.error_outline,
          title: 'Could not open this item',
          message: 'Please go back and try again.',
        ),
      ),
      _ => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: CircularProgressIndicator()),
      ),
    };
  }

  Widget _buildForm(String title, ClothingItem item) {
    // Initialise once; later stream emissions must not clobber edits.
    final draft = _draft ??= AttributesDraft.from(item.attributes);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (item.status == ItemStatus.draft)
            IconButton(
              tooltip: 'Discard',
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : _discard,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: StoredImage(
                relativePath: item.images?.working,
                fit: BoxFit.contain,
                semanticLabel: 'Photo of the item',
              ),
            ),
          ),
          if (widget.confirm)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Describe this item. Only the category is required; you can '
                'change everything later.',
              ),
            ),
          ClothingAttributesForm(
            draft: draft,
            showCategoryError: _showCategoryError,
            onChanged: () => setState(() => _showCategoryError = false),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.confirm ? 'Add to wardrobe' : 'Save changes'),
          ),
        ),
      ),
    );
  }
}
