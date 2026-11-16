import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../../core/database/app_database.dart';

/// Live-weather consent and chosen city in `app_settings`. Consent defaults
/// to off: nothing is sent until the user turns it on.
final class DriftWeatherSettingsRepository
    implements WeatherSettingsRepository {
  DriftWeatherSettingsRepository(this._db);

  final AppDatabase _db;

  static const enabledKey = 'live_weather_enabled';
  static const cityKey = 'weather_city_id';

  Future<String?> _get(String key) async => (await (_db.select(
    _db.appSettings,
  )..where((t) => t.key.equals(key))).getSingleOrNull())?.value;

  Future<void> _set(String key, String value) => _db
      .into(_db.appSettings)
      .insertOnConflictUpdate(
        AppSettingsCompanion.insert(key: key, value: value),
      );

  @override
  Future<Result<bool>> isLiveWeatherEnabled() async {
    try {
      return Success(await _get(enabledKey) == 'true');
    } on Exception catch (e) {
      return Failure(StorageFailure('Could not read settings', cause: e));
    }
  }

  @override
  Future<Result<void>> setLiveWeatherEnabled({required bool enabled}) async {
    try {
      await _set(enabledKey, '$enabled');
      return const Success(null);
    } on Exception catch (e) {
      return Failure(StorageFailure('Could not save settings', cause: e));
    }
  }

  @override
  Future<Result<int?>> selectedCityId() async {
    try {
      return Success(int.tryParse(await _get(cityKey) ?? ''));
    } on Exception catch (e) {
      return Failure(StorageFailure('Could not read settings', cause: e));
    }
  }

  @override
  Future<Result<void>> selectCity(int cityId) async {
    try {
      await _set(cityKey, '$cityId');
      return const Success(null);
    } on Exception catch (e) {
      return Failure(StorageFailure('Could not save settings', cause: e));
    }
  }
}
