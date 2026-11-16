import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../../shared/taxonomy_labels.dart';
import '../weather_providers.dart';
import 'city_search_sheet.dart';

/// Explains exactly what live weather sends, and asks for consent.
/// Returns `true` only if the user explicitly agrees.
Future<bool> askLiveWeatherConsent(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Use live weather?'),
        content: const SingleChildScrollView(
          child: Text(
            'When you tap "Get current weather", the app asks Open-Meteo '
            '(api.open-meteo.com) for the current weather.\n\n'
            'Sent: the approximate location of the city you choose '
            '(rounded to about 1 km) and, as with any internet request, your '
            'IP address.\n\n'
            'Never sent: your photos, wardrobe, preferences or precise '
            'location. Nothing is fetched in the background.\n\n'
            'You can turn this off any time in Style preferences.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Allow'),
          ),
        ],
      ),
    ) ??
    false;

/// Opt-in live weather inside the Stylist's weather section. Fetches only
/// when the user taps the button; on failure the manual values stay.
class LiveWeatherPanel extends ConsumerStatefulWidget {
  const LiveWeatherPanel({required this.onReport, this.report, super.key});

  /// Called with fresh conditions to fill the manual controls.
  final ValueChanged<WeatherReport> onReport;

  /// The last fetched report still shown in the form (if any).
  final WeatherReport? report;

  @override
  ConsumerState<LiveWeatherPanel> createState() => _LiveWeatherPanelState();
}

class _LiveWeatherPanelState extends ConsumerState<LiveWeatherPanel> {
  var _loading = false;

  Future<void> _enable() async {
    if (!await askLiveWeatherConsent(context)) return;
    await ref.read(liveWeatherStateProvider.notifier).setEnabled(enabled: true);
  }

  Future<void> _chooseCity() async {
    final city = await CitySearchSheet.show(context);
    if (city == null) return;
    await ref.read(liveWeatherStateProvider.notifier).selectCity(city);
  }

  Future<void> _fetch(City city) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loading = true);
    final result = await ref.read(fetchLiveWeatherProvider).call(city);
    if (!mounted) return;
    setState(() => _loading = false);
    switch (result) {
      case Success(:final value):
        widget.onReport(value);
      case Failure(:final failure):
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              failure is NetworkFailure
                  ? 'Couldn\'t get live weather. Enter it below instead.'
                  : failureMessage(failure),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveWeatherStateProvider).value;
    if (state == null) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    if (!state.enabled) {
      return Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: _enable,
          icon: const Icon(Icons.cloud_outlined),
          label: const Text('Use live weather'),
        ),
      );
    }
    final city = state.city;
    final report = widget.report;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_city_outlined, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(city?.label ?? 'No city chosen')),
            TextButton(
              onPressed: _chooseCity,
              child: Text(city == null ? 'Choose city' : 'Change'),
            ),
          ],
        ),
        FilledButton.tonalIcon(
          onPressed: city == null || _loading ? null : () => _fetch(city),
          icon: _loading
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.cloud_download_outlined),
          label: const Text('Get current weather'),
        ),
        if (report != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${report.city.name}: ${report.temperatureC.round()} °C, '
              '${report.isWet ? 'wet' : 'dry'} · weather data by '
              'Open-Meteo.com (CC BY 4.0)',
              style: text.bodySmall,
            ),
          ),
      ],
    );
  }
}
