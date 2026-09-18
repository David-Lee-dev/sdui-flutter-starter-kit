import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:sdui_starter/app/impl/http_api_client.dart';

void main() {
  group('HttpApiClient', () {
    group('execute', () {
      test('POSTs {op, variables} to /v3/data with version headers', () async {
        final requests = <http.Request>[];
        final client = HttpApiClient(
          baseUrl: 'http://s',
          appVersion: '1.2.3',
          client: MockClient((request) async {
            requests.add(request);
            return http.Response(jsonEncode({'data': {'ok': true}}), 200);
          }),
        );

        final result = await client.execute(
          query: 'HomeFeed',
          variables: {'page': 1},
          correlationId: 'corr-1',
        );

        expect(result.data, {'ok': true});
        final request = requests.single;
        expect(request.url.path, '/v3/data');
        expect(jsonDecode(request.body), {
          'op': 'HomeFeed',
          'variables': {'page': 1},
        });
        expect(request.headers['x-app-version'], '1.2.3');
        expect(request.headers['x-correlation-id'], 'corr-1');
      });

      test('server errorCode maps to a failed ApiResult', () async {
        final client = HttpApiClient(
          baseUrl: 'http://s',
          client: MockClient(
            (request) async => http.Response(
              jsonEncode({'errorCode': 'TK0001', 'errorMessage': 'nope'}),
              200,
            ),
          ),
        );

        final result = await client.execute(query: 'Q', variables: const {});
        expect(result.errorCode, 'TK0001');
        expect(result.errorMessage, 'nope');
      });

      test('transport failure becomes a NETWORK error, never a throw',
          () async {
        final client = HttpApiClient(
          baseUrl: 'http://s',
          client: MockClient((request) async => throw Exception('down')),
        );

        final result = await client.execute(query: 'Q', variables: const {});
        expect(result.errorCode, 'NETWORK');
      });
    });
  });
}
