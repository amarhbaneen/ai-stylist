import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/taxonomy_labels.dart';
import '../official_photo_providers.dart';

/// Opt-in for automatic official photos (Google Cloud Vision) and the
/// user's own API key, in Style preferences (DECISIONS D-43).
class OfficialPhotoSettingsSection extends ConsumerWidget {
  const OfficialPhotoSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(officialPhotoStateProvider).value;
    final notifier = ref.read(officialPhotoStateProvider.notifier);
    final text = Theme.of(context).textTheme;
    final enabled = state?.enabled ?? false;
    final hasKey = state?.hasKey ?? false;

    void report(Result<void> r) {
      if (r case Failure(:final failure)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failureMessage(failure))));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: Space.xxxl),
        Text('Official photos', style: text.titleMedium),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Find official photos automatically'),
          subtitle: const Text(
            'After the background is removed, the garment cut-out is sent '
            'to Google Cloud Vision to find the product photo. Never your '
            'face or room.',
          ),
          value: enabled,
          onChanged: state == null
              ? null
              : (on) async {
                  if (on && !await _askConsent(context)) return;
                  report(await notifier.setEnabled(enabled: on));
                },
        ),
        if (enabled)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(hasKey ? Icons.key_outlined : Icons.key_off_outlined),
            title: Text(hasKey ? 'API key saved' : 'Add your API key'),
            subtitle: Text(
              hasKey
                  ? 'Stored encrypted on this phone.'
                  : 'Needed before the app can search.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final key = await _ApiKeySheet.show(context, hasKey: hasKey);
              if (key == null) return;
              report(await notifier.setApiKey(key.isEmpty ? null : key));
            },
          ),
      ],
    );
  }

  static Future<bool> _askConsent(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Find official photos?'),
          content: const SingleChildScrollView(
            child: Text(
              'When you add a garment, the app sends its cut-out to Google '
              'Cloud Vision (vision.googleapis.com) with your own API key, '
              'then downloads the closest product photos from the shops '
              'that show them.\n\n'
              'Sent to Google: the garment cut-out on white, and your IP '
              'address. Shops see your IP address when their photos are '
              'downloaded.\n\n'
              'Never sent: your original photo, your face, your wardrobe or '
              'preferences.\n\n'
              'Google handles the image under its Cloud terms. The first '
              '1,000 searches a month are free; beyond that Google bills '
              'your account. Turn this off any time.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Turn on'),
            ),
          ],
        ),
      ) ??
      false;
}

/// Enter, replace or remove the API key. Returns the new key, `''` to
/// remove it, or `null` when cancelled.
class _ApiKeySheet extends StatefulWidget {
  const _ApiKeySheet({required this.hasKey});

  final bool hasKey;

  static Future<String?> show(BuildContext context, {required bool hasKey}) =>
      showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        builder: (context) => _ApiKeySheet(hasKey: hasKey),
      );

  @override
  State<_ApiKeySheet> createState() => _ApiKeySheetState();
}

class _ApiKeySheetState extends State<_ApiKeySheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.page,
        0,
        Space.page,
        MediaQuery.viewInsetsOf(context).bottom + Space.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Google Cloud API key', style: text.headlineSmall),
          const SizedBox(height: Space.sm),
          Text(
            'In Google Cloud Console: create a project, enable the Cloud '
            'Vision API, then create an API key. Restrict it to the Cloud '
            'Vision API and to the Android app dev.placeholder.ai_stylist.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: Space.lg),
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: widget.hasKey ? 'New API key' : 'API key',
            ),
          ),
          const SizedBox(height: Space.lg),
          FilledButton(
            onPressed: () {
              final key = _controller.text.trim();
              if (key.isNotEmpty) Navigator.pop(context, key);
            },
            child: const Text('Save key'),
          ),
          if (widget.hasKey) ...[
            const SizedBox(height: Space.sm),
            TextButton(
              onPressed: () => Navigator.pop(context, ''),
              child: const Text('Remove saved key'),
            ),
          ],
        ],
      ),
    );
  }
}
