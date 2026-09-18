import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sdui_engine/sdui_engine.dart';

final class _CachedScreen {
  const _CachedScreen(this.screen, this.etag);
  final LoadedScreen screen;
  final String etag;
}

/// Custom [ScreenLoader] adding etag revalidation on top of the default
/// protocol — the package default fetches fresh every time; caching policy is
/// the app's freedom, and this is the canonical example of taking it.
///
/// Keeps the server's `etag` per screen in memory and sends it back as
/// `If-None-Match`; a `304` answer reuses the cached copy without
/// transferring or re-parsing the body. Injected at boot:
///
/// ```dart
/// Sdui.initialize(serverUrl: ..., screenLoader: EtagScreenLoader(...));
/// ```
final class EtagScreenLoader implements ScreenLoader {
  EtagScreenLoader({
    required this.baseUrl,
    this.appVersion,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;

  /// Sent as `x-app-version` when set.
  final String? appVersion;

  final http.Client _client;
  final _cache = <String, _CachedScreen>{};

  @override
  Future<LoadedScreen> load(String screenId) async {
    final cached = _cache[screenId];
    final response = await _client.get(
      Uri.parse('$baseUrl/screens/$screenId'),
      headers: {
        'x-app-version': ?appVersion,
        if (cached != null) 'if-none-match': cached.etag,
      },
    );

    if (response.statusCode == 304 && cached != null) return cached.screen;
    if (response.statusCode != 200) {
      throw Exception('screen "$screenId": HTTP ${response.statusCode}');
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is! Map) {
      throw Exception('screen "$screenId": unexpected payload');
    }
    final template = body.map((key, value) => MapEntry(key.toString(), value));
    final rawModals = template.remove('_modals');
    final modals = rawModals is Map
        ? rawModals.map((key, value) => MapEntry(key.toString(), value))
        : const <String, Object?>{};

    final screen = (template: template, modals: modals);
    final etag = response.headers['etag'];
    if (etag != null && etag.isNotEmpty) {
      _cache[screenId] = _CachedScreen(screen, etag);
    }
    return screen;
  }
}
