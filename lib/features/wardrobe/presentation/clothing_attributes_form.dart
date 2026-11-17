import 'package:material_ui/material_ui.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../../shared/taxonomy_labels.dart';
import '../../../shared/widgets/chip_selectors.dart';

/// Mutable editing state for [ClothingAttributes].
final class AttributesDraft {
  AttributesDraft.from(ClothingAttributes a)
    : category = a.category,
      subcategory = a.subcategory,
      primaryColor = a.primaryColor,
      secondaryColors = {...a.secondaryColors},
      pattern = a.pattern,
      seasons = {...a.seasons},
      formality = a.formality,
      fit = a.fit,
      warmth = a.warmth,
      name = TextEditingController(text: a.displayName),
      brand = TextEditingController(text: a.brand),
      notes = TextEditingController(text: a.notes);

  GarmentCategory category;
  GarmentSubcategory? subcategory;
  ColorFamily? primaryColor;
  Set<ColorFamily> secondaryColors;
  GarmentPattern pattern;
  Set<Season> seasons;
  Formality? formality;
  GarmentFit fit;
  Warmth? warmth;
  final TextEditingController name;
  final TextEditingController brand;
  final TextEditingController notes;

  /// Fields the user has changed by hand; suggestions never overwrite them.
  final Set<AnalyzedAttribute> touched = {};

  ClothingAttributes build() => ClothingAttributes(
    category: category,
    subcategory: subcategory,
    displayName: name.text,
    notes: notes.text,
    primaryColor: primaryColor,
    secondaryColors: secondaryColors,
    pattern: pattern,
    seasons: seasons,
    formality: formality,
    fit: fit,
    brand: brand.text,
    warmth: warmth,
  );

  void dispose() {
    name.dispose();
    brand.dispose();
    notes.dispose();
  }
}

/// Manual classification form. Every attribute is editable (CLAUDE.md #8);
/// only the category is required to add the item to the wardrobe.
class ClothingAttributesForm extends StatelessWidget {
  const ClothingAttributesForm({
    required this.draft,
    required this.onChanged,
    this.showCategoryError = false,
    this.categoryNote,
    this.subcategoryNote,
    this.patternNote,
    this.primaryColorNote,
    this.secondaryColorNote,
    super.key,
  });

  final AttributesDraft draft;

  /// Called after any chip change so the parent rebuilds.
  final VoidCallback onChanged;
  final bool showCategoryError;

  /// Optional AI explanations under "Category", "Type" and "Pattern".
  final Widget? categoryNote;
  final Widget? subcategoryNote;
  final Widget? patternNote;

  /// Optional AI explanation shown under "Main colour" (confidence, hints).
  final Widget? primaryColorNote;

  /// Optional AI hints shown under "Other colours".
  final Widget? secondaryColorNote;

  void _set(VoidCallback change) {
    change();
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final d = draft;
    final scheme = Theme.of(context).colorScheme;
    Widget dot(ColorFamily c) => ColorDot(Labels.swatch(c));
    final secondaryOptions = ColorFamily.values
        .where((c) => c != d.primaryColor)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('Category *'),
        ?categoryNote,
        SingleChipSelector<GarmentCategory>(
          options: GarmentCategory.values
              .where((c) => c != GarmentCategory.unknown)
              .toList(),
          selected: d.category == GarmentCategory.unknown ? null : d.category,
          labelOf: Labels.category,
          onChanged: (c) => _set(() {
            d.category = c ?? GarmentCategory.unknown;
            if (d.subcategory?.category != d.category) d.subcategory = null;
            d.touched.add(AnalyzedAttribute.category);
          }),
        ),
        if (showCategoryError)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Choose a category to add this item.',
              style: TextStyle(color: scheme.error),
            ),
          ),
        if (d.category != GarmentCategory.unknown) ...[
          const FieldLabel('Type'),
          ?subcategoryNote,
          SingleChipSelector<GarmentSubcategory>(
            options: GarmentSubcategory.of(d.category),
            selected: d.subcategory,
            labelOf: Labels.subcategory,
            onChanged: (s) => _set(() {
              d.subcategory = s;
              d.touched.add(AnalyzedAttribute.subcategory);
            }),
          ),
        ],
        const FieldLabel('Name (optional)'),
        TextField(
          controller: d.name,
          maxLength: ClothingAttributes.maxNameLength,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'e.g. Navy linen shirt',
            border: OutlineInputBorder(),
          ),
        ),
        const FieldLabel('Main colour'),
        ?primaryColorNote,
        SingleChipSelector<ColorFamily>(
          options: ColorFamily.values,
          selected: d.primaryColor,
          labelOf: Labels.color,
          avatarOf: dot,
          onChanged: (c) => _set(() {
            d.primaryColor = c;
            d.secondaryColors.remove(c);
            d.touched.add(AnalyzedAttribute.primaryColor);
          }),
        ),
        const FieldLabel('Other colours'),
        ?secondaryColorNote,
        MultiChipSelector<ColorFamily>(
          options: secondaryOptions,
          selected: d.secondaryColors,
          labelOf: Labels.color,
          avatarOf: dot,
          onChanged: (s) => _set(() {
            d.secondaryColors = s;
            d.touched.add(AnalyzedAttribute.secondaryColor);
          }),
        ),
        const FieldLabel('Pattern'),
        ?patternNote,
        SingleChipSelector<GarmentPattern>(
          options: GarmentPattern.values
              .where((p) => p != GarmentPattern.unknown)
              .toList(),
          selected: d.pattern == GarmentPattern.unknown ? null : d.pattern,
          labelOf: Labels.pattern,
          onChanged: (p) => _set(() {
            d.pattern = p ?? GarmentPattern.unknown;
            d.touched.add(AnalyzedAttribute.pattern);
          }),
        ),
        const FieldLabel('Seasons'),
        MultiChipSelector<Season>(
          options: Season.values,
          selected: d.seasons,
          labelOf: Labels.season,
          onChanged: (s) => _set(() => d.seasons = s),
        ),
        const FieldLabel('Formality'),
        SingleChipSelector<Formality>(
          options: Formality.values,
          selected: d.formality,
          labelOf: Labels.formality,
          onChanged: (f) => _set(() => d.formality = f),
        ),
        const FieldLabel('Warmth'),
        SingleChipSelector<Warmth>(
          options: Warmth.values,
          selected: d.warmth,
          labelOf: Labels.warmth,
          onChanged: (w) => _set(() => d.warmth = w),
        ),
        const FieldLabel('Fit'),
        SingleChipSelector<GarmentFit>(
          options: GarmentFit.values
              .where((f) => f != GarmentFit.unknown)
              .toList(),
          selected: d.fit == GarmentFit.unknown ? null : d.fit,
          labelOf: Labels.fit,
          onChanged: (f) => _set(() => d.fit = f ?? GarmentFit.unknown),
        ),
        const FieldLabel('Brand (optional)'),
        TextField(
          controller: d.brand,
          maxLength: ClothingAttributes.maxBrandLength,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const FieldLabel('Notes (optional)'),
        TextField(
          controller: d.notes,
          maxLength: ClothingAttributes.maxNotesLength,
          maxLines: 3,
          minLines: 2,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      ],
    );
  }
}
