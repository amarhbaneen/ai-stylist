import 'dart:io';

import 'package:ai_stylist/core/database/app_database.dart';
import 'package:ai_stylist/core/media/file_hasher.dart';
import 'package:ai_stylist/core/storage/file_store.dart';
import 'package:ai_stylist/features/favorites/data/drift_feedback_repository.dart';
import 'package:ai_stylist/features/favorites/data/drift_personalization_repository.dart';
import 'package:ai_stylist/features/profile/data/drift_profile_repository.dart';
import 'package:ai_stylist/features/stylist/data/drift_outfit_repository.dart';
import 'package:ai_stylist/features/wardrobe/data/drift_wardrobe_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outfit_engine/outfit_engine.dart';
import 'package:path/path.dart' as p;
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../support/fakes.dart';

/// Feedback, favourites, history and learning over the real database.
void main() {
  late Directory tmp;
  late AppDatabase db;
  late FixedClock clock;
  late DriftWardrobeRepository wardrobe;
  late DriftFeedbackRepository feedback;
  late DriftPersonalizationRepository personalization;
  late GenerateOutfits generate;
  late RecordFeedback record;
  var seed = 0;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('feedback_flow');
    db = AppDatabase(NativeDatabase.memory());
    clock = FixedClock();
    final ids = SequentialIds();
    wardrobe = DriftWardrobeRepository(
      database: db,
      files: LocalFileStore(Directory(p.join(tmp.path, 'store'))),
      images: FakeImageProcessor(),
      hasher: sha256OfFile,
      clock: clock,
      ids: ids,
    );
    feedback = DriftFeedbackRepository(database: db, clock: clock, ids: ids);
    personalization = DriftPersonalizationRepository(
      database: db,
      clock: clock,
    );
    generate = GenerateOutfits(
      wardrobe: wardrobe,
      profiles: DriftProfileRepository(database: db, clock: clock),
      outfits: DriftOutfitRepository(database: db, clock: clock, ids: ids),
      clock: clock,
      personalization: personalization,
      // Do not avoid recent outfits here: these tests isolate learning.
      historyWindow: Duration.zero,
    );
    record = RecordFeedback(
      feedback: feedback,
      personalization: personalization,
      wardrobe: wardrobe,
    );
  });

  tearDown(() async {
    await db.close();
    await tmp.delete(recursive: true);
  });

  Future<String> add(GarmentCategory category, ColorFamily color) async {
    final photo = await writePhoto(tmp, 'p${seed++}.jpg', seed: seed);
    final id = (await wardrobe.importImage(photo)).valueOrNull!.id;
    await wardrobe.saveAttributes(
      id,
      ClothingAttributes(category: category, primaryColor: color),
      activate: true,
    );
    return id;
  }

  Future<List<SavedOutfit>> suggest({int count = 2}) async {
    clock.now = clock.now.add(const Duration(minutes: 1));
    return (await generate(
      StylistQuery(occasion: Occasion.casual, count: count),
    )).valueOrNull!.outfits;
  }

  Future<void> later() async =>
      clock.now = clock.now.add(const Duration(minutes: 1));

  test('a like changes the next ranking; reset restores it', () async {
    final topA = await add(GarmentCategory.top, ColorFamily.white);
    final topB = await add(GarmentCategory.top, ColorFamily.white);
    await add(GarmentCategory.bottom, ColorFamily.black);
    await add(GarmentCategory.footwear, ColorFamily.black);

    final before = await suggest();
    final baselineTop = before.first.outfit.itemIds.contains(topA)
        ? topA
        : topB;
    final otherTop = baselineTop == topA ? topB : topA;
    final other = before.firstWhere((s) => s.outfit.itemIds.contains(otherTop));

    await later();
    final liked = await record(outfitId: other.id, kind: FeedbackKind.like);
    expect(liked.isSuccess, isTrue);

    final learned = (await personalization.load()).valueOrNull!;
    expect(learned.of('item:$otherTop'), closeTo(0.05, 1e-9));
    final after = await suggest();
    expect(after.first.outfit.itemIds, contains(otherTop));
    expect(after.first.outfit.reasons, contains(ReasonCode.learnedLike));

    await later();
    await ResetPersonalization(personalization, clock)();
    expect((await personalization.load()).valueOrNull!.weights, isEmpty);
    final reset = await suggest();
    expect(reset.first.outfit.itemIds, contains(baselineTop));

    // Feedback before the reset is ignored by later learning.
    await later();
    await Relearn(feedback, personalization, wardrobe)();
    expect((await personalization.load()).valueOrNull!.weights, isEmpty);
  });

  test('changing a like to a dislike counts only the latest opinion', () async {
    final top = await add(GarmentCategory.top, ColorFamily.white);
    await add(GarmentCategory.bottom, ColorFamily.black);
    await add(GarmentCategory.footwear, ColorFamily.black);
    final outfit = (await suggest(count: 1)).single;

    await later();
    await record(outfitId: outfit.id, kind: FeedbackKind.like);
    await later();
    await record(
      outfitId: outfit.id,
      kind: FeedbackKind.dislike,
      reason: FeedbackReason.notMyStyle,
      note: '  too plain  ',
    );

    final learned = (await personalization.load()).valueOrNull!;
    expect(learned.of('item:$top'), closeTo(-0.05, 1e-9));
    final entry = await feedback.watchEntry(outfit.id).first;
    expect(entry!.rating, FeedbackKind.dislike);
    expect(entry.latestFeedback!.reason, FeedbackReason.notMyStyle);
    expect(entry.latestFeedback!.note, 'too plain');

    await later();
    await record(outfitId: outfit.id, kind: FeedbackKind.cleared);
    expect((await personalization.load()).valueOrNull!.weights, isEmpty);
    expect((await feedback.watchEntry(outfit.id).first)!.rating, isNull);
  });

  test(
    'events in the same millisecond keep their order (frozen clock)',
    () async {
      await add(GarmentCategory.top, ColorFamily.white);
      await add(GarmentCategory.bottom, ColorFamily.black);
      await add(GarmentCategory.footwear, ColorFamily.black);
      final outfit = (await suggest(count: 1)).single;

      // No clock advance between these: they would tie without the guard.
      for (var i = 0; i < 5; i++) {
        await record(outfitId: outfit.id, kind: FeedbackKind.like);
        await record(outfitId: outfit.id, kind: FeedbackKind.cleared);
      }

      expect((await feedback.watchEntry(outfit.id).first)!.rating, isNull);
      expect((await personalization.load()).valueOrNull!.weights, isEmpty);
    },
  );

  test('favourites are separate from ratings and filter history', () async {
    await add(GarmentCategory.top, ColorFamily.white);
    await add(GarmentCategory.top, ColorFamily.grey);
    await add(GarmentCategory.bottom, ColorFamily.black);
    await add(GarmentCategory.footwear, ColorFamily.black);
    final outfits = await suggest();

    await feedback.setFavorite(outfits.last.id, favorite: true);

    final all = await feedback.watchHistory().first;
    final saved = await feedback.watchHistory(favoritesOnly: true).first;
    expect(all, hasLength(2));
    expect(saved.single.saved.id, outfits.last.id);
    expect(saved.single.saved.isFavorite, isTrue);
    expect(saved.single.rating, isNull, reason: 'saving is not liking');
    expect(
      (await personalization.load()).valueOrNull!.weights,
      isEmpty,
      reason: 'favourites do not train the model',
    );

    await feedback.setFavorite(outfits.last.id, favorite: false);
    expect(await feedback.watchHistory(favoritesOnly: true).first, isEmpty);
  });

  test('history re-emits when feedback is added', () async {
    await add(GarmentCategory.top, ColorFamily.white);
    await add(GarmentCategory.bottom, ColorFamily.black);
    await add(GarmentCategory.footwear, ColorFamily.black);
    final outfit = (await suggest(count: 1)).single;

    final ratings = feedback.watchHistory().map((list) => list.single.rating);
    final expectation = expectLater(
      ratings,
      emitsInOrder([null, FeedbackKind.like]),
    );
    await Future<void>.delayed(Duration.zero);
    await later();
    await record(outfitId: outfit.id, kind: FeedbackKind.like);
    await expectation;
  });

  test('feedback for an unknown outfit is NotFound', () async {
    final r = await record(outfitId: 'nope', kind: FeedbackKind.like);
    expect((r as Failure).failure, isA<NotFoundFailure>());
    expect(
      ((await feedback.setFavorite('nope', favorite: true)) as Failure).failure,
      isA<NotFoundFailure>(),
    );
  });

  test('explicit preferences are never changed by learning', () async {
    final profiles = DriftProfileRepository(database: db, clock: clock);
    final explicit = StyleProfile(favoredColors: {ColorFamily.green});
    await profiles.saveProfile(explicit);
    await add(GarmentCategory.top, ColorFamily.white);
    await add(GarmentCategory.bottom, ColorFamily.black);
    await add(GarmentCategory.footwear, ColorFamily.black);
    final outfit = (await suggest(count: 1)).single;

    await later();
    await record(outfitId: outfit.id, kind: FeedbackKind.dislike);
    await ResetPersonalization(personalization, clock)();

    expect((await profiles.getProfile()).valueOrNull, explicit);
  });
}
