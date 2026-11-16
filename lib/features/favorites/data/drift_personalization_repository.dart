import 'package:outfit_engine/outfit_engine.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../../core/database/app_database.dart';

/// Learned weights in `learned_preferences`; the reset marker in
/// `app_settings`. Explicit preferences (`user_profile`) are never touched.
final class DriftPersonalizationRepository
    implements PersonalizationRepository {
  DriftPersonalizationRepository({
    required AppDatabase database,
    required this._clock,
  }) : _db = database;

  final AppDatabase _db;
  final Clock _clock;

  static const resetKey = 'personalization_reset_at';

  @override
  Future<Result<LearnedPreferences>> load() async {
    try {
      return Success(_toDomain(await _db.select(_db.learnedPreferences).get()));
    } on Exception catch (e) {
      return Failure(StorageFailure('Could not read learned prefs', cause: e));
    }
  }

  @override
  Stream<LearnedPreferences> watch() =>
      _db.select(_db.learnedPreferences).watch().map(_toDomain);

  @override
  Future<Result<void>> replace(LearnedPreferences learned) async {
    final now = toEpochMillisUtc(_clock.nowUtc());
    try {
      await _db.transaction(() async {
        await _db.delete(_db.learnedPreferences).go();
        await _db.batch(
          (b) => b.insertAll(_db.learnedPreferences, [
            for (final e in learned.weights.entries)
              LearnedPreferencesCompanion.insert(
                key: e.key,
                // Guard against float noise at the ±0.30 bound (CHECK).
                weight: e.value.clamp(
                  -PreferenceLearner.maxWeight,
                  PreferenceLearner.maxWeight,
                ),
                updatedAt: now,
              ),
          ]),
        );
      });
      return const Success(null);
    } on Exception catch (e) {
      return Failure(StorageFailure('Could not save learned prefs', cause: e));
    }
  }

  @override
  Future<Result<DateTime?>> resetAt() async {
    try {
      final row = await (_db.select(
        _db.appSettings,
      )..where((t) => t.key.equals(resetKey))).getSingleOrNull();
      final millis = int.tryParse(row?.value ?? '');
      return Success(millis == null ? null : fromEpochMillisUtc(millis));
    } on Exception catch (e) {
      return Failure(StorageFailure('Could not read settings', cause: e));
    }
  }

  @override
  Future<Result<void>> reset(DateTime at) async {
    try {
      await _db.transaction(() async {
        await _db.delete(_db.learnedPreferences).go();
        await _db
            .into(_db.appSettings)
            .insertOnConflictUpdate(
              AppSettingsCompanion.insert(
                key: resetKey,
                value: '${toEpochMillisUtc(at)}',
              ),
            );
      });
      return const Success(null);
    } on Exception catch (e) {
      return Failure(StorageFailure('Could not reset learning', cause: e));
    }
  }

  static LearnedPreferences _toDomain(List<LearnedPreferenceRow> rows) =>
      LearnedPreferences({for (final r in rows) r.key: r.weight});
}
