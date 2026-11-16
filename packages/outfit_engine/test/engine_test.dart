import 'dart:math' as math;

import 'package:outfit_engine/outfit_engine.dart';
import 'package:test/test.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import 'support.dart';

final _engine = OutfitEngine();

GenerationResult _gen(
  List<ClothingItem> wardrobe, {
  Occasion occasion = Occasion.casual,
  WeatherContext? weather,
  int count = 3,
  Set<String> excluded = const {},
  Map<String, int> recent = const {},
  StyleProfile? profile,
  LearnedPreferences? learned,
  StylePreference? style,
  Formality? customFormality,
}) => _engine.generate(
  wardrobe: wardrobe,
  request: OutfitRequest(
    occasion: occasion,
    weather: weather,
    count: count,
    excludedSignatures: excluded,
    recentItemUse: recent,
    style: style,
    customFormality: customFormality,
  ),
  profile: profile,
  learned: learned,
);

void main() {
  group('hard constraints', () {
    test('only ACTIVE items are ever used', () {
      final wardrobe = [
        ...basicWardrobe(),
        item(
          'draft-top',
          GarmentCategory.top,
          color: ColorFamily.black,
          status: ItemStatus.draft,
        ),
        item(
          'old-shoe',
          GarmentCategory.footwear,
          color: ColorFamily.black,
          status: ItemStatus.archived,
        ),
      ];
      final result = _gen(wardrobe, count: 3);
      final used = result.outfits.expand((o) => o.itemIds).toSet();
      expect(used, isNot(contains('draft-top')));
      expect(used, isNot(contains('old-shoe')));
    });

    test('formality outside the occasion window is excluded', () {
      final wardrobe = [
        top('shirt', color: ColorFamily.white, f: Formality.business),
        bottom('trousers', color: ColorFamily.grey, f: Formality.business),
        shoes('sneakers', color: ColorFamily.white, f: Formality.casual),
        shoes('oxfords', color: ColorFamily.black, f: Formality.formal),
      ];
      final result = _gen(wardrobe, occasion: Occasion.business);
      expect(result.outfits, hasLength(1));
      expect(result.outfits.single.itemIds, contains('oxfords'));
    });

    test('unknown formality never disqualifies an item', () {
      final wardrobe = [top('t'), bottom('b'), shoes('s')];
      expect(_gen(wardrobe, occasion: Occasion.formal).outfits, hasLength(1));
    });

    test('cold weather requires a layer', () {
      final wardrobe = [
        ...basicWardrobe(),
        layer('coat', color: ColorFamily.black, w: Warmth.heavy),
      ];
      final result = _gen(
        wardrobe,
        weather: const WeatherContext(temperatureC: 4),
      );
      expect(result.outfits, isNotEmpty);
      for (final o in result.outfits) {
        expect(o.itemIds, contains('coat'));
      }
    });

    test('hot weather excludes heavy and winter-only items', () {
      final wardrobe = [
        top('wool', color: ColorFamily.grey, w: Warmth.heavy),
        item(
          'winter-tee',
          GarmentCategory.top,
          color: ColorFamily.white,
          seasons: {Season.winter},
        ),
        top('linen', color: ColorFamily.white, w: Warmth.light),
        bottom('shorts', color: ColorFamily.beige),
        shoes('sandals', color: ColorFamily.brown),
      ];
      final result = _gen(
        wardrobe,
        weather: const WeatherContext(temperatureC: 32),
      );
      final used = result.outfits.expand((o) => o.itemIds).toSet();
      expect(used, containsAll(['linen']));
      expect(used, isNot(contains('wool')));
      expect(used, isNot(contains('winter-tee')));
    });
  });

  group('results', () {
    test('returns fewer than three when fewer are valid, never padded', () {
      final wardrobe = [top('t'), bottom('b'), shoes('s')];
      final result = _gen(wardrobe, count: 3);
      expect(result.outfits, hasLength(1));
    });

    test('one-piece template works without tops or bottoms', () {
      final wardrobe = [
        item('dress', GarmentCategory.onePiece, color: ColorFamily.black),
        shoes('heels', color: ColorFamily.black),
      ];
      final result = _gen(wardrobe);
      expect(result.outfits.single.templateId, OutfitTemplate.onePiece.id);
      expect(result.outfits.single.itemIds, {'dress', 'heels'});
    });

    test('distinct signatures and varied picks', () {
      final result = _gen(basicWardrobe(), count: 3);
      final sigs = result.outfits.map((o) => o.signature).toSet();
      expect(sigs.length, result.outfits.length);
      expect(result.outfits, hasLength(3));
    });

    test('scores and breakdown are within 0..1; weights sum to 1', () {
      for (final o in _gen(basicWardrobe()).outfits) {
        expect(o.totalScore, inInclusiveRange(0, 1));
        for (final v in o.breakdown.values) {
          expect(v, inInclusiveRange(0, 1));
        }
        final sum = o.weights.values.fold<double>(0, (a, b) => a + b);
        expect(sum, closeTo(1, 1e-9));
      }
    });
  });

  group('missing categories', () {
    test('no footwear: explains what to add', () {
      final result = _gen([top('t'), bottom('b')]);
      expect(result.outfits, isEmpty);
      expect(
        result.missing,
        contains(
          const MissingRequirement(
            templateId: 'SEPARATES',
            category: GarmentCategory.footwear,
            reason: MissingReason.noItems,
          ),
        ),
      );
    });

    test('items exist but are too casual for the occasion', () {
      final result = _gen([
        top('t', f: Formality.casual),
        bottom('b', f: Formality.formal),
        shoes('s', f: Formality.formal),
      ], occasion: Occasion.formal);
      expect(result.outfits, isEmpty);
      expect(
        result.missing.map((m) => (m.category, m.reason)),
        contains((GarmentCategory.top, MissingReason.notSuitableForOccasion)),
      );
    });

    test('cold weather without any outerwear', () {
      final result = _gen(
        basicWardrobe(),
        weather: const WeatherContext(temperatureC: 2),
      );
      expect(result.outfits, isEmpty);
      expect(
        result.missing.map((m) => (m.category, m.reason)),
        contains((GarmentCategory.outerwear, MissingReason.noItems)),
      );
    });
  });

  group('scoring', () {
    test('missing weather is omitted, not penalised', () {
      final o = _gen(basicWardrobe()).outfits.first;
      expect(o.weatherConsidered, isFalse);
      expect(o.breakdown.containsKey(ScoreComponent.weather), isFalse);
      expect(o.weights.containsKey(ScoreComponent.weather), isFalse);
      expect(o.reasons, contains(ReasonCode.weatherNotConsidered));

      final w = _gen(
        basicWardrobe(),
        weather: const WeatherContext(temperatureC: 20),
      ).outfits.first;
      expect(w.weatherConsidered, isTrue);
      expect(w.breakdown.containsKey(ScoreComponent.weather), isTrue);
    });

    test('a neutral base outranks a colour clash', () {
      final result = _gen([
        top('t-red', color: ColorFamily.red),
        top('t-white', color: ColorFamily.white),
        // Red and yellow are 120° apart on the colour wheel: a clash.
        bottom('b-yellow', color: ColorFamily.yellow),
        shoes('s-grey', color: ColorFamily.grey),
      ], count: 2);
      expect(result.outfits.first.itemIds, contains('t-white'));
      final clash = result.outfits.firstWhere(
        (o) => o.itemIds.contains('t-red'),
      );
      expect(clash.reasons, contains(ReasonCode.colorClash));
      expect(
        result.outfits.first.breakdown[ScoreComponent.color]!,
        greaterThan(clash.breakdown[ScoreComponent.color]!),
      );
    });

    test('closer formality ranks higher for business', () {
      final result = _gen([
        top('smart', color: ColorFamily.white, f: Formality.smartCasual),
        top('shirt', color: ColorFamily.white, f: Formality.business),
        bottom('trousers', color: ColorFamily.grey, f: Formality.business),
        shoes('oxfords', color: ColorFamily.black, f: Formality.business),
      ], occasion: Occasion.business);
      expect(result.outfits.first.itemIds, contains('shirt'));
    });

    test('custom occasion uses the chosen formality', () {
      final wardrobe = [
        top('lounge', f: Formality.lounge),
        top('formal', f: Formality.formal),
        bottom('b'),
        shoes('s'),
      ];
      final result = _gen(
        wardrobe,
        occasion: Occasion.custom,
        customFormality: Formality.lounge,
      );
      final used = result.outfits.expand((o) => o.itemIds).toSet();
      expect(used, contains('lounge'));
      expect(used, isNot(contains('formal')));
    });

    test('favoured and avoided colours shift the ranking', () {
      final wardrobe = [
        top('t-blue', color: ColorFamily.blue),
        top('t-orange', color: ColorFamily.orange),
        bottom('b', color: ColorFamily.black),
        shoes('s', color: ColorFamily.black),
      ];
      final likesBlue = _gen(
        wardrobe,
        profile: StyleProfile(favoredColors: {ColorFamily.blue}),
      );
      expect(likesBlue.outfits.first.itemIds, contains('t-blue'));
      expect(
        likesBlue.outfits.first.reasons,
        contains(ReasonCode.favoredColor),
      );

      final avoidsBlue = _gen(
        wardrobe,
        profile: StyleProfile(avoidedColors: {ColorFamily.blue}),
      );
      expect(avoidsBlue.outfits.first.itemIds, contains('t-orange'));
    });

    test('learned likes nudge ranking', () {
      final wardrobe = [
        top('a', color: ColorFamily.white),
        top('b', color: ColorFamily.white),
        bottom('x', color: ColorFamily.black),
        shoes('s', color: ColorFamily.black),
      ];
      final base = _gen(wardrobe).outfits.first.itemIds;
      final other = base.contains('a') ? 'b' : 'a';
      final nudged = _gen(
        wardrobe,
        learned: LearnedPreferences({'item:$other': 0.3}),
      );
      expect(nudged.outfits.first.itemIds, contains(other));
      expect(nudged.outfits.first.reasons, contains(ReasonCode.learnedLike));
    });

    test('rain prefers boots over sandals', () {
      final result = _gen([
        top('t', color: ColorFamily.white),
        bottom('b', color: ColorFamily.navy),
        shoes('boots', color: ColorFamily.black, sub: GarmentSubcategory.boots),
        shoes(
          'sandals',
          color: ColorFamily.black,
          sub: GarmentSubcategory.sandals,
        ),
      ], weather: const WeatherContext(temperatureC: 19, precipitation: true));
      expect(result.outfits.first.itemIds, contains('boots'));
      expect(
        result.outfits.first.reasons,
        contains(ReasonCode.weatherRainFootwear),
      );
    });

    test('requested style changes the pick', () {
      final wardrobe = [
        item(
          'floral',
          GarmentCategory.top,
          color: ColorFamily.pink,
          pattern: GarmentPattern.floral,
        ),
        top('plain', color: ColorFamily.white),
        bottom('b', color: ColorFamily.beige),
        shoes('s', color: ColorFamily.brown),
      ];
      expect(
        _gen(wardrobe, style: StylePreference.minimal).outfits.first.itemIds,
        contains('plain'),
      );
      expect(
        _gen(wardrobe, style: StylePreference.bohemian).outfits.first.itemIds,
        contains('floral'),
      );
    });
  });

  group('history', () {
    test('recent combinations are skipped where possible', () {
      final first = _gen(basicWardrobe(), count: 1).outfits.single;
      final next = _gen(
        basicWardrobe(),
        count: 1,
        excluded: {first.signature},
      ).outfits.single;
      expect(next.signature, isNot(first.signature));
    });

    test('a recent combination is reused only when nothing else exists', () {
      final wardrobe = [top('t'), bottom('b'), shoes('s')];
      final only = _gen(wardrobe).outfits.single;
      final again = _gen(wardrobe, excluded: {only.signature}).outfits;
      expect(again.single.signature, only.signature);
      expect(again.single.reasons, contains(ReasonCode.recentlySuggested));
    });

    test('recently used items lower the variety score', () {
      final fresh = _gen(basicWardrobe(), count: 1).outfits.single;
      final reused = _gen(
        basicWardrobe(),
        count: 1,
        recent: {for (final id in fresh.itemIds) id: 3},
      ).outfits.single;
      expect(fresh.breakdown[ScoreComponent.variety], greaterThan(0.99));
      expect(reused.itemIds, isNot(equals(fresh.itemIds)));
    });
  });

  group('determinism', () {
    test('same input gives identical output, regardless of input order', () {
      final wardrobe = basicWardrobe();
      final a = _gen(wardrobe);
      final b = _gen(wardrobe.reversed.toList());
      expect(
        a.outfits.map((o) => (o.signature, o.totalScore)).toList(),
        b.outfits.map((o) => (o.signature, o.totalScore)).toList(),
      );
    });
  });

  group('property: random wardrobes never break the rules', () {
    final categories = [
      GarmentCategory.top,
      GarmentCategory.bottom,
      GarmentCategory.onePiece,
      GarmentCategory.outerwear,
      GarmentCategory.footwear,
      GarmentCategory.accessory,
      GarmentCategory.unknown,
    ];
    test('200 seeded wardrobes', () {
      for (var seed = 0; seed < 200; seed++) {
        final r = math.Random(seed);
        T pick<T>(List<T> l) => l[r.nextInt(l.length)];
        final wardrobe = [
          for (var i = 0; i < r.nextInt(25); i++)
            item(
              'i$seed-$i',
              pick(categories),
              color: r.nextBool() ? pick(ColorFamily.values) : null,
              formality: r.nextBool() ? pick(Formality.values) : null,
              warmth: r.nextBool() ? pick(Warmth.values) : null,
              pattern: pick(GarmentPattern.values),
              status: pick(ItemStatus.values),
            ),
        ];
        final occasion = pick(Occasion.values);
        final weather = r.nextBool()
            ? WeatherContext(temperatureC: r.nextDouble() * 45 - 5)
            : null;
        final count = 1 + r.nextInt(3);
        final result = _gen(
          wardrobe,
          occasion: occasion,
          weather: weather,
          count: count,
        );
        final active = {
          for (final i in wardrobe)
            if (i.status == ItemStatus.active) i.id: i,
        };
        final request = OutfitRequest(occasion: occasion, weather: weather);

        expect(result.outfits.length, lessThanOrEqualTo(count));
        expect(
          result.outfits.map((o) => o.signature).toSet().length,
          result.outfits.length,
          reason: 'seed $seed: duplicate outfit',
        );
        for (final o in result.outfits) {
          final template = OutfitTemplate.all.firstWhere(
            (t) => t.id == o.templateId,
          );
          final slots = o.pieces.map((p) => p.slot).toSet();
          expect(
            slots.containsAll(
              template.requiredFor(cold: weather?.isCold ?? false),
            ),
            isTrue,
            reason: 'seed $seed: required slot missing',
          );
          expect(slots.length, o.pieces.length, reason: 'seed $seed: dup slot');
          for (final p in o.pieces) {
            final it = active[p.itemId];
            expect(it, isNotNull, reason: 'seed $seed: non-active item');
            expect(
              HardConstraints.allows(it!, p.slot, request),
              isTrue,
              reason: 'seed $seed: hard constraint broken by ${p.itemId}',
            );
          }
        }
      }
    });
  });

  test('a 500-item wardrobe is generated quickly', () {
    final r = math.Random(7);
    final cats = [
      GarmentCategory.top,
      GarmentCategory.bottom,
      GarmentCategory.footwear,
      GarmentCategory.outerwear,
      GarmentCategory.onePiece,
    ];
    final wardrobe = [
      for (var i = 0; i < 500; i++)
        item(
          'w$i',
          cats[i % cats.length],
          color: ColorFamily.values[r.nextInt(ColorFamily.values.length)],
          formality: Formality.values[r.nextInt(Formality.values.length)],
          warmth: Warmth.values[r.nextInt(Warmth.values.length)],
        ),
    ];
    final watch = Stopwatch()..start();
    final result = _gen(
      wardrobe,
      occasion: Occasion.smartCasual,
      weather: const WeatherContext(temperatureC: 15),
    );
    watch.stop();
    // ignore: avoid_print
    print(
      '500 items: ${watch.elapsedMilliseconds} ms, '
      '${result.candidatesConsidered} candidates',
    );
    expect(result.outfits, hasLength(3));
    expect(watch.elapsedMilliseconds, lessThan(3000));
  });
}
