import 'package:sdui_engine/sdui_engine.dart';
import 'package:video_player/video_player.dart';

import 'bundled_asset_registry.dart';

/// App-owned [VideoSource] — bundled-first, network fallback.
///
/// Same policy as [AppImageSource]: a src bundled under assets/videos plays
/// from assets; anything else streams from the network, with
/// server-relative paths resolved against [baseUrl].
class AppVideoSource implements VideoSource {
  const AppVideoSource({required this.baseUrl});

  /// Base URL that server-relative `src` paths resolve against.
  final String baseUrl;

  @override
  Future<VideoPlayerController> controllerFor(VideoRequest request) async {
    final src = request.src;
    final registry = BundledAssetRegistry.instance;
    if (registry.hasUrl(src)) {
      return VideoPlayerController.asset(
        registry.pathOf(BundledAssetRegistry.basenameOf(src)!),
      );
    }
    final url = src.startsWith('http') ? src : '$baseUrl$src';
    return VideoPlayerController.networkUrl(Uri.parse(url));
  }
}
