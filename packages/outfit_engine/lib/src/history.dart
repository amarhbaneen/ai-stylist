import 'package:meta/meta.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import 'outfit.dart';
import 'request.dart';

/// An outfit that was shown to the user and stored in history.
@immutable
final class SavedOutfit {
  const SavedOutfit({
    required this.id,
    required this.occasion,
    required this.outfit,
    required this.createdAt,
    this.isFavorite = false,
  });

  final String id;
  final Occasion occasion;
  final Outfit outfit;

  /// UTC.
  final DateTime createdAt;
  final bool isFavorite;
}

/// What recent history the engine needs for variety (FR-06).
@immutable
final class RecentHistory {
  RecentHistory({
    Set<String> signatures = const {},
    Map<String, int> itemUse = const {},
  }) : signatures = Set.unmodifiable(signatures),
       itemUse = Map.unmodifiable(itemUse);

  static final empty = RecentHistory();

  final Set<String> signatures;
  final Map<String, int> itemUse;
}

/// Persistence for generated outfits (REQUIREMENTS §12). Feedback and
/// favourites are added in M6.
abstract interface class OutfitRepository {
  /// Stores [outfits] as one generation and returns them with IDs.
  Future<Result<List<SavedOutfit>>> saveGenerated(
    OutfitRequest request,
    List<Outfit> outfits,
  );

  /// Signatures and item usage of outfits suggested since [since].
  Future<Result<RecentHistory>> recentHistory({required DateTime since});

  /// Live single outfit; `null` if it does not exist.
  Stream<SavedOutfit?> watchOutfit(String id);
}
