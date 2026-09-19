import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:sdui_engine/testing.dart';

import '../support/engine_harness.dart';

/// Mounts the example screens' *compiled output* in the real engine — proves
/// the YAML under `examples/sdui` and the compiler's golden output actually
/// render and act end-to-end.
void main() {
  // In-repo vendored copy first (works from a lone clone); fall back to the
  // sibling compiler checkout for testing against a freshly-recompiled
  // fixture without re-vendoring.
  final inRepoFixturesDir = '${Directory.current.path}/example/compiled';
  final siblingFixturesDir =
      '${Directory.current.path}/../91_sdui-template-compiler/spec/fixtures/basic/expected';
  final fixturesDir = File('$inRepoFixturesDir/manifest.json').existsSync()
      ? inRepoFixturesDir
      : siblingFixturesDir;

  test('resolves the vendored in-repo fixtures, not the sibling checkout', () {
    // Self-containment: a lone clone must resolve example/compiled, which
    // this repo vendors, never the sibling compiler checkout.
    expect(fixturesDir, inRepoFixturesDir);
  });

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
    installTestNetworkClient(
      _FakeNetworkClient({
        '/feed': {'items': feed},
        '/items/1': {
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

final class _FakeNetworkClient implements NetworkClient {
  const _FakeNetworkClient(this.responses);

  final Map<String, Object?> responses;

  @override
  Future<NetworkResult> send(NetworkRequest request) async {
    final path = request.fields['path'];
    final data = responses[path];
    if (data == null) {
      return NetworkResult(errorCode: 'NOT_FOUND', errorMessage: '$path');
    }
    return NetworkResult(data: data);
  }
}
