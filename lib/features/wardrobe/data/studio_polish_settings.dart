import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../../core/database/app_database.dart';

/// The "Studio polish" choice in `app_settings` (DECISIONS D-44). On by
/// default: the row exists only once the user changes it.
final class StudioPolishSettings {
  StudioPolishSettings(this._db);

  final AppDatabase _db;

  static const key = 'studio_polish_enabled';

  Future<Result<bool>> isEnabled() async {
    try {
      final row = await (_db.select(
        _db.appSettings,
      )..where((t) => t.key.equals(key))).getSingleOrNull();
      return Success(row?.value != 'false');
    } on Exception catch (e) {
      return Failure(StorageFailure('Could not read settings', cause: e));
    }
  }

  Future<Result<void>> setEnabled({required bool enabled}) async {
    try {
      await _db
          .into(_db.appSettings)
          .insertOnConflictUpdate(
            AppSettingsCompanion.insert(key: key, value: '$enabled'),
          );
      return const Success(null);
    } on Exception catch (e) {
      return Failure(StorageFailure('Could not save settings', cause: e));
    }
  }
}
