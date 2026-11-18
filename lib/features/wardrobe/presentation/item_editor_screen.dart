import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../../app/routes.dart';
import '../../../shared/taxonomy_labels.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../clothing_analysis/analysis_providers.dart';
import '../../clothing_analysis/presentation/apply_suggestions.dart';
import '../../clothing_analysis/presentation/attribute_suggestion_note.dart';
import '../../clothing_analysis/presentation/color_suggestion_notes.dart';
import '../wardrobe_providers.dart';
import 'clothing_attributes_form.dart';
import 'item_photo.dart';

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

  /// Suggestions are applied once, when both the form and the analysis are
  /// ready; later changes are entirely the user's.
  var _suggestionsApplied = false;

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
        // Record which suggestions were kept (provenance, FR-04). Best
        // effort: the item itself is already saved.
        await ref
            .read(confirmAnalysisProvider)
            .call(widget.itemId, value.attributes);
        if (!mounted) return;
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
        body: const LoadingState(),
      ),
    };
  }

  Widget _buildForm(String title, ClothingItem item) {
    // Initialise once; later stream emissions must not clobber edits.
    final draft = _draft ??= AttributesDraft.from(item.attributes);

    // On-device analysis only for items still under review (new photos).
    final analyse = item.status == ItemStatus.draft;
    final analysis = analyse
        ? ref.watch(clothingAnalysisProvider(item.id))
        : null;
    final policy = ref.watch(confidencePolicyProvider);
    if (analysis case AsyncData(:final value) when !_suggestionsApplied) {
      // Mutating the local draft before it is rendered keeps this frame
      // consistent; no setState needed.
      applySuggestions(draft, value, policy);
      _suggestionsApplied = true;
    }
    void pickPrimary(ColorFamily c) => setState(() {
      draft.primaryColor = c;
      draft.secondaryColors.remove(c);
      draft.touched.add(AnalyzedAttribute.primaryColor);
    });
    void addSecondary(ColorFamily c) => setState(() {
      draft.secondaryColors = {...draft.secondaryColors, c};
      draft.touched.add(AnalyzedAttribute.secondaryColor);
    });
    final suggested = switch (analysis) {
      AsyncData(:final value) => value,
      _ => null,
    };
    // A type suggestion only makes sense for the category in the form.
    final typeSuggestion = suggested?.subcategory;
    final typeFits = typeSuggestion?.value.category == draft.category;

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
          ItemPhoto(item: item, semanticLabel: 'Photo of the item'),
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
            categoryNote: suggested == null
                ? null
                : AttributeSuggestionNote<GarmentCategory>(
                    suggestion: suggested.category,
                    policy: policy,
                    current: draft.category,
                    labelOf: Labels.category,
                    noun: 'category',
                    onPick: (c) => setState(() {
                      draft.category = c;
                      if (draft.subcategory?.category != c) {
                        draft.subcategory = null;
                      }
                      draft.touched.add(AnalyzedAttribute.category);
                      _showCategoryError = false;
                    }),
                  ),
            subcategoryNote: !typeFits
                ? null
                : AttributeSuggestionNote<GarmentSubcategory>(
                    suggestion: typeSuggestion,
                    policy: policy,
                    current: draft.subcategory,
                    labelOf: Labels.subcategory,
                    noun: 'type',
                    onPick: (s) => setState(() {
                      draft.subcategory = s;
                      draft.touched.add(AnalyzedAttribute.subcategory);
                    }),
                  ),
            patternNote: suggested == null
                ? null
                : AttributeSuggestionNote<GarmentPattern>(
                    suggestion: suggested.pattern,
                    policy: policy,
                    current: draft.pattern,
                    labelOf: Labels.pattern,
                    noun: 'pattern',
                    onPick: (p) => setState(() {
                      draft.pattern = p;
                      draft.touched.add(AnalyzedAttribute.pattern);
                    }),
                  ),
            primaryColorNote: analysis == null
                ? null
                : PrimaryColorNote(
                    analysis: analysis,
                    policy: policy,
                    current: draft.primaryColor,
                    onPick: pickPrimary,
                  ),
            secondaryColorNote: switch (analysis) {
              AsyncData(:final value) => SecondaryColorNote(
                suggestions: value.secondaryColors,
                primary: draft.primaryColor,
                selected: draft.secondaryColors,
                onAdd: addSecondary,
              ),
              _ => null,
            },
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
