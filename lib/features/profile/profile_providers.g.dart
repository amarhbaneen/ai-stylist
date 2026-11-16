// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(profileRepository)
final profileRepositoryProvider = ProfileRepositoryProvider._();

final class ProfileRepositoryProvider
    extends
        $FunctionalProvider<
          ProfileRepository,
          ProfileRepository,
          ProfileRepository
        >
    with $Provider<ProfileRepository> {
  ProfileRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProfileRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProfileRepository create(Ref ref) {
    return profileRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileRepository>(value),
    );
  }
}

String _$profileRepositoryHash() => r'0edde2ba92cc7433eb4d81fbc65c76bc1c02b7a0';

@ProviderFor(saveStyleProfile)
final saveStyleProfileProvider = SaveStyleProfileProvider._();

final class SaveStyleProfileProvider
    extends
        $FunctionalProvider<
          SaveStyleProfile,
          SaveStyleProfile,
          SaveStyleProfile
        >
    with $Provider<SaveStyleProfile> {
  SaveStyleProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'saveStyleProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$saveStyleProfileHash();

  @$internal
  @override
  $ProviderElement<SaveStyleProfile> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SaveStyleProfile create(Ref ref) {
    return saveStyleProfile(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SaveStyleProfile value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SaveStyleProfile>(value),
    );
  }
}

String _$saveStyleProfileHash() => r'48107bf6c35996c635b3dc7c7ef97c952ab61958';

@ProviderFor(resetStyleProfile)
final resetStyleProfileProvider = ResetStyleProfileProvider._();

final class ResetStyleProfileProvider
    extends
        $FunctionalProvider<
          ResetStyleProfile,
          ResetStyleProfile,
          ResetStyleProfile
        >
    with $Provider<ResetStyleProfile> {
  ResetStyleProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'resetStyleProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$resetStyleProfileHash();

  @$internal
  @override
  $ProviderElement<ResetStyleProfile> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ResetStyleProfile create(Ref ref) {
    return resetStyleProfile(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ResetStyleProfile value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ResetStyleProfile>(value),
    );
  }
}

String _$resetStyleProfileHash() => r'f9cdf3d526dba5646294eb2cb7ec1ad5107eb18b';

@ProviderFor(completeOnboarding)
final completeOnboardingProvider = CompleteOnboardingProvider._();

final class CompleteOnboardingProvider
    extends
        $FunctionalProvider<
          CompleteOnboarding,
          CompleteOnboarding,
          CompleteOnboarding
        >
    with $Provider<CompleteOnboarding> {
  CompleteOnboardingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'completeOnboardingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$completeOnboardingHash();

  @$internal
  @override
  $ProviderElement<CompleteOnboarding> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CompleteOnboarding create(Ref ref) {
    return completeOnboarding(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CompleteOnboarding value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CompleteOnboarding>(value),
    );
  }
}

String _$completeOnboardingHash() =>
    r'58f2d305c1bdfcc2d842c07d506a02a681cee4be';

/// The user's explicit preferences, live.

@ProviderFor(styleProfile)
final styleProfileProvider = StyleProfileProvider._();

/// The user's explicit preferences, live.

final class StyleProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<StyleProfile>,
          StyleProfile,
          Stream<StyleProfile>
        >
    with $FutureModifier<StyleProfile>, $StreamProvider<StyleProfile> {
  /// The user's explicit preferences, live.
  StyleProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'styleProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$styleProfileHash();

  @$internal
  @override
  $StreamProviderElement<StyleProfile> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<StyleProfile> create(Ref ref) {
    return styleProfile(ref);
  }
}

String _$styleProfileHash() => r'766d77f42ab6959293cf771cfdad7097a45a9730';

/// Whether onboarding had been completed when the app launched. Read once
/// in bootstrap so the first screen is chosen without a loading flash.

@ProviderFor(onboardingCompleteAtLaunch)
final onboardingCompleteAtLaunchProvider =
    OnboardingCompleteAtLaunchProvider._();

/// Whether onboarding had been completed when the app launched. Read once
/// in bootstrap so the first screen is chosen without a loading flash.

final class OnboardingCompleteAtLaunchProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether onboarding had been completed when the app launched. Read once
  /// in bootstrap so the first screen is chosen without a loading flash.
  OnboardingCompleteAtLaunchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingCompleteAtLaunchProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingCompleteAtLaunchHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return onboardingCompleteAtLaunch(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$onboardingCompleteAtLaunchHash() =>
    r'0033975bdd7c9c402c8c8b78b97d0dd6707f3887';
