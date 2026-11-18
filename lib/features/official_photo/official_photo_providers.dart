import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../core/logging/app_logger.dart';
import '../../core/media/visual_search.dart' show flattenForSearch;
import '../../core/providers.dart';
import '../weather/weather_providers.dart' show httpClientProvider;
import 'data/candidate_downloader.dart';
import 'data/cloud_vision_search.dart';
import 'data/official_photo_settings_store.dart';
import 'domain/find_official_photo.dart';
import 'domain/official_photo.dart';

part 'official_photo_providers.g.dart';

@Riverpod(keepAlive: true)
SecretStore secretStore(Ref ref) => const KeystoreSecretStore();

@Riverpod(keepAlive: true)
OfficialPhotoSettings officialPhotoSettings(Ref ref) =>
    StoredOfficialPhotoSettings(
      ref.watch(appDatabaseProvider),
      ref.watch(secretStoreProvider),
    );

const _channel = MethodChannel('ai_stylist/visual_search');

/// This app's package name and signing SHA-1 on Android, for API keys
/// restricted to the app; `null` elsewhere or if it cannot be read.
Future<AndroidIdentity?> _androidIdentity() async {
  if (!Platform.isAndroid) return null;
  try {
    final map = await _channel.invokeMapMethod<String, String?>('appIdentity');
    final package = map?['package'];
    final sha1 = map?['sha1'];
    if (package == null || sha1 == null) return null;
    return (package: package, sha1: sha1);
  } on PlatformException catch (e) {
    AppLogger.error('Could not read the app identity', e);
    return null;
  } on MissingPluginException {
    return null;
  }
}

@Riverpod(keepAlive: true)
ProductImageSearch productImageSearch(Ref ref) {
  final settings = ref.watch(officialPhotoSettingsProvider);
  return CloudVisionSearch(
    client: ref.watch(httpClientProvider),
    apiKey: () async => (await settings.apiKey()).valueOrNull,
    androidIdentity: _androidIdentity,
  );
}

/// Folder for downloaded candidates of one item, emptied before each
/// search (D-43).
Directory _candidateDir(Ref ref, String itemId) => Directory(
  p.join(
    ref.watch(appSupportDirectoryProvider).path,
    'official_photo_candidates',
    itemId,
  ),
);

@Riverpod(keepAlive: true)
CandidateDownloader candidateDownloader(Ref ref) =>
    HttpCandidateDownloader(client: ref.watch(httpClientProvider));

/// Official-photo suggestions for the cut-out at [imagePath] of item
/// [itemId]. Computed once while the item is on screen; "search again"
/// invalidates it.
@riverpod
Future<Result<List<DownloadedCandidate>>> officialPhotoSuggestions(
  Ref ref,
  String itemId,
  String imagePath,
) async {
  // Read every dependency before the first await.
  final dir = _candidateDir(ref, itemId);
  final store = ref.watch(fileStoreProvider);
  final find = FindOfficialPhoto(
    settings: ref.watch(officialPhotoSettingsProvider),
    search: ref.watch(productImageSearchProvider),
    downloader: ref.watch(candidateDownloaderProvider),
    prepare: (path) async {
      final file = store.resolve(path).path;
      try {
        return await Isolate.run(() => flattenForSearch(file));
      } on Exception catch (e) {
        AppLogger.error('Could not prepare the cut-out', e);
        return null;
      }
    },
  );
  try {
    if (await dir.exists()) await dir.delete(recursive: true);
  } on FileSystemException catch (e) {
    AppLogger.error('Could not clear old candidates', e);
  }
  return find(imagePath, dir);
}

/// The feature's switch and whether a key is saved, for the settings UI.
@riverpod
class OfficialPhotoState extends _$OfficialPhotoState {
  @override
  Future<({bool enabled, bool hasKey})> build() async {
    final settings = ref.watch(officialPhotoSettingsProvider);
    final enabled = (await settings.isEnabled()).valueOrNull ?? false;
    final key = (await settings.apiKey()).valueOrNull;
    return (enabled: enabled, hasKey: key != null && key.isNotEmpty);
  }

  Future<Result<void>> setEnabled({required bool enabled}) async {
    final r = await ref
        .read(officialPhotoSettingsProvider)
        .setEnabled(enabled: enabled);
    ref.invalidateSelf();
    return r;
  }

  Future<Result<void>> setApiKey(String? key) async {
    final r = await ref.read(officialPhotoSettingsProvider).setApiKey(key);
    ref.invalidateSelf();
    return r;
  }
}
