import 'package:flutter/widgets.dart';
import 'package:sdui_engine/sdui_engine.dart';

import 'bundled_asset_registry.dart';

/// App-owned [ImageSource] — bundled-first, network fallback.
///
/// Resolution order:
/// 1. **Bundled asset** — a src whose basename (`/assets/logo.png`) is in
///    the app bundle renders from [BundledAssetRegistry] with no network.
/// 2. **Network** — anything else loads over HTTP with the engine's loading
///    polish (fade-in + shimmer placeholder, exported by the package);
///    server-relative paths resolve against [baseUrl].
class AppImageSource implements ImageSource {
  const AppImageSource({required this.baseUrl});

  /// Base URL that server-relative `src` paths resolve against.
  final String baseUrl;

  @override
  ImageResult resolve(ImageRequest r) {
    final src = r.src;
    if (src.isEmpty) return const NoImage();

    final registry = BundledAssetRegistry.instance;
    if (registry.hasUrl(src)) {
      final path = registry.pathOf(BundledAssetRegistry.basenameOf(src)!);
      return ReadyImage(
        Image.asset(
          path,
          width: r.width,
          height: r.height,
          fit: r.fit,
          color: r.color,
          alignment: r.alignment ?? Alignment.center,
          colorBlendMode: r.colorBlendMode,
          repeat: r.repeat ?? ImageRepeat.noRepeat,
          semanticLabel: r.semanticLabel,
          cacheWidth: r.cacheWidth,
          cacheHeight: r.cacheHeight,
          errorBuilder: r.error == null ? null : (ctx, e, st) => r.error!,
        ),
      );
    }

    final url = src.startsWith('http') ? src : '$baseUrl$src';
    return ReadyImage(
      Image.network(
        url,
        width: r.width,
        height: r.height,
        fit: r.fit,
        color: r.color,
        alignment: r.alignment ?? Alignment.center,
        colorBlendMode: r.colorBlendMode,
        repeat: r.repeat ?? ImageRepeat.noRepeat,
        semanticLabel: r.semanticLabel,
        cacheWidth: r.cacheWidth,
        cacheHeight: r.cacheHeight,
        frameBuilder: fadeInImageFrame,
        loadingBuilder: (ctx, child, progress) => loadingImageTransition(
          loaded: progress == null,
          placeholder:
              r.loading ?? shimmerPlaceholder(width: r.width, height: r.height),
          image: child,
        ),
        errorBuilder: r.error == null ? null : (ctx, e, st) => r.error!,
      ),
    );
  }
}
