import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

import '../core/database/app_database.dart';
import '../core/database/database_connection.dart';
import '../core/logging/app_logger.dart';
import '../core/providers.dart';
import 'app.dart';

/// Initialises error handling and local storage, then runs the app.
///
/// Nothing here touches the network: the app starts fully offline.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  final database = AppDatabase(openAppDatabaseConnection());

  runApp(
    ProviderScope(
      overrides: [
        appSupportDirectoryProvider.overrideWithValue(supportDir),
        appDatabaseProvider.overrideWithValue(database),
      ],
      child: const AiStylistApp(),
    ),
  );
}
