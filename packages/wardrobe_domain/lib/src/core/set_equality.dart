/// Order-independent equality for small sets (avoids a `collection` dependency).
bool setEquals<T>(Set<T> a, Set<T> b) =>
    a.length == b.length && a.containsAll(b);

/// Order-independent hash for small sets.
int setHash<T>(Set<T> values) => Object.hashAllUnordered(values);
