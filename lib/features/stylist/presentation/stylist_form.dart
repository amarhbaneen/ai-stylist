import 'package:material_ui/material_ui.dart';
import 'package:outfit_engine/outfit_engine.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../../shared/outfit_labels.dart';
import '../../../shared/taxonomy_labels.dart';
import '../../../shared/widgets/chip_selectors.dart';
import '../../weather/presentation/live_weather_panel.dart';

/// Mutable form state for the Stylist screen.
final class StylistFormState {
  Occasion occasion = Occasion.casual;
  Formality customFormality = Formality.smartCasual;
  StylePreference? style;
  bool weatherOn = false;
  double temperatureC = 18;
  bool rain = false;
  int count = 3;

  /// Last live report used to fill the controls; cleared on manual edits.
  WeatherReport? liveReport;

  /// Fills the (still editable) manual controls from a live report.
  void applyReport(WeatherReport report) {
    temperatureC = report.temperatureC.clamp(-10, 40).roundToDouble();
    rain = report.isWet;
    liveReport = report;
  }

  StylistQuery toQuery() => StylistQuery(
    occasion: occasion,
    customFormality: occasion == Occasion.custom ? customFormality : null,
    style: style,
    weather: weatherOn
        ? WeatherContext(temperatureC: temperatureC, precipitation: rain)
        : null,
    count: count,
  );
}

/// Occasion, optional style, optional manual weather and result count
/// (REQUIREMENTS §6.4.1–3). Weather is entered by hand; live weather is an
/// opt-in helper that only fills the same editable controls.
class StylistForm extends StatelessWidget {
  const StylistForm({required this.state, required this.onChanged, super.key});

  final StylistFormState state;
  final VoidCallback onChanged;

  void _set(VoidCallback change) {
    change();
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final s = state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('Occasion'),
        SingleChipSelector<Occasion>(
          options: Occasion.values,
          selected: s.occasion,
          labelOf: OutfitLabels.occasion,
          onChanged: (o) => _set(() => s.occasion = o ?? s.occasion),
        ),
        if (s.occasion == Occasion.custom) ...[
          const FieldLabel('Formality'),
          SingleChipSelector<Formality>(
            options: Formality.values,
            selected: s.customFormality,
            labelOf: Labels.formality,
            onChanged: (f) =>
                _set(() => s.customFormality = f ?? s.customFormality),
          ),
        ],
        const FieldLabel('Style (optional)'),
        SingleChipSelector<StylePreference>(
          options: StylePreference.values,
          selected: s.style,
          labelOf: Labels.style,
          onChanged: (v) => _set(() => s.style = v),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Include weather'),
          subtitle: const Text('Entered by you, or fetched when you ask'),
          value: s.weatherOn,
          onChanged: (v) => _set(() => s.weatherOn = v),
        ),
        if (s.weatherOn) ...[
          LiveWeatherPanel(
            report: s.liveReport,
            onReport: (r) => _set(() => s.applyReport(r)),
          ),
          Row(
            children: [
              const Icon(Icons.thermostat),
              Expanded(
                child: Slider(
                  min: -10,
                  max: 40,
                  divisions: 50,
                  value: s.temperatureC,
                  label: '${s.temperatureC.round()} °C',
                  onChanged: (v) => _set(() {
                    s
                      ..temperatureC = v
                      ..liveReport = null;
                  }),
                ),
              ),
              SizedBox(
                width: 56,
                child: Text(
                  '${s.temperatureC.round()} °C',
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Rain or snow'),
            value: s.rain,
            onChanged: (v) => _set(() {
              s
                ..rain = v
                ..liveReport = null;
            }),
          ),
        ],
        const FieldLabel('How many ideas'),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 1, label: Text('1')),
            ButtonSegment(value: 2, label: Text('2')),
            ButtonSegment(value: 3, label: Text('3')),
          ],
          selected: {s.count},
          onSelectionChanged: (v) => _set(() => s.count = v.single),
        ),
      ],
    );
  }
}
