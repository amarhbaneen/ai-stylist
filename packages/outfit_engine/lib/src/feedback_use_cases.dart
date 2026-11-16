import 'package:wardrobe_domain/wardrobe_domain.dart';

import 'feedback.dart';
import 'learner.dart';

/// Stores the user's like/dislike (or clears it) and recomputes learned
/// preferences by replaying the feedback log since the last reset.
///
/// Recomputing from the log, rather than nudging stored weights, keeps the
/// result deterministic and self-healing: the weights always equal
/// `learn(events since reset)`.
final class RecordFeedback {
  const RecordFeedback({
    required this._feedback,
    required this._personalization,
    required this._wardrobe,
    this._learner = const PreferenceLearner(),
  });

  final FeedbackRepository _feedback;
  final PersonalizationRepository _personalization;
  final WardrobeRepository _wardrobe;
  final PreferenceLearner _learner;

  Future<Result<OutfitFeedback>> call({
    required String outfitId,
    required FeedbackKind kind,
    FeedbackReason? reason,
    String? note,
  }) async {
    final saved = await _feedback.addFeedback(
      outfitId: outfitId,
      kind: kind,
      reason: kind == FeedbackKind.dislike ? reason : null,
      note: note,
    );
    if (saved case Failure(:final failure)) return Failure(failure);
    // The feedback itself is stored; if learning fails it is simply
    // recomputed on the next feedback, so the save still succeeds.
    await Relearn(_feedback, _personalization, _wardrobe, _learner)();
    return saved;
  }
}

/// Recomputes learned weights from the feedback log since the last reset.
final class Relearn {
  const Relearn(
    this._feedback,
    this._personalization,
    this._wardrobe, [
    this._learner = const PreferenceLearner(),
  ]);

  final FeedbackRepository _feedback;
  final PersonalizationRepository _personalization;
  final WardrobeRepository _wardrobe;
  final PreferenceLearner _learner;

  Future<Result<void>> call() async {
    final since = await _personalization.resetAt();
    if (since case Failure(:final failure)) return Failure(failure);
    final events = await _feedback.feedbackSince(since.valueOrNull);
    switch (events) {
      case Failure(:final failure):
        return Failure(failure);
      case Success(:final value):
        final ids = {for (final e in value) ...e.itemIds};
        final colors = <String, ColorFamily?>{};
        for (final id in ids) {
          // Deleted items keep their item/pair keys but have no colour.
          colors[id] = (await _wardrobe.getItem(id))
              .valueOrNull
              ?.attributes
              .primaryColor;
        }
        return _personalization.replace(_learner.learn(value, colors));
    }
  }
}

final class SetFavorite {
  const SetFavorite(this._feedback);

  final FeedbackRepository _feedback;

  Future<Result<void>> call(String outfitId, {required bool favorite}) =>
      _feedback.setFavorite(outfitId, favorite: favorite);
}

/// Forgets everything learned from feedback (FR-08 reset). History,
/// favourites and explicit preferences are kept.
final class ResetPersonalization {
  const ResetPersonalization(this._personalization, this._clock);

  final PersonalizationRepository _personalization;
  final Clock _clock;

  Future<Result<void>> call() => _personalization.reset(_clock.nowUtc());
}
