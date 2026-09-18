import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_engine/sdui_engine.dart';

import 'package:sdui_starter/app/impl/bundled_asset_registry.dart';
import 'package:sdui_starter/app/impl/image_source.dart';

void main() {
  setUp(() => BundledAssetRegistry.instance.seed(const {}));
  tearDown(() => BundledAssetRegistry.instance.seed(const {}));

  group('BundledAssetRegistry', () {
    group('hashedFilename', () {
      test('accepts bare and /assets/-prefixed hash names only', () {
        expect(
          BundledAssetRegistry.hashedFilename('/assets/abc12345.png'),
          'abc12345.png',
        );
        expect(
          BundledAssetRegistry.hashedFilename('abc12345.png'),
          'abc12345.png',
        );
        expect(
          BundledAssetRegistry.hashedFilename('https://x.com/abc12345.png'),
          isNull,
        );
        expect(BundledAssetRegistry.hashedFilename('/assets/logo.png'), isNull);
      });
    });

    group('hasUrl', () {
      test('true only for hash urls present in the bundle index', () {
        BundledAssetRegistry.instance.seed(const {
          'abc12345.png': 'assets/images/abc12345.png',
        });
        expect(BundledAssetRegistry.instance.hasUrl('/assets/abc12345.png'),
            isTrue);
        expect(BundledAssetRegistry.instance.hasUrl('/assets/deadbeef.png'),
            isFalse);
      });
    });
  });

  group('AppImageSource', () {
    group('resolve', () {
      test('빈 src는 NoImage', () {
        expect(
          const AppImageSource(baseUrl: 'http://s')
              .resolve(const ImageRequest(src: '')),
          isA<NoImage>(),
        );
      });

      test('번들에 있는 해시 src는 asset으로 렌더한다 (네트워크 없음)', () {
        BundledAssetRegistry.instance.seed(const {
          'abc12345.png': 'assets/images/abc12345.png',
        });
        final result = const AppImageSource(baseUrl: 'http://s')
            .resolve(const ImageRequest(src: '/assets/abc12345.png'))
            as ReadyImage;
        final image = result.image as Image;
        expect(image.image, isA<AssetImage>());
        expect(
          (image.image as AssetImage).assetName,
          'assets/images/abc12345.png',
        );
      });

      test('번들에 없으면 네트워크 폴백 — 상대 경로는 baseUrl에 붙는다', () {
        final result = const AppImageSource(baseUrl: 'http://s')
            .resolve(const ImageRequest(src: '/assets/deadbeef.png'))
            as ReadyImage;
        final image = result.image as Image;
        expect(image.image, isA<NetworkImage>());
        expect(
          (image.image as NetworkImage).url,
          'http://s/assets/deadbeef.png',
        );
        // 네트워크 경로에서만 로딩 폴리시(shimmer)가 붙는다.
        expect(image.loadingBuilder, isNotNull);
      });

      test('절대 URL은 그대로 네트워크로 간다', () {
        final result = const AppImageSource(baseUrl: 'http://s')
            .resolve(const ImageRequest(src: 'https://cdn.x.com/a.png'))
            as ReadyImage;
        expect(
          ((result.image as Image).image as NetworkImage).url,
          'https://cdn.x.com/a.png',
        );
      });
    });
  });
}
