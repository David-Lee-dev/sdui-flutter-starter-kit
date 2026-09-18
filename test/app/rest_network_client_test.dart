import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sdui_engine/sdui_engine.dart';

import 'package:sdui_starter/app/impl/rest_network_client.dart';

void main() {
  group('RestNetworkClient', () {
    RestNetworkClient client({
      required Future<http.Response> Function(http.Request) handler,
    }) => RestNetworkClient(
      baseUrl: 'http://s',
      appVersion: '1.2.3',
      client: MockClient(handler),
    );

    NetworkRequest request(Map<String, Object?> fields) =>
        NetworkRequest(fields: fields, correlationId: 'cid-1');

    group('send', () {
      test('path만으로 GET을 보내고 data를 돌려준다', () async {
        late http.Request seen;
        final result = await client(
          handler: (r) async {
            seen = r;
            return http.Response(jsonEncode({'data': {'items': []}}), 200);
          },
        ).send(request({'path': '/feed'}));

        expect(seen.method, 'GET');
        expect(seen.url.toString(), 'http://s/feed');
        expect(seen.headers['x-app-version'], '1.2.3');
        expect(seen.headers['x-correlation-id'], 'cid-1');
        expect(result.data, {'items': []});
        expect(result.errorCode, isNull);
      });

      test('params는 쿼리 스트링이 된다', () async {
        late http.Request seen;
        await client(
          handler: (r) async {
            seen = r;
            return http.Response(jsonEncode({'data': {}}), 200);
          },
        ).send(request({
          'path': '/items/7',
          'params': {'expand': 'full', 'limit': 5},
        }));

        expect(seen.url.path, '/items/7');
        expect(seen.url.queryParameters, {'expand': 'full', 'limit': '5'});
      });

      test('method와 body — GET이 아니면 body를 JSON으로 보낸다', () async {
        late http.Request seen;
        await client(
          handler: (r) async {
            seen = r;
            return http.Response(jsonEncode({'data': {}}), 200);
          },
        ).send(request({
          'path': '/notes',
          'method': 'post',
          'body': {'text': 'hi'},
        }));

        expect(seen.method, 'POST');
        expect(jsonDecode(seen.body), {'text': 'hi'});
      });

      test('path가 없으면 BAD_REQUEST로 실패한다 (호출 없음)', () async {
        var calls = 0;
        final result = await client(
          handler: (r) async {
            calls++;
            return http.Response('{}', 200);
          },
        ).send(request({'method': 'GET'}));

        expect(result.errorCode, 'BAD_REQUEST');
        expect(calls, 0);
      });

      test('서버 errorCode 봉투는 그대로 전달된다', () async {
        final result = await client(
          handler: (r) async => http.Response(
            jsonEncode({'errorCode': 'DUP', 'errorMessage': 'no'}),
            200,
          ),
        ).send(request({'path': '/feed'}));

        expect(result.errorCode, 'DUP');
        expect(result.errorMessage, 'no');
      });

      test('4xx/5xx는 HTTP_<status>로 실패한다', () async {
        final result = await client(
          handler: (r) async => http.Response(jsonEncode({}), 503),
        ).send(request({'path': '/feed'}));

        expect(result.errorCode, 'HTTP_503');
      });

      test('전송 실패는 NETWORK로 보고한다', () async {
        final result = await client(
          handler: (r) async => throw Exception('down'),
        ).send(request({'path': '/feed'}));

        expect(result.errorCode, 'NETWORK');
      });
    });
  });
}
