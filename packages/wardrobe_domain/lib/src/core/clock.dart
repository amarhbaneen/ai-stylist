/// Source of the current time. Inject a fake in tests for determinism.
abstract interface class Clock {
  /// Current instant in UTC.
  DateTime nowUtc();
}

/// [Clock] backed by the system clock.
final class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}

/// Converts a UTC [DateTime] to the integer milliseconds stored in the database.
int toEpochMillisUtc(DateTime time) => time.toUtc().millisecondsSinceEpoch;

/// Converts stored integer milliseconds back to a UTC [DateTime].
DateTime fromEpochMillisUtc(int millis) =>
    DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
