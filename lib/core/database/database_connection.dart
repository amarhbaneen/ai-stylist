import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// Opens the on-device database in the app-support directory, which is
/// private to the app and not exposed in user-visible file browsers.
QueryExecutor openAppDatabaseConnection() => driftDatabase(
  name: 'ai_stylist',
  native: const DriftNativeOptions(
    databaseDirectory: getApplicationSupportDirectory,
  ),
);
