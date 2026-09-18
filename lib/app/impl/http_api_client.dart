import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:sdui_engine/sdui_engine.dart';

/// App-owned [ApiClient] — named data operations over plain HTTP.
///
/// The engine has NO default data plane: `Sdui.initialize` requires an
/// [ApiClient], and this is this app's. The `api` command is
/// transport-agnostic (`query` is just an operation name); this
/// implementation posts it to `POST <baseUrl>/v3/data` as `{ op, variables }`
/// and expects `{ data }` or `{ errorCode, errorMessage }`. Speak GraphQL or
/// any other protocol by writing a different [ApiClient] — templates never
/// change.
final class HttpApiClient implements ApiClient {
  HttpApiClient({required this.baseUrl, this.appVersion, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;

  /// Sent as `x-app-version` when set.
  final String? appVersion;

  final http.Client _client;

  @override
  Future<ApiResult> execute({
    required String query,
    required Map<String, Object?> variables,
    String? correlationId,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/v3/data'),
        headers: {
          'content-type': 'application/json',
          'x-app-version': ?appVersion,
          'x-correlation-id': ?correlationId,
        },
        body: jsonEncode({'op': query, 'variables': variables}),
      );

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is! Map) {
        return ApiResult(
          errorCode: 'BAD_PAYLOAD',
          errorMessage: 'unexpected payload for $query',
        );
      }
      final errorCode = body['errorCode'];
      if (errorCode is String) {
        return ApiResult(
          errorCode: errorCode,
          errorMessage: body['errorMessage'] as String?,
        );
      }
      if (response.statusCode >= 400) {
        return ApiResult(
          errorCode: 'HTTP_${response.statusCode}',
          errorMessage: 'request for $query failed',
        );
      }
      return ApiResult(data: body['data']);
    } catch (error) {
      return ApiResult(errorCode: 'NETWORK', errorMessage: '$error');
    }
  }
}
