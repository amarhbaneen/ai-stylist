/// An enum value with a stable string code used for persistence and backups.
///
/// Codes never change once released; renaming a Dart identifier must not
/// change its stored code.
abstract interface class CodedEnum {
  String get code;
}

/// Looks up [code] in [values], returning [fallback] when it is unknown
/// (for example data written by a newer app version).
T enumFromCode<T extends CodedEnum>(
  List<T> values,
  String? code, {
  required T fallback,
}) {
  if (code == null) return fallback;
  for (final value in values) {
    if (value.code == code) return value;
  }
  return fallback;
}
