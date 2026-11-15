import 'package:test/test.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

void main() {
  group('coded enums', () {
    test('codes are unique per enum', () {
      for (final values in <List<CodedEnum>>[
        ItemStatus.values,
        GarmentCategory.values,
        GarmentPattern.values,
        Season.values,
        GarmentFit.values,
      ]) {
        final codes = values.map((v) => v.code).toList();
        expect(codes.toSet().length, codes.length);
      }
    });

    test('round-trip every code', () {
      for (final v in GarmentCategory.values) {
        expect(GarmentCategory.fromCode(v.code), v);
      }
      for (final v in ItemStatus.values) {
        expect(ItemStatus.fromCode(v.code), v);
      }
    });

    test('unknown codes fall back safely', () {
      expect(GarmentCategory.fromCode('SPACESUIT'), GarmentCategory.unknown);
      expect(GarmentCategory.fromCode(null), GarmentCategory.unknown);
      expect(ItemStatus.fromCode('DELETED?'), ItemStatus.draft);
      expect(GarmentPattern.fromCode(''), GarmentPattern.unknown);
      expect(Season.tryFromCode('MONSOON'), isNull);
    });
  });

  group('formality', () {
    test('levels are 1..5 and ordered', () {
      expect(Formality.values.map((f) => f.level), [1, 2, 3, 4, 5]);
    });

    test('out-of-range level is null', () {
      expect(Formality.tryFromLevel(0), isNull);
      expect(Formality.tryFromLevel(6), isNull);
      expect(Formality.tryFromLevel(null), isNull);
      expect(Formality.tryFromLevel(4), Formality.business);
    });
  });

  group('time helpers', () {
    test('epoch millis round-trip in UTC', () {
      final t = DateTime.utc(2026, 11, 15, 12, 30, 1, 250);
      final back = fromEpochMillisUtc(toEpochMillisUtc(t));
      expect(back, t);
      expect(back.isUtc, isTrue);
    });
  });

  group('result', () {
    test('valueOrNull', () {
      expect(const Success(3).valueOrNull, 3);
      expect(const Failure<int>(NotFoundFailure('x')).valueOrNull, isNull);
    });
  });
}
