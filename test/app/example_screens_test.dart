import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:sdui_engine/testing.dart';

import '../support/engine_harness.dart';

/// Mounts the example screens' *compiled output* in the real engine — proves
/// the YAML under `examples/sdui` and the compiler's golden output actually
/// render and act end-to-end.
void main() {
  final fixturesDir =
      '${Directory.current.path}/../91_sdui-starter/spec/fixtures/basic/expected';

  Map<String, Object?> loadTemplate(String screen) {
    final raw = File(
      '$fixturesDir/screens/$screen/1.0.0.json',
    ).readAsStringSync();
    return (jsonDecode(raw) as Map).cast<String, Object?>();
  }

  final feed = [
    {'id': 1, 'emoji': '🚀', 'title': 'Server-driven UI', 'subtitle': 'a'},
    {'id': 2, 'emoji': '🧩', 'title': 'Components & tokens', 'subtitle': 'b'},
  ];

  setUp(() {
    installTestApiClient(
      _FakeApiClient({
        'HomeFeed': {'items': feed},
        'ItemDetail': {
          'item': {
            'id': 1,
            'emoji': '🚀',
            'title': 'Server-driven UI',
            'description': 'desc',
          },
        },
      }),
    );
  });

  tearDown(DriverRegistry.reset);

  testWidgets('home renders the feed and navigates on row tap', (tester) async {
    final pushed = <String>[];
    await pumpEngineTemplate(
      tester,
      loadTemplate('home'),
      navigate: NavigateHandle(
        push: (location) async {
          pushed.add(location);
          return null;
        },
        go: (_) {},
        pop: ([_]) {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Today's picks"), findsOneWidget);
    expect(find.text('Server-driven UI'), findsOneWidget);
    expect(find.text('Components & tokens'), findsOneWidget);

    await tester.tap(find.text('Server-driven UI'));
    await tester.pumpAndSettle();
    expect(pushed, ['/screens/detail?id=1']);
  });

  testWidgets('detail loads by the id route parameter', (tester) async {
    await pumpEngineTemplate(
      tester,
      loadTemplate('detail'),
      rootData: const {'id': '1'},
    );
    await tester.pumpAndSettle();

    expect(find.text('Server-driven UI'), findsOneWidget);
    expect(find.text('desc'), findsOneWidget);
    expect(find.text('Item id: 1'), findsOneWidget);
  });
}

final class _FakeApiClient implements ApiClient {
  const _FakeApiClient(this.responses);

  final Map<String, Object?> responses;

  @override
  Future<ApiResult> execute({
    required String query,
    required Map<String, Object?> variables,
    String? correlationId,
  }) async {
    final data = responses[query];
    if (data == null) {
      return ApiResult(errorCode: 'UNKNOWN_OP', errorMessage: query);
    }
    return ApiResult(data: data);
  }
}
