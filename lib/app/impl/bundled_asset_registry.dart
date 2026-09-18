import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Registry of media assets bundled with the app.
///
/// Loaded once at boot from the AssetManifest: every file under
/// `assets/images/` and `assets/videos/` is indexed by hashed basename so the
/// media sources can answer "is this bundled?" synchronously. Templates send
/// hashed asset URLs (`/assets/a1b2c3d4.png`); a bundled copy is used
/// directly, anything else falls back to the server — ship the popular assets
/// inside the app and the screen renders without a network round-trip.
class BundledAssetRegistry {
  BundledAssetRegistry._();

  static final BundledAssetRegistry instance = BundledAssetRegistry._();

  /// Bundle locations indexed at [init].
  static const List<String> prefixes = ['assets/images/', 'assets/videos/'];

  /// Hashed-filename match, both shapes templates use:
  ///   bare:      `abc12345.png`
  ///   prefixed:  `/assets/abc12345.png`
  /// Capture group 1 = basename (`abc12345.png`).
  static final RegExp _hashedAssetPattern = RegExp(
    r'^(?:/assets/)?([0-9a-f]{8}\.[a-zA-Z0-9]+)$',
  );

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

  /// Returns the hashed basename when [url] points at a hash asset, else null.
  static String? hashedFilename(String url) =>
      _hashedAssetPattern.firstMatch(url)?.group(1);

  /// Whether [url] points at a hash asset that is actually bundled.
  bool hasUrl(String url) {
    final filename = hashedFilename(url);
    return filename != null && has(filename);
  }
}
