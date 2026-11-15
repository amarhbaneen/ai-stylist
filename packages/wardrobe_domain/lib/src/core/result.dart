import 'app_failure.dart';

/// Outcome of a use case or repository call: either a value or a typed
/// [AppFailure]. Callers must handle both branches explicitly.
sealed class Result<T> {
  const Result();

  /// Returns the value, or `null` when this is a [Failure].
  T? get valueOrNull => switch (this) {
    Success<T>(:final value) => value,
    Failure<T>() => null,
  };

  bool get isSuccess => this is Success<T>;
}

final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

final class Failure<T> extends Result<T> {
  const Failure(this.failure);

  final AppFailure failure;
}
