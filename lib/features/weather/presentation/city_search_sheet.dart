import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../weather_providers.dart';

/// Searches the bundled city list. Typing never sends anything anywhere.
class CitySearchSheet extends ConsumerStatefulWidget {
  const CitySearchSheet({super.key});

  static Future<City?> show(BuildContext context) => showModalBottomSheet<City>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const CitySearchSheet(),
  );

  @override
  ConsumerState<CitySearchSheet> createState() => _CitySearchSheetState();
}

class _CitySearchSheetState extends ConsumerState<CitySearchSheet> {
  var _results = const <City>[];
  var _query = '';

  Future<void> _search(String query) async {
    _query = query;
    final results = await ref.read(cityDirectoryProvider).search(query);
    // Ignore results for an older query that finished late.
    if (mounted && query == _query) setState(() => _results = results);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search cities (offline)',
                border: OutlineInputBorder(),
              ),
              onChanged: _search,
            ),
          ),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Text(
                      _query.trim().isEmpty
                          ? 'Type a city name'
                          : 'No matching city. Try a nearby larger city.',
                    ),
                  )
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, i) {
                      final c = _results[i];
                      return ListTile(
                        leading: const Icon(Icons.place_outlined),
                        title: Text(c.name),
                        subtitle: Text(c.countryCode),
                        onTap: () => Navigator.pop(context, c),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );
}
