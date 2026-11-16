import 'package:meta/meta.dart';

import '../core/set_equality.dart';
import '../taxonomy/taxonomy.dart';
import 'clothing_item.dart';

/// Criteria for browsing the wardrobe (REQUIREMENTS §6.3).
///
/// Empty sets mean "any". Deleted items are never returned.
@immutable
final class WardrobeFilter {
  WardrobeFilter({
    Set<ItemStatus> statuses = const {ItemStatus.active, ItemStatus.draft},
    Set<GarmentCategory> categories = const {},
    Set<ColorFamily> colors = const {},
    Set<Season> seasons = const {},
    Set<Formality> formalities = const {},
    String query = '',
  }) : statuses = Set.unmodifiable(statuses),
       categories = Set.unmodifiable(categories),
       colors = Set.unmodifiable(colors),
       seasons = Set.unmodifiable(seasons),
       formalities = Set.unmodifiable(formalities),
       query = query.trim().toLowerCase();

  final Set<ItemStatus> statuses;
  final Set<GarmentCategory> categories;

  /// Matches the primary or any secondary colour.
  final Set<ColorFamily> colors;

  /// Matches items tagged with any of these seasons.
  final Set<Season> seasons;
  final Set<Formality> formalities;

  /// Case-insensitive search over name, notes and brand.
  final String query;

  /// Number of active refinements beyond the default status set (for badges).
  int get refinementCount =>
      colors.length + seasons.length + formalities.length;

  /// Pure in-memory predicate. Repositories may push filters into SQL, but
  /// must return exactly the items this predicate accepts.
  bool matches(ClothingItem item) {
    final a = item.attributes;
    if (statuses.isNotEmpty && !statuses.contains(item.status)) return false;
    if (categories.isNotEmpty && !categories.contains(a.category)) {
      return false;
    }
    if (colors.isNotEmpty) {
      final itemColors = {?a.primaryColor, ...a.secondaryColors};
      if (!itemColors.any(colors.contains)) return false;
    }
    if (seasons.isNotEmpty && !a.seasons.any(seasons.contains)) return false;
    if (formalities.isNotEmpty &&
        (a.formality == null || !formalities.contains(a.formality))) {
      return false;
    }
    if (query.isNotEmpty) {
      final haystack = [
        a.displayName,
        a.notes,
        a.brand,
      ].whereType<String>().join('\n').toLowerCase();
      if (!haystack.contains(query)) return false;
    }
    return true;
  }

  WardrobeFilter copyWith({
    Set<ItemStatus>? statuses,
    Set<GarmentCategory>? categories,
    Set<ColorFamily>? colors,
    Set<Season>? seasons,
    Set<Formality>? formalities,
    String? query,
  }) => WardrobeFilter(
    statuses: statuses ?? this.statuses,
    categories: categories ?? this.categories,
    colors: colors ?? this.colors,
    seasons: seasons ?? this.seasons,
    formalities: formalities ?? this.formalities,
    query: query ?? this.query,
  );

  @override
  bool operator ==(Object other) =>
      other is WardrobeFilter &&
      setEquals(other.statuses, statuses) &&
      setEquals(other.categories, categories) &&
      setEquals(other.colors, colors) &&
      setEquals(other.seasons, seasons) &&
      setEquals(other.formalities, formalities) &&
      other.query == query;

  @override
  int get hashCode => Object.hash(
    setHash(statuses),
    setHash(categories),
    setHash(colors),
    setHash(seasons),
    setHash(formalities),
    query,
  );
}
