import '../core/result.dart';
import 'style_profile.dart';

final class SaveStyleProfile {
  const SaveStyleProfile(this._repository);

  final ProfileRepository _repository;

  Future<Result<void>> call(StyleProfile profile) =>
      _repository.saveProfile(profile);
}

/// Clears explicit preferences only (learned preferences are separate, D-11).
final class ResetStyleProfile {
  const ResetStyleProfile(this._repository);

  final ProfileRepository _repository;

  Future<Result<void>> call() => _repository.resetProfile();
}

/// Finishes first launch, saving any preferences the user chose (all
/// optional; skipping saves nothing but still completes onboarding).
final class CompleteOnboarding {
  const CompleteOnboarding(this._repository);

  final ProfileRepository _repository;

  Future<Result<void>> call({StyleProfile? profile}) async {
    if (profile != null && !profile.isEmpty) {
      final saved = await _repository.saveProfile(profile);
      if (saved is Failure<void>) return saved;
    }
    return _repository.markOnboardingComplete();
  }
}
