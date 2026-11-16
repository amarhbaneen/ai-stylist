import 'package:meta/meta.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import 'engine.dart';
import 'history.dart';
import 'outfit.dart';
import 'request.dart';

/// Runs the engine. The app passes a runner that moves the work onto a
/// background isolate; tests run it inline.
typedef EngineRunner = Future<GenerationResult> Function(
  List<ClothingItem> wardrobe,
  OutfitRequest request,
  StyleProfile profile,
  LearnedPreferences learned,
);

/// Runs [OutfitEngine] on the calling isolate.
Future<GenerationResult> runEngineInline(
  List<ClothingItem> wardrobe,
  OutfitRequest request,
  StyleProfile profile,
  LearnedPreferences learned,
) async => OutfitEngine().generate(
  wardrobe: wardrobe,
  request: request,
  profile: profile,
  learned: learned,
);

/// The user's choices on the Stylist screen (history is added here).
@immutable
final class StylistQuery {
  const StylistQuery({
    required this.occasion,
    this.customFormality,
    this.style,
    this.weather,
    this.count = 3,
  });

  final Occasion occasion;
  final Formality? customFormality;
  final StylePreference? style;
  final WeatherContext? weather;
  final int count;
}

@immutable
final class GenerationOutcome {
  GenerationOutcome({
    required List<SavedOutfit> outfits,
    required List<MissingRequirement> missing,
    required this.activeItemCount,
  }) : outfits = List.unmodifiable(outfits),
       missing = List.unmodifiable(missing);

  final List<SavedOutfit> outfits;
  final List<MissingRequirement> missing;

  /// So the UI can tell "empty wardrobe" from "nothing suitable".
  final int activeItemCount;
}

/// Loads ACTIVE items, preferences and recent history, generates outfits,
/// verifies every item reference and stores the result (REQUIREMENTS §6.4).
final class GenerateOutfits {
  const GenerateOutfits({
    required this._wardrobe,
    required this._profiles,
    required this._outfits,
    required this._clock,
    this._runner = runEngineInline,
    this._learned,
    this.historyWindow = const Duration(days: 7),
  });

  final WardrobeRepository _wardrobe;
  final ProfileRepository _profiles;
  final OutfitRepository _outfits;
  final Clock _clock;
  final EngineRunner _runner;
  final LearnedPreferences Function()? _learned;

  /// Suggestions in this window are avoided where possible.
  final Duration historyWindow;

  Future<Result<GenerationOutcome>> call(StylistQuery query) async {
    final items = await _wardrobe
        .watchItems(WardrobeFilter(statuses: {ItemStatus.active}))
        .first;

    // Preferences and history improve ranking but are never required.
    final profile =
        (await _profiles.getProfile()).valueOrNull ?? StyleProfile.empty;
    final history =
        (await _outfits.recentHistory(
          since: _clock.nowUtc().subtract(historyWindow),
        )).valueOrNull ??
        RecentHistory.empty;

    final request = OutfitRequest(
      occasion: query.occasion,
      customFormality: query.customFormality,
      style: query.style,
      weather: query.weather,
      count: query.count,
      excludedSignatures: history.signatures,
      recentItemUse: history.itemUse,
    );
    final result = await _runner(
      items,
      request,
      profile,
      _learned?.call() ?? LearnedPreferences.none,
    );

    // Defence in depth: never surface an outfit that references anything
    // but a real, ACTIVE item (CLAUDE.md rule 9).
    final activeIds = {for (final i in items) i.id};
    for (final o in result.outfits) {
      if (!activeIds.containsAll(o.itemIds)) {
        return const Failure(
          ValidationFailure('Generated outfit referenced an unknown item'),
        );
      }
    }

    if (result.outfits.isEmpty) {
      return Success(
        GenerationOutcome(
          outfits: const [],
          missing: result.missing,
          activeItemCount: items.length,
        ),
      );
    }
    final saved = await _outfits.saveGenerated(request, result.outfits);
    return switch (saved) {
      Failure(:final failure) => Failure(failure),
      Success(:final value) => Success(
        GenerationOutcome(
          outfits: value,
          missing: result.missing,
          activeItemCount: items.length,
        ),
      ),
    };
  }
}
