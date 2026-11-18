import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../../app/routes.dart';
import '../../../shared/taxonomy_labels.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../favorites/presentation/learned_preferences_section.dart';
import '../../official_photo/presentation/official_photo_settings_section.dart';
import '../../weather/presentation/live_weather_settings_section.dart';
import '../profile_providers.dart';
import 'preferences_form.dart';

/// Edit or reset explicit style preferences (FR-01).
class PreferencesScreen extends ConsumerStatefulWidget {
  const PreferencesScreen({super.key});

  @override
  ConsumerState<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends ConsumerState<PreferencesScreen> {
  /// Local edits; `null` until the user changes something.
  StyleProfile? _draft;
  var _busy = false;

  void _show(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _save(StyleProfile profile) async {
    setState(() => _busy = true);
    final result = await ref.read(saveStyleProfileProvider).call(profile);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result.isSuccess) _draft = null;
    });
    _show(switch (result) {
      Success() => 'Preferences saved',
      Failure(:final failure) => failureMessage(failure),
    });
  }

  Future<void> _reset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset preferences?'),
        content: const Text(
          'This clears your style, colour, fit and formality choices. '
          'Your wardrobe is not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    final result = await ref.read(resetStyleProfileProvider).call();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _draft = null;
    });
    _show(switch (result) {
      Success() => 'Preferences reset',
      Failure(:final failure) => failureMessage(failure),
    });
  }

  @override
  Widget build(BuildContext context) {
    final stored = ref.watch(styleProfileProvider);
    final draft = _draft;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Style preferences'),
        actions: [
          // "choices" distinguishes this from "Reset learning" further down.
          TextButton(
            onPressed: _busy ? null : _reset,
            child: const Text('Reset choices'),
          ),
        ],
      ),
      floatingActionButton: draft == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _busy ? null : () => _save(draft),
              icon: const Icon(Icons.check),
              label: const Text('Save'),
            ),
      body: switch (stored) {
        AsyncData(:final value) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          children: [
            PreferencesForm(
              value: draft ?? value,
              onChanged: (p) => setState(() => _draft = p),
            ),
            const LearnedPreferencesSection(),
            const LiveWeatherSettingsSection(),
            const OfficialPhotoSettingsSection(),
            const Divider(height: 40),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.memory_outlined),
              title: const Text('On-device models'),
              subtitle: const Text('Optional downloads for clothing analysis'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.models),
            ),
          ],
        ),
        AsyncError(:final error) => ErrorState(
          title: 'Your preferences did not load',
          error: error,
          fallback: 'Nothing was changed. Try again, or restart the app.',
          onRetry: () => ref.invalidate(styleProfileProvider),
        ),
        _ => const LoadingState(),
      },
    );
  }
}
