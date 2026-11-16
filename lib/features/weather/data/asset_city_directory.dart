import 'dart:convert';
import 'dart:isolate';

import 'package:wardrobe_domain/wardrobe_domain.dart';

/// Offline city search over the bundled GeoNames list (CC BY 4.0), built by
/// `tools/build_cities.ps1`. Searching never touches the network.
final class AssetCityDirectory implements CityDirectory {
  AssetCityDirectory(this._loadJson);

  static const asset = 'assets/cities/cities.json';

  /// Loads the raw JSON text (rootBundle in the app, a string in tests).
  final Future<String> Function() _loadJson;

  Future<List<_Entry>>? _entries;

  Future<List<_Entry>> _load() => _entries ??= _loadJson().then(
    // ~700 KB of JSON: parse off the UI thread.
    (text) => Isolate.run(() => _parse(text)),
  );

  @override
  Future<List<City>> search(String query, {int limit = 20}) async {
    final q = _fold(query.trim());
    if (q.isEmpty) return const [];
    final entries = await _load();
    final starts = <City>[];
    final contains = <City>[];
    for (final e in entries) {
      if (starts.length >= limit) break;
      if (e.key.startsWith(q)) {
        starts.add(e.city);
      } else if (contains.length < limit && e.key.contains(q)) {
        contains.add(e.city);
      }
    }
    // Entries are sorted by population, so each group is already ranked.
    return [...starts, ...contains].take(limit).toList();
  }

  @override
  Future<City?> byId(int id) async {
    for (final e in await _load()) {
      if (e.city.id == id) return e.city;
    }
    return null;
  }

  static List<_Entry> _parse(String text) {
    final rows = jsonDecode(text) as List<Object?>;
    return [
      for (final r in rows)
        if (r is List && r.length >= 7)
          _Entry(
            '${_fold(r[1] as String)}\n${_fold(r[2] as String)}',
            City(
              id: (r[0] as num).toInt(),
              name: r[1] as String,
              countryCode: r[3] as String,
              latitude: (r[4] as num).toDouble(),
              longitude: (r[5] as num).toDouble(),
              population: (r[6] as num).toInt(),
            ),
          ),
    ];
  }

  /// Lower-case, with common Latin diacritics removed, so "zurich" finds
  /// "Zürich" (the ASCII name is searched too).
  static String _fold(String s) {
    const from = 'àáâãäåçèéêëìíîïñòóôõöøùúûüýÿ';
    const to = 'aaaaaaceeeeiiiinoooooouuuuyy';
    final lower = s.toLowerCase();
    final out = StringBuffer();
    for (final ch in lower.split('')) {
      final i = from.indexOf(ch);
      out.write(i >= 0 ? to[i] : ch);
    }
    return out.toString();
  }
}

final class _Entry {
  _Entry(this.key, this.city);

  /// Folded "name\nasciiName" used for matching.
  final String key;
  final City city;
}
