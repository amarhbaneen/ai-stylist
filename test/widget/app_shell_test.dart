import 'dart:io';

import 'package:ai_stylist/app/app.dart';
import 'package:ai_stylist/core/database/app_database.dart';
import 'package:ai_stylist/core/providers.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSupportDirectoryProvider.overrideWithValue(Directory.systemTemp),
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: const AiStylistApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('starts on Home with four primary destinations', (tester) async {
    await pumpApp(tester);

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
  });

  testWidgets('switches tabs and shows each empty state', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.checkroom_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Your wardrobe is empty'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.auto_awesome_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Nothing to style yet'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();
    expect(find.text('No favorites yet'), findsOneWidget);
  });

  testWidgets('startup error screen explains the problem', (tester) async {
    await tester.pumpWidget(const StartupErrorApp());
    expect(find.textContaining('could not open its storage'), findsOneWidget);
  });
}
