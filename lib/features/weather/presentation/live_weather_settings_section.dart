import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../weather_providers.dart';
import 'city_search_sheet.dart';
import 'live_weather_panel.dart';

/// Live-weather consent, city and attributions in Style preferences.
class LiveWeatherSettingsSection extends ConsumerWidget {
  const LiveWeatherSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(liveWeatherStateProvider).value;
    final notifier = ref.read(liveWeatherStateProvider.notifier);
    final text = Theme.of(context).textTheme;
    final enabled = state?.enabled ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 40),
        Text('Live weather', style: text.titleMedium),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Allow live weather'),
          subtitle: const Text(
            'Only when you tap "Get current weather" in the Stylist. Sends '
            'the chosen city\'s approximate location to Open-Meteo.',
          ),
          value: enabled,
          onChanged: state == null
              ? null
              : (on) async {
                  if (on && !await askLiveWeatherConsent(context)) return;
                  await notifier.setEnabled(enabled: on);
                },
        ),
        if (enabled)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.location_city_outlined),
            title: Text(state?.city?.label ?? 'No city chosen'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final city = await CitySearchSheet.show(context);
              if (city != null) await notifier.selectCity(city);
            },
          ),
        const SizedBox(height: 8),
        Text(
          'Weather data by Open-Meteo.com (CC BY 4.0, '
          'open-meteo.com/en/licence). City list by GeoNames '
          '(CC BY 4.0, geonames.org).',
          style: text.bodySmall,
        ),
      ],
    );
  }
}
