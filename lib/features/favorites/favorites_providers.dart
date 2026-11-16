import 'package:outfit_engine/outfit_engine.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/providers.dart';
import '../wardrobe/wardrobe_providers.dart';
import 'data/drift_feedback_repository.dart';
import 'data/drift_personalization_repository.dart';

part 'favorites_providers.g.dart';

@Riverpod(keepAlive: true)
FeedbackRepository feedbackRepository(Ref ref) => DriftFeedbackRepository(
  database: ref.watch(appDatabaseProvider),
  clock: ref.watch(clockProvider),
  ids: ref.watch(idGeneratorProvider),
);

@Riverpod(keepAlive: true)
PersonalizationRepository personalizationRepository(Ref ref) =>
    DriftPersonalizationRepository(
      database: ref.watch(appDatabaseProvider),
      clock: ref.watch(clockProvider),
    );

@riverpod
RecordFeedback recordFeedback(Ref ref) => RecordFeedback(
  feedback: ref.watch(feedbackRepositoryProvider),
  personalization: ref.watch(personalizationRepositoryProvider),
  wardrobe: ref.watch(wardrobeRepositoryProvider),
);

@riverpod
SetFavorite setFavorite(Ref ref) =>
    SetFavorite(ref.watch(feedbackRepositoryProvider));

@riverpod
ResetPersonalization resetPersonalization(Ref ref) => ResetPersonalization(
  ref.watch(personalizationRepositoryProvider),
  ref.watch(clockProvider),
);

/// Outfit history (newest first) or only favourites.
@riverpod
Stream<List<OutfitHistoryEntry>> outfitHistory(
  Ref ref, {
  required bool favoritesOnly,
}) => ref
    .watch(feedbackRepositoryProvider)
    .watchHistory(favoritesOnly: favoritesOnly);

/// One outfit with its current rating and favourite state.
@riverpod
Stream<OutfitHistoryEntry?> outfitEntry(Ref ref, String outfitId) =>
    ref.watch(feedbackRepositoryProvider).watchEntry(outfitId);

@riverpod
Stream<LearnedPreferences> learnedPreferences(Ref ref) =>
    ref.watch(personalizationRepositoryProvider).watch();
