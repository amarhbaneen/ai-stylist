import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../core/providers.dart';
import 'data/drift_profile_repository.dart';

part 'profile_providers.g.dart';

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) => DriftProfileRepository(
  database: ref.watch(appDatabaseProvider),
  clock: ref.watch(clockProvider),
);

@riverpod
SaveStyleProfile saveStyleProfile(Ref ref) =>
    SaveStyleProfile(ref.watch(profileRepositoryProvider));

@riverpod
ResetStyleProfile resetStyleProfile(Ref ref) =>
    ResetStyleProfile(ref.watch(profileRepositoryProvider));

@riverpod
CompleteOnboarding completeOnboarding(Ref ref) =>
    CompleteOnboarding(ref.watch(profileRepositoryProvider));

/// The user's explicit preferences, live.
@riverpod
Stream<StyleProfile> styleProfile(Ref ref) =>
    ref.watch(profileRepositoryProvider).watchProfile();

/// Whether onboarding had been completed when the app launched. Read once
/// in bootstrap so the first screen is chosen without a loading flash.
@Riverpod(keepAlive: true)
bool onboardingCompleteAtLaunch(Ref ref) => throw UnimplementedError(
  'onboardingCompleteAtLaunchProvider must be overridden in bootstrap',
);
