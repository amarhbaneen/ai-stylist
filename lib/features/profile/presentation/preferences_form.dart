import 'package:material_ui/material_ui.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../../shared/taxonomy_labels.dart';
import '../../../shared/widgets/chip_selectors.dart';

/// Controlled editor for explicit style preferences. Every field is optional.
class PreferencesForm extends StatelessWidget {
  const PreferencesForm({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final StyleProfile value;
  final ValueChanged<StyleProfile> onChanged;

  StyleProfile _copy({
    Set<StylePreference>? styles,
    Set<ColorFamily>? favored,
    Set<ColorFamily>? avoided,
    GarmentFit? Function()? fit,
    Formality? Function()? formality,
  }) => StyleProfile(
    preferredStyles: styles ?? value.preferredStyles,
    favoredColors: favored ?? value.favoredColors,
    // Choosing a colour as favoured removes it from avoided, and vice versa.
    avoidedColors: (avoided ?? value.avoidedColors).difference(
      favored ?? const {},
    ),
    fit: fit == null ? value.fit : fit(),
    formality: formality == null ? value.formality : formality(),
  );

  @override
  Widget build(BuildContext context) {
    Widget dot(ColorFamily c) => ColorDot(Labels.swatch(c));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('Styles you like'),
        MultiChipSelector<StylePreference>(
          options: StylePreference.values,
          selected: value.preferredStyles,
          labelOf: Labels.style,
          onChanged: (s) => onChanged(_copy(styles: s)),
        ),
        const FieldLabel('Colours to favour'),
        MultiChipSelector<ColorFamily>(
          options: ColorFamily.values,
          selected: value.favoredColors,
          labelOf: Labels.color,
          avatarOf: dot,
          onChanged: (s) => onChanged(_copy(favored: s)),
        ),
        const FieldLabel('Colours to avoid'),
        MultiChipSelector<ColorFamily>(
          options: ColorFamily.values,
          selected: value.avoidedColors,
          labelOf: Labels.color,
          avatarOf: dot,
          onChanged: (s) => onChanged(
            StyleProfile(
              preferredStyles: value.preferredStyles,
              favoredColors: value.favoredColors.difference(s),
              avoidedColors: s,
              fit: value.fit,
              formality: value.formality,
            ),
          ),
        ),
        const FieldLabel('Preferred fit'),
        SingleChipSelector<GarmentFit>(
          options: GarmentFit.values
              .where((f) => f != GarmentFit.unknown)
              .toList(),
          selected: value.fit,
          labelOf: Labels.fit,
          onChanged: (f) => onChanged(_copy(fit: () => f)),
        ),
        const FieldLabel('Usual formality'),
        SingleChipSelector<Formality>(
          options: Formality.values,
          selected: value.formality,
          labelOf: Labels.formality,
          onChanged: (f) => onChanged(_copy(formality: () => f)),
        ),
      ],
    );
  }
}
