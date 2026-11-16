import 'package:ai_stylist/core/database/app_database.dart';
import 'package:ai_stylist/features/profile/data/drift_profile_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../support/fakes.dart';

void main() {
  late AppDatabase db;
  late DriftProfileRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftProfileRepository(database: db, clock: FixedClock());
  });
  tearDown(() => db.close());

  test('a fresh install has an empty profile and no onboarding', () async {
    expect((await repo.getProfile()).valueOrNull, StyleProfile.empty);
    expect((await repo.isOnboardingComplete()).valueOrNull, isFalse);
  });

  test('saves, updates and resets explicit preferences', () async {
    final profile = StyleProfile(
      preferredStyles: {StylePreference.minimal, StylePreference.classic},
      favoredColors: {ColorFamily.navy},
      avoidedColors: {ColorFamily.orange},
      fit: GarmentFit.relaxed,
      formality: Formality.smartCasual,
    );

    await repo.saveProfile(profile);
    expect((await repo.getProfile()).valueOrNull, profile);

    final updated = StyleProfile(favoredColors: {ColorFamily.green});
    await repo.saveProfile(updated);
    expect((await repo.getProfile()).valueOrNull, updated);
    expect(await db.select(db.userProfile).get(), hasLength(1));

    await repo.resetProfile();
    expect((await repo.getProfile()).valueOrNull, StyleProfile.empty);
  });

  test('unknown stored codes are dropped, not crashed on', () async {
    await db
        .into(db.userProfile)
        .insert(
          UserProfileCompanion.insert(
            id: DriftProfileRepository.profileId,
            preferredStyles: const Value('["MINIMAL","FUTURE_STYLE"]'),
            favoredColors: const Value('not json'),
            createdAt: 0,
            updatedAt: 0,
          ),
        );
    final profile = (await repo.getProfile()).valueOrNull!;
    expect(profile.preferredStyles, {StylePreference.minimal});
    expect(profile.favoredColors, isEmpty);
  });

  test('onboarding completion persists', () async {
    await repo.markOnboardingComplete();
    await repo.markOnboardingComplete(); // idempotent
    expect((await repo.isOnboardingComplete()).valueOrNull, isTrue);
  });
}
