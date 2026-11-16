import 'package:test/test.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

final _t = DateTime.utc(2026, 11, 16);

ClothingItem _item(
  String id,
  ClothingAttributes attributes, {
  ItemStatus status = ItemStatus.active,
}) => ClothingItem(
  id: id,
  attributes: attributes,
  status: status,
  createdAt: _t,
  updatedAt: _t,
);

/// Minimal in-memory repository for use-case tests.
final class _FakeRepo implements WardrobeRepository {
  final items = <String, ClothingItem>{};
  ClothingAttributes? savedAttributes;
  bool? savedActivate;

  @override
  Future<Result<ClothingItem>> getItem(String id) async {
    final item = items[id];
    return item == null
        ? const Failure(NotFoundFailure('missing'))
        : Success(item);
  }

  @override
  Future<Result<ClothingItem>> saveAttributes(
    String id,
    ClothingAttributes attributes, {
    required bool activate,
  }) async {
    savedAttributes = attributes;
    savedActivate = activate;
    return Success(
      _item(
        id,
        attributes,
        status: activate ? ItemStatus.active : items[id]!.status,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ClothingAttributes', () {
    test('trims text and treats blank as null', () {
      final a = ClothingAttributes(displayName: '  Navy tee ', brand: '   ');
      expect(a.displayName, 'Navy tee');
      expect(a.brand, isNull);
    });

    test('secondary colours never repeat the primary', () {
      final a = ClothingAttributes(
        primaryColor: ColorFamily.navy,
        secondaryColors: {ColorFamily.navy, ColorFamily.white},
      );
      expect(a.secondaryColors, {ColorFamily.white});
    });

    test('activation requires a known category', () {
      expect(
        ClothingAttributes().validate(forActivation: true),
        isA<ValidationFailure>(),
      );
      expect(ClothingAttributes().validate(forActivation: false), isNull);
      expect(
        ClothingAttributes(category: GarmentCategory.top)
            .validate(forActivation: true),
        isNull,
      );
    });

    test('subcategory must belong to the category', () {
      final a = ClothingAttributes(
        category: GarmentCategory.top,
        subcategory: GarmentSubcategory.jeans,
      );
      expect(a.validate(forActivation: true), isA<ValidationFailure>());
    });

    test('rejects overlong text', () {
      final a = ClothingAttributes(
        category: GarmentCategory.top,
        displayName: 'x' * (ClothingAttributes.maxNameLength + 1),
      );
      expect(a.validate(forActivation: true), isA<ValidationFailure>());
    });

    test('value equality ignores set order', () {
      expect(
        ClothingAttributes(seasons: {Season.winter, Season.autumn}),
        ClothingAttributes(seasons: {Season.autumn, Season.winter}),
      );
    });
  });

  group('taxonomy', () {
    test('every category except unknown has subcategories', () {
      for (final c in GarmentCategory.values) {
        expect(
          GarmentSubcategory.of(c).isEmpty,
          c == GarmentCategory.unknown,
          reason: c.code,
        );
      }
    });

    test('subcategory and colour codes are unique', () {
      final sub = GarmentSubcategory.values.map((s) => s.code);
      expect(sub.toSet().length, sub.length);
      final col = ColorFamily.values.map((c) => c.code);
      expect(col.toSet().length, col.length);
    });
  });

  group('WardrobeFilter', () {
    final tee = _item(
      'tee',
      ClothingAttributes(
        category: GarmentCategory.top,
        displayName: 'Navy Tee',
        primaryColor: ColorFamily.navy,
        secondaryColors: {ColorFamily.white},
        seasons: {Season.summer},
        formality: Formality.casual,
        brand: 'Acme',
      ),
    );
    final draft = _item(
      'draft',
      ClothingAttributes(),
      status: ItemStatus.draft,
    );
    final archived = _item(
      'old',
      ClothingAttributes(category: GarmentCategory.footwear),
      status: ItemStatus.archived,
    );

    test('defaults show active and drafts, hide archived', () {
      final f = WardrobeFilter();
      expect([tee, draft, archived].where(f.matches), [tee, draft]);
    });

    test('colour matches primary or secondary', () {
      expect(WardrobeFilter(colors: {ColorFamily.white}).matches(tee), isTrue);
      expect(WardrobeFilter(colors: {ColorFamily.red}).matches(tee), isFalse);
    });

    test('formality filter excludes unknown formality', () {
      final f = WardrobeFilter(formalities: {Formality.casual});
      expect(f.matches(tee), isTrue);
      expect(f.matches(draft), isFalse);
    });

    test('search is case-insensitive over name, notes and brand', () {
      expect(WardrobeFilter(query: '  navy ').matches(tee), isTrue);
      expect(WardrobeFilter(query: 'ACME').matches(tee), isTrue);
      expect(WardrobeFilter(query: 'linen').matches(tee), isFalse);
    });

    test('season and category filters', () {
      expect(WardrobeFilter(seasons: {Season.winter}).matches(tee), isFalse);
      expect(
        WardrobeFilter(categories: {GarmentCategory.top}).matches(tee),
        isTrue,
      );
    });
  });

  group('SaveClothingItem', () {
    late _FakeRepo repo;
    late SaveClothingItem save;

    setUp(() {
      repo = _FakeRepo();
      save = SaveClothingItem(repo);
      repo.items['d'] = _item(
        'd',
        ClothingAttributes(),
        status: ItemStatus.draft,
      );
      repo.items['a'] = _item(
        'a',
        ClothingAttributes(category: GarmentCategory.top),
      );
    });

    test('a draft can be saved without a category if not confirmed', () async {
      final r = await save('d', ClothingAttributes(), confirm: false);
      expect(r.isSuccess, isTrue);
      expect(repo.savedActivate, isFalse);
    });

    test('confirming requires a category', () async {
      final r = await save('d', ClothingAttributes(), confirm: true);
      expect((r as Failure).failure, isA<ValidationFailure>());
      expect(repo.savedAttributes, isNull, reason: 'nothing persisted');
    });

    test('an active item cannot lose its category', () async {
      final r = await save('a', ClothingAttributes(), confirm: false);
      expect((r as Failure).failure, isA<ValidationFailure>());
    });

    test('confirming a valid draft activates it', () async {
      final r = await save(
        'd',
        ClothingAttributes(category: GarmentCategory.bottom),
        confirm: true,
      );
      expect(r.valueOrNull?.status, ItemStatus.active);
    });

    test('unknown item id is reported', () async {
      final r = await save('zzz', ClothingAttributes(), confirm: true);
      expect((r as Failure).failure, isA<NotFoundFailure>());
    });
  });

  group('StyleProfile', () {
    test('a colour cannot be both favoured and avoided', () {
      final p = StyleProfile(
        favoredColors: {ColorFamily.green},
        avoidedColors: {ColorFamily.green, ColorFamily.orange},
      );
      expect(p.avoidedColors, {ColorFamily.orange});
    });

    test('empty profile', () {
      expect(StyleProfile.empty.isEmpty, isTrue);
      expect(StyleProfile(fit: GarmentFit.slim).isEmpty, isFalse);
    });
  });
}
