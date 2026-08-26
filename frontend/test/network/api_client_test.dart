import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gamelearn_app/core/network/api_client.dart';
import 'package:gamelearn_app/core/network/api_exception.dart';

http.Client _client(http.Response Function(http.Request) fn) =>
    MockClient((request) async => fn(request));

void main() {
  test('adds bearer token and JSON content type', () async {
    String? auth;
    String? contentType;
    final api = ApiClient(
      client: _client((request) {
        auth = request.headers['Authorization'];
        contentType = request.headers['Content-Type'];
        return http.Response(jsonEncode({'ok': true}), 200);
      }),
    );
    api.tokenProvider = () => 'tok-123';
    await api.getJson('/api/v1/dashboard');
    expect(auth, 'Bearer tok-123');

    await api.postJson('/api/v1/quiz/x/submit', {'answers': []});
    expect(contentType, contains('application/json'));
  });

  test('maps error envelope to typed exceptions', () async {
    final api = ApiClient(
      client: _client(
        (request) => http.Response(
          jsonEncode({
            'timestamp': 't',
            'status': 409,
            'errorCode': 'DATA_CONFLICT',
            'message': 'assessment baseline already established',
            'path': '/x',
            'requestId': 'r',
          }),
          409,
        ),
      ),
    );

    await expectLater(
      api.postJson('/api/v1/assessment/s/submit', {}),
      throwsA(
        isA<ConflictException>().having(
          (e) => e.message,
          'message',
          contains('baseline'),
        ),
      ),
    );
  });

  test('validation errors carry fieldErrors', () async {
    final api = ApiClient(
      client: _client(
        (request) => http.Response(
          jsonEncode({
            'status': 400,
            'errorCode': 'VALIDATION_FAILED',
            'message': 'Validation failed',
            'fieldErrors': {'question': 'must not be blank'},
          }),
          400,
        ),
      ),
    );

    try {
      await api.postJson('/api/v1/ai/tutor', {});
      fail('should throw');
    } on ValidationException catch (e) {
      expect(e.fieldError('question'), 'must not be blank');
    }
  });

  test('401 triggers onUnauthorized for protected paths only', () async {
    var fired = 0;
    final api = ApiClient(
      client: _client(
        (request) =>
            http.Response(jsonEncode({'errorCode': 'UNAUTHORIZED'}), 401),
      ),
    );
    api.onUnauthorized = () => fired++;

    await expectLater(
      api.getJson('/api/v1/dashboard'),
      throwsA(isA<UnauthorizedException>()),
    );
    expect(fired, 1);

    // Auth endpoints must not re-trigger global invalidation.
    await expectLater(
      api.getJson('/api/v1/auth/validate'),
      throwsA(isA<UnauthorizedException>()),
    );
    expect(fired, 1);
  });

  test('429 maps to RateLimitedException', () async {
    final api = ApiClient(
      client: _client(
        (request) => http.Response(
          jsonEncode({'errorCode': 'AI_RATE_LIMITED', 'message': 'slow down'}),
          429,
        ),
      ),
    );
    await expectLater(
      api.postJson('/api/v1/ai/tutor', {}),
      throwsA(isA<RateLimitedException>()),
    );
  });

  test('503 maps to AiUnavailableException', () async {
    final api = ApiClient(
      client: _client(
        (request) => http.Response(
          jsonEncode({'errorCode': 'AI_SERVICE_UNAVAILABLE'}),
          503,
        ),
      ),
    );
    await expectLater(
      api.postJson('/api/v1/ai/tutor', {}),
      throwsA(isA<AiUnavailableException>()),
    );
  });

  test('malformed JSON body -> MalformedResponseException', () async {
    final api = ApiClient(
      client: _client((request) => http.Response('<html>boom</html>', 200)),
    );
    await expectLater(
      api.getJson('/api/v1/subjects'),
      throwsA(isA<MalformedResponseException>()),
    );
  });

  test('socket failure -> NetworkException', () async {
    final api = ApiClient(
      client: MockClient(
        (request) async => throw http.ClientException('connection refused'),
      ),
    );
    await expectLater(
      api.getJson('/api/v1/dashboard'),
      throwsA(anyOf(isA<NetworkException>(), isA<ApiException>())),
    );
  });
}
