import 'dart:developer' as developer;

/// Local-only logger. Writes to the platform debug log; it never sends data
/// off the device (no crash reporting or analytics SDKs, CLAUDE.md rule 5).
abstract final class AppLogger {
  static void info(String message) =>
      developer.log(message, name: 'ai_stylist');

  static void error(String message, Object error, [StackTrace? stackTrace]) =>
      developer.log(
        message,
        name: 'ai_stylist',
        level: 1000,
        error: error,
        stackTrace: stackTrace,
      );
}
