/// Generates stable unique identifiers (UUID v4 in production).
abstract interface class IdGenerator {
  String newId();
}
