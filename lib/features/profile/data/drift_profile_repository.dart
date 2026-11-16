import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../../core/database/app_database.dart';

/// Stores the single local profile and first-launch state in SQLite.
final class DriftProfileRepository implements ProfileRepository {
  DriftProfileRepository({required AppDatabase database, required this._clock})
    : _db = database;

  final AppDatabase _db;
  final Clock _clock;

  /// There is exactly one local profile (FR-01).
  static const profileId = 'local';
  static const onboardingKey = 'onboarding_complete';

  @override
  Future<Result<StyleProfile>> getProfile() async {
    try {
      final row = await _profileQuery().getSingleOrNull();
      return Success(_toDomain(row));
    } on Exception catch (e) {
      return Failure(StorageFailure('Could not read preferences', cause: e));
    }
  }

  @override
  Stream<StyleProfile> watchProfile() =>
      _profileQuery().watchSingleOrNull().map(_toDomain);

  SimpleSelectStatement<$UserProfileTable, UserProfileRow> _profileQuery() =>
      _db.select(_db.userProfile)..where((t) => t.id.equals(profileId));

  @override
  Future<Result<void>> saveProfile(StyleProfile profile) async {
    try {
      final now = toEpochMillisUtc(_clock.nowUtc());
      await _db
          .into(_db.userProfile)
          .insert(
            UserProfileCompanion.insert(
              id: profileId,
              preferredStyles: Value(_codes(profile.preferredStyles)),
              favoredColors: Value(_codes(profile.favoredColors)),
              avoidedColors: Value(_codes(profile.avoidedColors)),
              fitPreference: Value(profile.fit?.code),
              formalityPreference: Value(profile.formality?.level),
              createdAt: now,
              updatedAt: now,
            ),
            onConflict: DoUpdate(
              (old) => UserProfileCompanion(
                preferredStyles: Value(_codes(profile.preferredStyles)),
                favoredColors: Value(_codes(profile.favoredColors)),
                avoidedColors: Value(_codes(profile.avoidedColors)),
                fitPreference: Value(profile.fit?.code),
                formalityPreference: Value(profile.formality?.level),
                updatedAt: Value(now),
              ),
            ),
          );
      return const Success(null);
    } on Exception catch (e) {
      return Failure(StorageFailure('Could not save preferences', cause: e));
    }
  }

  @override
  Future<Result<void>> resetProfile() => saveProfile(StyleProfile.empty);

  @override
  Future<Result<bool>> isOnboardingComplete() async {
    try {
      final row = await (_db.select(
        _db.appSettings,
      )..where((t) => t.key.equals(onboardingKey))).getSingleOrNull();
      return Success(row?.value == 'true');
    } on Exception catch (e) {
      return Failure(StorageFailure('Could not read settings', cause: e));
    }
  }

  @override
  Future<Result<void>> markOnboardingComplete() async {
    try {
      await _db
          .into(_db.appSettings)
          .insertOnConflictUpdate(
            AppSettingsCompanion.insert(key: onboardingKey, value: 'true'),
          );
      return const Success(null);
    } on Exception catch (e) {
      return Failure(StorageFailure('Could not save settings', cause: e));
    }
  }

  static String _codes(Iterable<CodedEnum> values) =>
      jsonEncode([for (final v in values) v.code]..sort());

  static List<String> _decode(String json) {
    try {
      final decoded = jsonDecode(json);
      return decoded is List ? decoded.whereType<String>().toList() : const [];
    } on FormatException {
      return const [];
    }
  }

  static StyleProfile _toDomain(UserProfileRow? row) {
    if (row == null) return StyleProfile.empty;
    return StyleProfile(
      preferredStyles: {
        for (final c in _decode(row.preferredStyles))
          ?StylePreference.tryFromCode(c),
      },
      favoredColors: {
        for (final c in _decode(row.favoredColors)) ?ColorFamily.tryFromCode(c),
      },
      avoidedColors: {
        for (final c in _decode(row.avoidedColors)) ?ColorFamily.tryFromCode(c),
      },
      fit: switch (GarmentFit.fromCode(row.fitPreference)) {
        GarmentFit.unknown => null,
        final fit => fit,
      },
      formality: Formality.tryFromLevel(row.formalityPreference),
    );
  }
}
