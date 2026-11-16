import 'package:flutter_test/flutter_test.dart';

import '../support/test_app.dart';

void main() {
  testWidgets('model manager works with no optional models and no network', (
    tester,
  ) async {
    final app = await TestApp.create(tester);
    await app.pump(tester);
    await tapAndSettle(tester, find.byTooltip('Style preferences'));
    await tapAndSettle(tester, find.text('On-device models'));

    await pumpUntil(tester, find.textContaining('No optional models'));
    expect(find.textContaining('set every detail by hand'), findsOneWidget);
    expect(app.network.requests, isEmpty);
    await app.dispose(tester);
  });
}
