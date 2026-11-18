import 'package:ai_stylist/features/wardrobe/wardrobe_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/test_app.dart';

void main() {
  testWidgets('studio polish is on by default and can be turned off', (
    tester,
  ) async {
    final app = await TestApp.create(tester);
    await app.pump(tester);
    await tapAndSettle(tester, find.byTooltip('Style preferences'));
    await scrollTo(tester, find.text('Studio polish'));

    final tile = find.widgetWithText(SwitchListTile, 'Studio polish');
    expect(tester.widget<SwitchListTile>(tile).value, isTrue);

    await tapAndSettle(tester, tile);

    expect(tester.widget<SwitchListTile>(tile).value, isFalse);
    late bool stored;
    await tester.runAsync(() async {
      stored =
          (await app.container.read(studioPolishSettingsProvider).isEnabled())
              .valueOrNull!;
    });
    expect(stored, isFalse);
    await app.dispose(tester);
  });
}
