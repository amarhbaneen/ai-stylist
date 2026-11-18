import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../../core/database/app_database.dart';
import '../domain/official_photo.dart';

/// Where the user's API key is kept: the platform keystore (Android
/// Keystore-backed encryption, iOS Keychain). Overridden in tests.
abstract interface class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String? value);
}

/// [SecretStore] with `flutter_secure_storage`.
final class KeystoreSecretStore implements SecretStore {
  const KeystoreSecretStore();

  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String? value) => value == null
      ? _storage.delete(key: key)
      : _storage.write(key: key, value: value);
}

/// The opt-in in `app_settings` (off by default) and the API key in the
/// [SecretStore], never in the database (D-43).
final class StoredOfficialPhotoSettings implements OfficialPhotoSettings {
  StoredOfficialPhotoSettings(this._db, this._secrets);

  final AppDatabase _db;
  final SecretStore _secrets;

  static const enabledKey = 'official_photo_search_enabled';
  static const apiKeyName = 'google_cloud_vision_api_key';

  @override
  Future<Result<bool>> isEnabled() async {
    try {
      final row = await (_db.select(
        _db.appSettings,
      )..where((t) => t.key.equals(enabledKey))).getSingleOrNull();
      return Success(row?.value == 'true');
    } on Exception catch (e) {
      return Failure(StorageFailure('Could not read settings', cause: e));
    }
  }

  @override
  Future<Result<void>> setEnabled({required bool enabled}) async {
    try {
      await _db
          .into(_db.appSettings)
          .insertOnConflictUpdate(
            AppSettingsCompanion.insert(key: enabledKey, value: '$enabled'),
          );
      return const Success(null);
    } on Exception catch (e) {
      return Failure(StorageFailure('Could not save settings', cause: e));
    }
  }

  @override
  Future<Result<String?>> apiKey() async {
    try {
      return Success(await _secrets.read(apiKeyName));
    } on PlatformException catch (e) {
      return Failure(StorageFailure('Could not read the API key', cause: e));
    }
  }

  @override
  Future<Result<void>> setApiKey(String? key) async {
    final value = key?.trim();
    try {
      await _secrets.write(
        apiKeyName,
        value == null || value.isEmpty ? null : value,
      );
      return const Success(null);
    } on PlatformException catch (e) {
      return Failure(StorageFailure('Could not save the API key', cause: e));
    }
  }
}
