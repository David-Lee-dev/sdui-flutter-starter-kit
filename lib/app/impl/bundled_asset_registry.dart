import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Registry of media assets bundled with the app.
///
/// Loaded once at boot from the AssetManifest: every file under
/// `assets/images/` and `assets/videos/` is indexed by basename so the media
/// sources can answer "is this bundled?" synchronously. When a template's
/// media src names a file that ships inside the app (`/assets/logo.png`,
/// `logo.png`), the bundled copy renders with no network round-trip; anything
/// else falls back to the server.
class BundledAssetRegistry {
  BundledAssetRegistry._();

  static final BundledAssetRegistry instance = BundledAssetRegistry._();

  /// Bundle locations indexed at [init].
  static const List<String> prefixes = ['assets/images/', 'assets/videos/'];

  Map<String, String> _bundled = const {};

  /// Indexes the bundle. Call once before `runApp`.
  Future<void> init() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    _bundled = {
      for (final key in manifest.listAssets())
        if (prefixes.any(key.startsWith)) key.split('/').last: key,
    };
  }

  /// Replaces the index for isolated tests.
  @visibleForTesting
  void seed(Map<String, String> bundled) => _bundled = Map.of(bundled);

  bool has(String filename) => _bundled.containsKey(filename);

  String pathOf(String filename) => _bundled[filename]!;

  /// Returns the basename a media src would match in the bundle, or null for
  /// srcs that cannot be bundle-relative (absolute http(s) URLs).
  static String? basenameOf(String src) {
    if (src.startsWith('http')) return null;
    final basename = src.split('/').last;
    return basename.isEmpty ? null : basename;
  }

  /// Whether [src] names a file that is actually bundled.
  bool hasUrl(String src) {
    final basename = basenameOf(src);
    return basename != null && has(basename);
  }
}
