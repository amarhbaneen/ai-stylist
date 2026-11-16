import 'package:ai_stylist/features/profile/profile_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../support/test_app.dart';

void main() {
  testWidgets('first launch explains privacy, saves chosen preferences', (
    tester,
  ) async {
    final app = await TestApp.create(tester, onboardingComplete: false);
    await app.pump(tester);

    expect(find.textContaining('stored only on this device'), findsOneWidget);
    expect(find.textContaining('works offline'), findsOneWidget);

    await tapAndSettle(tester, find.text('Continue'));
    expect(find.text('Your style (optional)'), findsOneWidget);

    await tapAndSettle(tester, find.text('Minimal'));
    await tapAndSettle(tester, find.text('Get started'));

    expect(find.text('No suggestion yet'), findsOneWidget, reason: 'on Home');
    final repo = app.container.read(profileRepositoryProvider);
    late Result<StyleProfile> profile;
    late Result<bool> done;
    await tester.runAsync(() async {
      profile = await repo.getProfile();
      done = await repo.isOnboardingComplete();
    });
    expect(profile.valueOrNull!.preferredStyles, {StylePreference.minimal});
    expect(done.valueOrNull, isTrue);
    await app.dispose(tester);
  });

  testWidgets('preferences can be skipped', (tester) async {
    final app = await TestApp.create(tester, onboardingComplete: false);
    await app.pump(tester);

    await tapAndSettle(tester, find.text('Continue'));
    await tapAndSettle(tester, find.text('Minimal'));
    await tapAndSettle(tester, find.text('Skip'));

    expect(find.text('No suggestion yet'), findsOneWidget);
    final repo = app.container.read(profileRepositoryProvider);
    late Result<StyleProfile> profile;
    await tester.runAsync(() async => profile = await repo.getProfile());
    expect(profile.valueOrNull!.isEmpty, isTrue, reason: 'nothing saved');
    await app.dispose(tester);
  });
}
