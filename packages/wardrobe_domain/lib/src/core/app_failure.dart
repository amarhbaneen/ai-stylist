/// Typed failures shared by every layer. Presentation maps each subtype to a
/// user-friendly message; nothing is caught and silently ignored.
///
/// Normally returned inside a `Result`; it implements [Exception] so it can
/// also be raised into async state (e.g. Riverpod's `AsyncError`).
sealed class AppFailure implements Exception {
  const AppFailure(this.message, {this.cause});

  /// Developer-facing description (never shown verbatim to users).
  final String message;

  /// Underlying error, kept for local logging only.
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// Reading or writing local storage (database or files) failed.
final class StorageFailure extends AppFailure {
  const StorageFailure(super.message, {super.cause});
}

/// The device does not have enough free space for the operation.
final class InsufficientStorageFailure extends AppFailure {
  const InsufficientStorageFailure(super.message, {super.cause});
}

/// The user denied a permission required for the action.
final class PermissionDeniedFailure extends AppFailure {
  const PermissionDeniedFailure(super.message, {super.cause});
}

/// The selected file is not a supported image.
final class UnsupportedImageFailure extends AppFailure {
  const UnsupportedImageFailure(super.message, {super.cause});
}

/// The same image already belongs to an existing item.
final class DuplicateItemFailure extends AppFailure {
  const DuplicateItemFailure(super.message, {required this.existingItemId});

  final String existingItemId;
}

/// A record that should exist was not found.
final class NotFoundFailure extends AppFailure {
  const NotFoundFailure(super.message);
}

/// Input failed validation (for example an unknown taxonomy value).
final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

/// The requested model is not installed or cannot run on this device.
final class ModelUnavailableFailure extends AppFailure {
  const ModelUnavailableFailure(super.message, {super.cause});
}

/// A model file failed integrity or format checks.
final class ModelCorruptFailure extends AppFailure {
  const ModelCorruptFailure(super.message, {super.cause});
}

/// On-device inference failed at run time.
final class InferenceFailure extends AppFailure {
  const InferenceFailure(super.message, {super.cause});
}

/// An optional, user-initiated network request failed.
final class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message, {super.cause});
}

/// A backup archive failed validation before import.
final class ArchiveValidationFailure extends AppFailure {
  const ArchiveValidationFailure(super.message, {super.cause});
}

/// The user cancelled the operation.
final class CancelledFailure extends AppFailure {
  const CancelledFailure([super.message = 'Cancelled by user']);
}
