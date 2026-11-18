import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart'
    show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../core/database/app_database.dart';
import '../core/database/database_connection.dart';
import '../core/logging/app_logger.dart';
import '../core/providers.dart';
import '../features/profile/profile_providers.dart';
import '../features/wardrobe/wardrobe_providers.dart';
import 'app.dart';

/// Initialises error handling and local storage, then runs the app.
///
/// Nothing here touches the network: the app starts fully offline.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicenses();

  FlutterError.onError = (details) {
    AppLogger.error(
      'Flutter framework error',
      details.exception,
      details.stack,
    );
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('Uncaught platform error', error, stack);
    return true;
  };

  final Directory supportDir;
  try {
    supportDir = await getApplicationSupportDirectory();
    await supportDir.create(recursive: true);
  } on Exception catch (e, s) {
    // MissingPlatformDirectoryException or a FileSystemException.
    AppLogger.error('Could not resolve private storage', e, s);
    runApp(const StartupErrorApp());
    return;
  }

  final container = ProviderContainer(
    overrides: [
      appSupportDirectoryProvider.overrideWithValue(supportDir),
      appDatabaseProvider.overrideWithValue(
        AppDatabase(openAppDatabaseConnection()),
      ),
    ],
  );

  final onboarding = await container
      .read(profileRepositoryProvider)
      .isOnboardingComplete();
  final bool onboardingComplete;
  switch (onboarding) {
    case Success(:final value):
      onboardingComplete = value;
    case Failure(:final failure):
      AppLogger.error('Could not open the database', failure);
      runApp(const StartupErrorApp());
      return;
  }

  // Remove files left behind by an interrupted import or delete. Runs in the
  // background; failure only means the clean-up is retried next launch.
  unawaited(
    container.read(wardrobeRepositoryProvider).removeOrphanFiles().then((r) {
      if (r case Success(:final value) when value > 0) {
        AppLogger.info('Removed $value orphaned image files');
      }
    }),
  );

  runApp(
    UncontrolledProviderScope(
      container: ProviderContainer(
        parent: container,
        overrides: [
          onboardingCompleteAtLaunchProvider.overrideWithValue(
            onboardingComplete,
          ),
        ],
      ),
      child: const AiStylistApp(),
    ),
  );
}

/// Lists the bundled fonts' SIL OFL licences on the licences page.
void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final (family, file) in const [
      ('Geist', 'assets/fonts/Geist-OFL.txt'),
      ('Instrument Serif', 'assets/fonts/InstrumentSerif-OFL.txt'),
    ]) {
      yield LicenseEntryWithLineBreaks([
        family,
      ], await rootBundle.loadString(file));
    }
  });
}
