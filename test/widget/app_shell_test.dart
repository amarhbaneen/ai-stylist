import 'package:ai_stylist/app/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/test_app.dart';

void main() {
  testWidgets('starts on Home with four primary destinations', (tester) async {
    final app = await TestApp.create(tester);
    await app.pump(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    for (final label in ['Home', 'Wardrobe', 'Stylist', 'Favorites']) {
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }
    expect(find.text('No suggestion yet'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('switches tabs and shows each empty state', (tester) async {
    final app = await TestApp.create(tester);
    await app.pump(tester);

    await tapAndSettle(tester, find.byIcon(Icons.checkroom_outlined).last);
    expect(find.text('Your wardrobe is empty'), findsOneWidget);

    await tapAndSettle(tester, find.byIcon(Icons.auto_awesome_outlined));
    expect(find.text('Occasion'), findsOneWidget);

    await tapAndSettle(tester, find.byIcon(Icons.favorite_border));
    expect(find.text('No favorites yet'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('startup error screen explains the problem', (tester) async {
    await tester.pumpWidget(const StartupErrorApp());
    expect(find.textContaining('could not open its storage'), findsOneWidget);
  });
}
