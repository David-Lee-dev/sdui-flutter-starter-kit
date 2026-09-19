import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:sdui_starter/main.dart' as app;

/// On-device end-to-end: boots the real app against a running example server
/// (`node scripts/serve_example.mjs` — or any server exposing the same
/// screens) and walks the home -> detail flow through real HTTP,
/// real engine, real gestures.
///
/// Run on a simulator/emulator:
/// ```sh
/// flutter test integration_test -d <device-id>
/// ```
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home feed loads from the server and a row opens its detail', (
    tester,
  ) async {
    await app.main();
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // Home: server template rendered, feed rows arrived over the net command.
    expect(find.text("Today's picks"), findsOneWidget);
    expect(find.text('Server-driven UI'), findsOneWidget);

    // Tap the first row: `_on tap -> open_detail -> navigate` with the loop
    // item id as the event payload, landing on /screens/detail?id=1.
    await tester.tap(find.text('Server-driven UI'));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // Detail: the id query parameter reached root state, ItemDetail loaded.
    expect(find.text('Item id: 1'), findsOneWidget);
    expect(
      find.textContaining('Screens are YAML'),
      findsOneWidget,
    ); // item 1's description, served by ItemDetail
    expect(find.text('Detail'), findsOneWidget);
  });
}
