import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:sdui_starter/app/impl/etag_screen_loader.dart';

void main() {
  group('EtagScreenLoader', () {
    group('load', () {
      test('revalidates with If-None-Match and reuses the copy on 304',
          () async {
        final requests = <http.Request>[];
        final loader = EtagScreenLoader(
          baseUrl: 'http://s',
          appVersion: '1.0.0',
          client: MockClient((request) async {
            requests.add(request);
            if (request.headers['if-none-match'] == 'v1') {
              return http.Response('', 304);
            }
            return http.Response(
              jsonEncode({'_type': 'text', 'value': 'fresh'}),
              200,
              headers: {'etag': 'v1'},
            );
          }),
        );

        final first = await loader.load('home');
        final second = await loader.load('home');

        expect(requests, hasLength(2));
        expect(requests[0].headers.containsKey('if-none-match'), isFalse);
        expect(requests[1].headers['if-none-match'], 'v1');
        expect(second.template, first.template);
      });

      test('a 200 always replaces the cached copy', () async {
        var version = 0;
        final loader = EtagScreenLoader(
          baseUrl: 'http://s',
          client: MockClient((request) async {
            version += 1;
            return http.Response(
              jsonEncode({'_type': 'text', 'n': version}),
              200,
              headers: {'etag': 'v$version'},
            );
          }),
        );

        await loader.load('home');
        final second = await loader.load('home');
        expect(second.template['n'], 2);
      });

      test('missing etag header disables caching silently', () async {
        final requests = <http.Request>[];
        final loader = EtagScreenLoader(
          baseUrl: 'http://s',
          client: MockClient((request) async {
            requests.add(request);
            return http.Response(jsonEncode({'_type': 'text'}), 200);
          }),
        );

        await loader.load('home');
        await loader.load('home');
        expect(requests[1].headers.containsKey('if-none-match'), isFalse);
      });
    });
  });
}
