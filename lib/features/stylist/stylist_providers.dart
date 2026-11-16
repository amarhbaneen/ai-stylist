import 'dart:isolate';

import 'package:outfit_engine/outfit_engine.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../core/providers.dart';
import '../profile/profile_providers.dart';
import '../wardrobe/wardrobe_providers.dart';
import 'data/drift_outfit_repository.dart';

part 'stylist_providers.g.dart';

@Riverpod(keepAlive: true)
OutfitRepository outfitRepository(Ref ref) => DriftOutfitRepository(
  database: ref.watch(appDatabaseProvider),
  clock: ref.watch(clockProvider),
  ids: ref.watch(idGeneratorProvider),
);

/// Runs the engine on a background isolate so generation never blocks the
/// UI thread, even for large wardrobes (REQUIREMENTS §9).
Future<GenerationResult> runEngineInIsolate(
  List<ClothingItem> wardrobe,
  OutfitRequest request,
  StyleProfile profile,
  LearnedPreferences learned,
) => Isolate.run(
  () => OutfitEngine().generate(
    wardrobe: wardrobe,
    request: request,
    profile: profile,
    learned: learned,
  ),
);

/// Overridden in widget tests, where isolates cannot run on the fake clock.
@Riverpod(keepAlive: true)
EngineRunner engineRunner(Ref ref) => runEngineInIsolate;

@riverpod
GenerateOutfits generateOutfits(Ref ref) => GenerateOutfits(
  wardrobe: ref.watch(wardrobeRepositoryProvider),
  profiles: ref.watch(profileRepositoryProvider),
  outfits: ref.watch(outfitRepositoryProvider),
  clock: ref.watch(clockProvider),
  runner: ref.watch(engineRunnerProvider),
);

/// One stored outfit, live.
@riverpod
Stream<SavedOutfit?> savedOutfit(Ref ref, String id) =>
    ref.watch(outfitRepositoryProvider).watchOutfit(id);
