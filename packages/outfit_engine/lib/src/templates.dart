import 'package:meta/meta.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

/// A position in an outfit. Each slot accepts exactly one category.
enum Slot implements CodedEnum {
  top('TOP', GarmentCategory.top),
  bottom('BOTTOM', GarmentCategory.bottom),
  onePiece('ONE_PIECE', GarmentCategory.onePiece),
  outerwear('OUTERWEAR', GarmentCategory.outerwear),
  footwear('FOOTWEAR', GarmentCategory.footwear);

  const Slot(this.code, this.category);

  @override
  final String code;
  final GarmentCategory category;

  static Slot? tryFromCode(String code) {
    for (final s in values) {
      if (s.code == code) return s;
    }
    return null;
  }
}

/// A garment-based outfit structure (IMPLEMENTATION_PLAN §4). Templates are
/// data, not gender rules: anyone's wardrobe can fill any template.
@immutable
final class OutfitTemplate {
  const OutfitTemplate({
    required this.id,
    required this.required,
    this.optional = const {},
  });

  final String id;
  final Set<Slot> required;
  final Set<Slot> optional;

  /// Separates: top + bottom + footwear, optional layer.
  static const separates = OutfitTemplate(
    id: 'SEPARATES',
    required: {Slot.top, Slot.bottom, Slot.footwear},
    optional: {Slot.outerwear},
  );

  /// One-piece: dress/jumpsuit + footwear, optional layer.
  static const onePiece = OutfitTemplate(
    id: 'ONE_PIECE',
    required: {Slot.onePiece, Slot.footwear},
    optional: {Slot.outerwear},
  );

  /// All templates. Business and formal use the same structures with a
  /// higher formality window (applied as a hard constraint per item).
  static const all = [separates, onePiece];

  /// Required slots once weather is applied: in the cold, the optional
  /// layer becomes mandatory (the "cold-weather" template of FR-06).
  Set<Slot> requiredFor({required bool cold}) => cold
      ? {...required, ...optional.where((s) => s == Slot.outerwear)}
      : required;
}
