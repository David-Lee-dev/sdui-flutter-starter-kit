import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sdui_engine/sdui_engine.dart';

import 'package:sdui_starter/app/impl/etag_screen_loader.dart';
import 'package:sdui_starter/app/impl/device_secure_storage.dart';
import 'package:sdui_starter/app/impl/image_source.dart';
import 'package:sdui_starter/app/impl/video_source.dart';

/// Compile-level contract: the four customization points the starter promises
/// must all be expressible through the package's public API (the barrel
/// import above — no deep imports needed).

// ── 1. Custom ApiClient (replace the HTTP data plane) ──────────────────────
final class MyGraphqlApiClient implements ApiClient {
  @override
  Future<ApiResult> execute({
    required String query,
    required Map<String, Object?> variables,
    String? correlationId,
  }) async => const ApiResult(data: {'ok': true});
}

// ── 2. Platform capability as a service (templates call { _type: sys_clipboard })
final class ClipboardCommand implements ExternalCommand {
  @override
  String get type => 'sys_clipboard';

  @override
  Future<Object?> run(CommandInvocation invocation) async => null;
}

// ── 3. Vendor integration bundling its commands ────────────────────────────
final class SupportChatService extends SduiService {
  @override
  List<ExternalCommand> get commands => [ClipboardCommand(), _ChatCommand()];

  @override
  void onRegister() {
    // SDK initialization goes here.
  }
}

final class _ChatCommand implements ExternalCommand {
  @override
  String get type => 'support_chat';

  @override
  Future<Object?> run(CommandInvocation invocation) async => null;
}

// ── 4. Pre-registered screen with a pre-warmed template ────────────────────
final class PrewarmedHomePage extends StatelessWidget {
  const PrewarmedHomePage({super.key, required this.screen});

  final LoadedScreen screen;

  @override
  Widget build(BuildContext context) => EngineRunner(
    screenId: 'home',
    template: screen.template,
    modalTemplates: screen.modals,
  );
}

final class _FakeAppStorage implements AppStorage {
  final _values = <String, Object?>{};
  @override
  Object? get(String key) => _values[key];
  @override
  Future<void> set(String key, Object? value) async => _values[key] = value;
}

void main() {
  test('all four customization points compile against the public API', () {
    // Boot-time seams: the required dependency implementations plus a
    // vendor service contributing template-callable commands.
    void boot(LoadedScreen prewarmed) {
      Sdui.initialize(
        screenLoader: EtagScreenLoader(baseUrl: 'http://localhost:1'),
        apiClient: MyGraphqlApiClient(),
        imageSource: const AppImageSource(baseUrl: 'http://localhost:1'),
        videoSource: const AppVideoSource(baseUrl: 'http://localhost:1'),
        appStorage: _FakeAppStorage(),
        secureStorage: const DeviceSecureStorage(),
        services: [SupportChatService()],
      );
      // Router-time seams: a dedicated route in front of the generic one,
      // reusing either a custom page or the stock SduiScreenPage.
      Sdui.router(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => PrewarmedHomePage(screen: prewarmed),
          ),
          GoRoute(
            path: '/promo',
            pageBuilder: (context, state) => CustomTransitionPage(
              transitionsBuilder: (context, animation, secondary, child) =>
                  FadeTransition(opacity: animation, child: child),
              child: SduiScreenPage(
                screenId: 'promo',
                loader: Sdui.screenLoader,
              ),
            ),
          ),
        ],
      );
    }

    expect(boot, isA<void Function(LoadedScreen)>());
  });
}
