import 'package:outfit_engine/outfit_engine.dart';
import 'package:test/test.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import 'support.dart';

final _t0 = DateTime.utc(2026, 11, 16, 9);

FeedbackEvent _event(
  String id,
  String outfitId,
  List<String> items,
  FeedbackKind kind, {
  FeedbackReason? reason,
  int minute = 0,
}) => FeedbackEvent(
  feedback: OutfitFeedback(
    id: id,
    outfitId: outfitId,
    kind: kind,
    reason: reason,
    createdAt: _t0.add(Duration(minutes: minute)),
  ),
  itemIds: items,
);

const _learner = PreferenceLearner();
const _colors = {
  'a': ColorFamily.white,
  'b': ColorFamily.white,
  'x': ColorFamily.black,
  's': ColorFamily.black,
};

void main() {
  group('PreferenceLearner', () {
    test('a like raises items, colours and the pairing', () {
      final l = _learner.learn([
        _event('f1', 'o1', ['a', 'x', 's'], FeedbackKind.like),
      ], _colors);
      expect(l.of('item:a'), closeTo(0.05, 1e-9));
      expect(l.of('color:WHITE'), closeTo(0.03, 1e-9));
      expect(l.of('color:BLACK'), closeTo(0.03, 1e-9));
      expect(l.of(PreferenceLearner.pairKey('x', 'a')), closeTo(0.05, 1e-9));
      expect(l.of('item:b'), 0, reason: 'unrelated items untouched');
    });

    test('a plain dislike lowers them', () {
      final l = _learner.learn([
        _event('f1', 'o1', ['a', 'x', 's'], FeedbackKind.dislike),
      ], _colors);
      expect(l.of('item:a'), closeTo(-0.05, 1e-9));
      expect(l.of('color:WHITE'), closeTo(-0.03, 1e-9));
    });

    test('the reason shapes what is learned', () {
      final clash = _learner.learn([
        _event(
          'f1',
          'o1',
          ['a', 'x'],
          FeedbackKind.dislike,
          reason: FeedbackReason.colorsClash,
        ),
      ], _colors);
      expect(clash.of('color:WHITE'), closeTo(-0.03, 1e-9));
      expect(clash.of('item:a'), closeTo(-0.01, 1e-9));

      final context = _learner.learn([
        _event(
          'f1',
          'o1',
          ['a', 'x'],
          FeedbackKind.dislike,
          reason: FeedbackReason.tooFormal,
        ),
      ], _colors);
      expect(context.of('color:WHITE'), 0, reason: 'colours are fine');
      expect(context.of(PreferenceLearner.pairKey('a', 'x')), lessThan(0));

      final worn = _learner.learn([
        _event(
          'f1',
          'o1',
          ['a', 'x'],
          FeedbackKind.dislike,
          reason: FeedbackReason.wornRecently,
        ),
      ], _colors);
      expect(worn.weights, isEmpty, reason: 'not a judgement on taste');
    });

    test('only the latest opinion per outfit counts', () {
      final l = _learner.learn([
        _event('f1', 'o1', ['a'], FeedbackKind.like, minute: 1),
        _event('f2', 'o1', ['a'], FeedbackKind.dislike, minute: 2),
      ], _colors);
      expect(l.of('item:a'), closeTo(-0.05, 1e-9));

      final cleared = _learner.learn([
        _event('f1', 'o1', ['a'], FeedbackKind.like, minute: 1),
        _event('f2', 'o1', ['a'], FeedbackKind.cleared, minute: 2),
      ], _colors);
      expect(cleared.weights, isEmpty);
    });

    test('weights are bounded at ±0.30', () {
      final l = _learner.learn([
        for (var i = 0; i < 20; i++)
          _event('f$i', 'o$i', ['a', 'x'], FeedbackKind.like, minute: i),
      ], _colors);
      expect(l.of('item:a'), PreferenceLearner.maxWeight);
      for (final w in l.weights.values) {
        expect(w.abs(), lessThanOrEqualTo(PreferenceLearner.maxWeight));
      }
    });

    test('is deterministic regardless of input order', () {
      final events = [
        _event('f1', 'o1', ['a', 'x'], FeedbackKind.like, minute: 1),
        _event('f2', 'o2', ['b', 's'], FeedbackKind.dislike, minute: 2),
        _event('f3', 'o3', ['a', 's'], FeedbackKind.like, minute: 3),
      ];
      expect(
        _learner.learn(events, _colors).weights,
        _learner.learn(events.reversed, _colors).weights,
      );
    });

    test('unknown colours (deleted items) are skipped, not guessed', () {
      final l = _learner.learn([
        _event('f1', 'o1', ['gone', 'a'], FeedbackKind.like),
      ], _colors);
      expect(l.of('item:gone'), closeTo(0.05, 1e-9));
      expect(l.weights.keys.where((k) => k.startsWith('color:')), [
        'color:WHITE',
      ]);
    });
  });

  group('feedback changes ranking predictably', () {
    final wardrobe = [
      top('a', color: ColorFamily.white),
      top('b', color: ColorFamily.white),
      bottom('x', color: ColorFamily.black),
      shoes('s', color: ColorFamily.black),
    ];
    final engine = OutfitEngine();

    GenerationResult run(LearnedPreferences learned) => engine.generate(
      wardrobe: wardrobe,
      request: OutfitRequest(occasion: Occasion.casual, count: 2),
      learned: learned,
    );

    Outfit withTop(GenerationResult r, String id) =>
        r.outfits.firstWhere((o) => o.itemIds.contains(id));

    test('liking an outfit moves it to the top by a bounded amount', () {
      final baseline = run(LearnedPreferences.none);
      // Identical items: the tie is broken by signature, so 'a' wins.
      expect(baseline.outfits.first.itemIds, contains('a'));

      final learned = _learner.learn([
        _event('f1', 'o1', ['b', 'x', 's'], FeedbackKind.like),
      ], _colors);
      final after = run(learned);

      expect(after.outfits.first.itemIds, contains('b'));
      // Preference component (weight 0.15/0.85 without weather) rises by:
      // items +0.05, colours +0.03, pair +0.05 = 0.13.
      final w = 0.15 / 0.85;
      final delta =
          withTop(after, 'b').totalScore - withTop(baseline, 'b').totalScore;
      expect(delta, closeTo(0.13 * w, 1e-9));
    });

    test('disliking an outfit moves it down', () {
      final learned = _learner.learn([
        _event('f1', 'o1', ['a', 'x', 's'], FeedbackKind.dislike),
      ], _colors);
      expect(run(learned).outfits.first.itemIds, contains('b'));
    });

    test('no learned weights reproduces the baseline exactly (reset)', () {
      final baseline = run(LearnedPreferences.none);
      final reset = run(_learner.learn(const [], _colors));
      expect(
        reset.outfits.map((o) => (o.signature, o.totalScore)).toList(),
        baseline.outfits.map((o) => (o.signature, o.totalScore)).toList(),
      );
    });

    test('learned weights never break the 0..1 score range', () {
      final saturated = _learner.learn([
        for (var i = 0; i < 30; i++)
          _event('f$i', 'o$i', ['a', 'x', 's'], FeedbackKind.like, minute: i),
      ], _colors);
      for (final o in run(saturated).outfits) {
        expect(o.totalScore, inInclusiveRange(0, 1));
        expect(o.breakdown[ScoreComponent.preference], inInclusiveRange(0, 1));
        expect(o.reasons, contains(ReasonCode.learnedLike));
      }
    });
  });
}
