import 'package:meta/meta.dart';

import '../core/result.dart';
import '../core/set_equality.dart';
import '../taxonomy/taxonomy.dart';

/// The user's *explicit* style preferences (FR-01). Every field is optional.
///
/// Learned preferences live separately and never overwrite these (FR-08).
@immutable
final class StyleProfile {
  StyleProfile({
    Set<StylePreference> preferredStyles = const {},
    Set<ColorFamily> favoredColors = const {},
    Set<ColorFamily> avoidedColors = const {},
    this.fit,
    this.formality,
  }) : preferredStyles = Set.unmodifiable(preferredStyles),
       favoredColors = Set.unmodifiable(favoredColors),
       // A colour cannot be both favoured and avoided; favoured wins.
       avoidedColors = Set.unmodifiable(
         avoidedColors.difference(favoredColors),
       );

  static final empty = StyleProfile();

  final Set<StylePreference> preferredStyles;
  final Set<ColorFamily> favoredColors;
  final Set<ColorFamily> avoidedColors;
  final GarmentFit? fit;
  final Formality? formality;

  bool get isEmpty =>
      preferredStyles.isEmpty &&
      favoredColors.isEmpty &&
      avoidedColors.isEmpty &&
      fit == null &&
      formality == null;

  @override
  bool operator ==(Object other) =>
      other is StyleProfile &&
      setEquals(other.preferredStyles, preferredStyles) &&
      setEquals(other.favoredColors, favoredColors) &&
      setEquals(other.avoidedColors, avoidedColors) &&
      other.fit == fit &&
      other.formality == formality;

  @override
  int get hashCode => Object.hash(
    setHash(preferredStyles),
    setHash(favoredColors),
    setHash(avoidedColors),
    fit,
    formality,
  );
}

/// Local profile and first-launch state (REQUIREMENTS §12).
abstract interface class ProfileRepository {
  Future<Result<StyleProfile>> getProfile();

  Stream<StyleProfile> watchProfile();

  Future<Result<void>> saveProfile(StyleProfile profile);

  /// Clears explicit preferences back to [StyleProfile.empty].
  Future<Result<void>> resetProfile();

  Future<Result<bool>> isOnboardingComplete();

  Future<Result<void>> markOnboardingComplete();
}
