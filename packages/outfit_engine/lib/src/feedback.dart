import 'package:meta/meta.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import 'history.dart';
import 'request.dart';

/// What the user said about an outfit (FR-08). Like/dislike is separate
/// from favourite: you can save an outfit without rating it.
enum FeedbackKind implements CodedEnum {
  like('LIKE'),
  dislike('DISLIKE'),

  /// The user removed an earlier like or dislike.
  cleared('CLEARED');

  const FeedbackKind(this.code);

  @override
  final String code;

  static FeedbackKind fromCode(String? code) =>
      enumFromCode(values, code, fallback: FeedbackKind.cleared);
}

/// Optional reason for a dislike. Each reason changes what is learned
/// (see [PreferenceLearner]), so the user's intent is respected: "worn
/// recently" is not a judgement on the clothes.
enum FeedbackReason implements CodedEnum {
  notMyStyle('NOT_MY_STYLE'),
  colorsClash('COLORS_CLASH'),
  tooFormal('TOO_FORMAL'),
  tooCasual('TOO_CASUAL'),
  wrongForWeather('WRONG_FOR_WEATHER'),
  wornRecently('WORN_RECENTLY'),
  other('OTHER');

  const FeedbackReason(this.code);

  @override
  final String code;

  static FeedbackReason? tryFromCode(String? code) {
    for (final r in values) {
      if (r.code == code) return r;
    }
    return null;
  }
}

/// One stored feedback event. Events are append-only; the latest event per
/// outfit is the current opinion.
@immutable
final class OutfitFeedback {
  const OutfitFeedback({
    required this.id,
    required this.outfitId,
    required this.kind,
    required this.createdAt,
    this.reason,
    this.note,
  });

  final String id;
  final String outfitId;
  final FeedbackKind kind;
  final FeedbackReason? reason;

  /// Optional free text, stored locally only.
  final String? note;

  /// UTC.
  final DateTime createdAt;
}

/// A feedback event together with the items of the outfit it is about —
/// the learner's input.
@immutable
final class FeedbackEvent {
  FeedbackEvent({required this.feedback, required List<String> itemIds})
    : itemIds = List.unmodifiable(itemIds);

  final OutfitFeedback feedback;
  final List<String> itemIds;
}

/// A history row: a stored outfit plus the user's current opinion of it.
@immutable
final class OutfitHistoryEntry {
  const OutfitHistoryEntry({required this.saved, this.latestFeedback});

  final SavedOutfit saved;

  /// `null` when never rated (or the last event cleared the rating).
  final OutfitFeedback? latestFeedback;

  FeedbackKind? get rating => switch (latestFeedback?.kind) {
    FeedbackKind.like => FeedbackKind.like,
    FeedbackKind.dislike => FeedbackKind.dislike,
    _ => null,
  };
}

/// Feedback, favourites and history (REQUIREMENTS §6.5).
abstract interface class FeedbackRepository {
  Future<Result<OutfitFeedback>> addFeedback({
    required String outfitId,
    required FeedbackKind kind,
    FeedbackReason? reason,
    String? note,
  });

  Future<Result<void>> setFavorite(String outfitId, {required bool favorite});

  /// Stored outfits, newest first; only favourites when [favoritesOnly].
  Stream<List<OutfitHistoryEntry>> watchHistory({bool favoritesOnly = false});

  Stream<OutfitHistoryEntry?> watchEntry(String outfitId);

  /// Feedback events (with their outfits' items) after [since], or all
  /// events when `null`. Used to recompute learned preferences.
  Future<Result<List<FeedbackEvent>>> feedbackSince(DateTime? since);
}

/// Learned preferences, kept apart from explicit ones (FR-08, D-11).
abstract interface class PersonalizationRepository {
  Future<Result<LearnedPreferences>> load();

  Stream<LearnedPreferences> watch();

  /// Replaces all learned weights with [learned].
  Future<Result<void>> replace(LearnedPreferences learned);

  /// Feedback before this instant is ignored by learning (set by reset).
  Future<Result<DateTime?>> resetAt();

  /// Clears learned weights and ignores all feedback up to [at]. Outfit
  /// history, favourites and explicit preferences are untouched.
  Future<Result<void>> reset(DateTime at);
}
