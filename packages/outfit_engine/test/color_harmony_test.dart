import 'package:outfit_engine/outfit_engine.dart';
import 'package:test/test.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

void main() {
  group('pairHarmony', () {
    test('neutrals go with anything', () {
      expect(pairHarmony(ColorFamily.navy, ColorFamily.orange), (
        1.0,
        ReasonCode.neutralBase,
      ));
    });

    test('same colour is monochrome', () {
      expect(
        pairHarmony(ColorFamily.green, ColorFamily.green).$2,
        ReasonCode.monochrome,
      );
    });

    test('analogous, complementary and clashing hues', () {
      expect(
        pairHarmony(ColorFamily.red, ColorFamily.orange).$2,
        ReasonCode.analogousColors,
      );
      expect(
        pairHarmony(ColorFamily.orange, ColorFamily.blue).$2,
        ReasonCode.complementaryColors,
      );
      expect(
        pairHarmony(ColorFamily.red, ColorFamily.green).$2,
        ReasonCode.complementaryColors,
      );
      expect(
        pairHarmony(ColorFamily.red, ColorFamily.purple).$2,
        ReasonCode.analogousColors,
      );
      expect(
        pairHarmony(ColorFamily.red, ColorFamily.yellow).$2,
        ReasonCode.colorClash,
      );
      expect(
        pairHarmony(ColorFamily.orange, ColorFamily.pink).$2,
        ReasonCode.colorClash,
      );
    });

    test('unknown colour is neutral-ish, not a clash', () {
      expect(pairHarmony(null, ColorFamily.red), (0.65, null));
    });

    test('multicolour pairs best with neutrals', () {
      expect(pairHarmony(ColorFamily.multicolor, ColorFamily.black).$1, 1.0);
      expect(
        pairHarmony(ColorFamily.multicolor, ColorFamily.red).$1,
        lessThan(0.6),
      );
    });

    test('is symmetric', () {
      for (final a in ColorFamily.values) {
        for (final b in ColorFamily.values) {
          expect(pairHarmony(a, b), pairHarmony(b, a), reason: '$a/$b');
        }
      }
    });
  });

  group('colorScore', () {
    test('three competing colours are penalised', () {
      final (two, _) = colorScore([ColorFamily.red, ColorFamily.orange]);
      final (three, reasons) = colorScore([
        ColorFamily.red,
        ColorFamily.orange,
        ColorFamily.yellow,
      ]);
      expect(three, lessThan(two));
      expect(reasons, contains(ReasonCode.colorClash));
    });

    test('a clash suppresses positive labels', () {
      final (_, reasons) = colorScore([
        ColorFamily.red,
        ColorFamily.green,
        ColorFamily.orange,
      ]);
      expect(reasons, isNot(contains(ReasonCode.analogousColors)));
    });

    test('scores stay within 0..1', () {
      for (final a in ColorFamily.values) {
        for (final b in ColorFamily.values) {
          final (s, _) = colorScore([a, b, ColorFamily.multicolor]);
          expect(s, inInclusiveRange(0, 1));
        }
      }
    });
  });
}
