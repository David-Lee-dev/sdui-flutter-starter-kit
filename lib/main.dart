import 'package:flutter/material.dart';
import 'package:sdui_engine/sdui_engine.dart';

import 'package:sdui_starter/app/config/env.dart';
import 'package:sdui_starter/app/impl/etag_screen_loader.dart';
import 'package:sdui_starter/app/impl/bundled_asset_registry.dart';
import 'package:sdui_starter/app/impl/device_secure_storage.dart';
import 'package:sdui_starter/app/impl/http_api_client.dart';
import 'package:sdui_starter/app/impl/image_source.dart';
import 'package:sdui_starter/app/impl/prefs_app_storage.dart';
import 'package:sdui_starter/app/impl/video_source.dart';
import 'package:sdui_starter/app/service/clipboard_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bundled-first media needs the asset index; device storage needs its
  // preferences instance. Both load once before the engine boots.
  await BundledAssetRegistry.instance.init();
  final appStorage = await PrefsAppStorage.load();

  // The engine requires an implementation for every dependency — the app
  // implements and injects all of them (lib/app/impl, guided by its README).
  // Telemetry alone defaults to the package's no-op sink.
  Sdui.initialize(
    screenLoader: EtagScreenLoader(
      baseUrl: Env.serverUrl,
      appVersion: Env.appVersion,
    ),
    apiClient: HttpApiClient(
      baseUrl: Env.serverUrl,
      appVersion: Env.appVersion,
    ),
    imageSource: const AppImageSource(baseUrl: Env.serverUrl),
    videoSource: const AppVideoSource(baseUrl: Env.serverUrl),
    appStorage: appStorage,
    secureStorage: const DeviceSecureStorage(),
    // App-added template capability — see clipboard_service.dart for the
    // full walkthrough of what a service and its commands are.
    services: const [ClipboardService()],
    debugLogLevel: LogLevel.debug,
  );

  runApp(const SduiStarterApp());
}

final class SduiStarterApp extends StatelessWidget {
  const SduiStarterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SDUI Starter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0E0E0E),
        useMaterial3: true,
      ),
      // Add app-owned routes (tab shells, pre-warmed screens, custom
      // transitions) via Sdui.router(routes: [...]).
      routerConfig: Sdui.router(),
    );
  }
}
