import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../../app/routes.dart';
import '../../../shared/taxonomy_labels.dart';
import '../../profile/presentation/preferences_form.dart';
import '../../profile/profile_providers.dart';

/// First launch: privacy explanation, then optional preferences (§6.1).
/// No account, gender, location or camera permission is requested here.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  var _page = 0;
  var _profile = StyleProfile.empty;
  var _saving = false;

  Future<void> _finish({required bool savePreferences}) async {
    setState(() => _saving = true);
    final result = await ref
        .read(completeOnboardingProvider)
        .call(profile: savePreferences ? _profile : null);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Success():
        context.go(AppRoutes.home);
      case Failure(:final failure):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failureMessage(failure))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _page == 0
            ? _PrivacyPage(onContinue: () => setState(() => _page = 1))
            : _PreferencesPage(
                profile: _profile,
                saving: _saving,
                onChanged: (p) => setState(() => _profile = p),
                onSkip: () => _finish(savePreferences: false),
                onDone: () => _finish(savePreferences: true),
              ),
      ),
    );
  }
}

class _PrivacyPage extends StatelessWidget {
  const _PrivacyPage({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Text('Welcome to AI Stylist', style: text.headlineMedium),
          const SizedBox(height: 16),
          const _Point(
            icon: Icons.phone_android,
            text:
                'Your photos, wardrobe and preferences are stored only on '
                'this device. There is no account and nothing is uploaded.',
          ),
          const _Point(
            icon: Icons.wifi_off,
            text:
                'Everything works offline. The internet is only used if you '
                'later choose live weather or an optional model download.',
          ),
          const _Point(
            icon: Icons.edit_outlined,
            text:
                'You stay in control: every detail about a garment can be '
                'edited.',
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onContinue,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class _PreferencesPage extends StatelessWidget {
  const _PreferencesPage({
    required this.profile,
    required this.saving,
    required this.onChanged,
    required this.onSkip,
    required this.onDone,
  });

  final StyleProfile profile;
  final bool saving;
  final ValueChanged<StyleProfile> onChanged;
  final VoidCallback onSkip;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Your style (optional)',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'These help rank outfit ideas. You can skip this and change '
                'it any time from Home.',
              ),
              PreferencesForm(value: profile, onChanged: onChanged),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Row(
            children: [
              TextButton(
                onPressed: saving ? null : onSkip,
                child: const Text('Skip'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: saving ? null : onDone,
                child: const Text('Get started'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
