import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:sdui_engine/sdui_engine.dart';

/// App-owned [NetworkClient] — traditional REST request fields, straight
/// from the template.
///
/// The engine's `net` command is transport-blind: it forwards the command's
/// fields verbatim and this client defines what they mean. This
/// implementation reads the classic four —
///
/// ```yaml
/// _type: net
/// method: GET                  # optional, GET by default
/// path: '/items/${id}'         # required; ${} interpolation happens upstream
/// params: { expand: full }     # optional query string
/// body: { text: hi }           # optional JSON body (non-GET)
/// _then: [{ _type: set, detail: '${data.item}' }]
/// ```
///
/// — so a template author reads a screen and sees the actual endpoint.
/// Prefer op-name indirection (templates say `op: HomeFeed`, the app owns
/// URLs), or GraphQL/gRPC? Write a different [NetworkClient]: the request
/// vocabulary is the client's own, not the engine's.
final class RestNetworkClient implements NetworkClient {
  RestNetworkClient({
    required this.baseUrl,
    this.appVersion,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;

  /// Sent as `x-app-version` when set.
  final String? appVersion;

  final http.Client _client;

  @override
  Future<NetworkResult> send(NetworkRequest request) async {
    final path = request.fields['path'];
    if (path is! String || path.isEmpty) {
      return const NetworkResult(
        errorCode: 'BAD_REQUEST',
        errorMessage: 'net command needs a non-empty "path"',
      );
    }
    final method = switch (request.fields['method']) {
      null => 'GET',
      final String m when m.isNotEmpty => m.toUpperCase(),
      final other => '$other',
    };
    final rawParams = request.fields['params'];
    final params = rawParams is Map
        ? rawParams.map((k, v) => MapEntry('$k', '$v'))
        : const <String, String>{};

    try {
      final uri = Uri.parse(
        '$baseUrl$path',
      ).replace(queryParameters: params.isEmpty ? null : params);
      final headers = {
        'content-type': 'application/json',
        'x-app-version': ?appVersion,
        'x-correlation-id': ?request.correlationId,
      };
      final body = request.fields['body'];
      final httpRequest = http.Request(method, uri)..headers.addAll(headers);
      if (body != null && method != 'GET') {
        httpRequest.body = jsonEncode(body);
      }
      final response = await http.Response.fromStream(
        await _client.send(httpRequest),
      );

      final payload = jsonDecode(utf8.decode(response.bodyBytes));
      if (payload is! Map) {
        return NetworkResult(
          errorCode: 'BAD_PAYLOAD',
          errorMessage: 'unexpected payload for $method $path',
        );
      }
      final errorCode = payload['errorCode'];
      if (errorCode is String) {
        return NetworkResult(
          errorCode: errorCode,
          errorMessage: payload['errorMessage'] as String?,
        );
      }
      if (response.statusCode >= 400) {
        return NetworkResult(
          errorCode: 'HTTP_${response.statusCode}',
          errorMessage: 'request for $method $path failed',
        );
      }
      return NetworkResult(data: payload['data']);
    } catch (error) {
      return NetworkResult(errorCode: 'NETWORK', errorMessage: '$error');
    }
  }
}
