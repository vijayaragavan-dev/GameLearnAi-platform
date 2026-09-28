// API base URL + tunnel header contract.
//
// Run with:
//   flutter test test/core/api_config_test.dart
//     --dart-define=API_BASE_URL=https://idealness-esquire-upriver.ngrok-free.dev
// so AppConfig resolves against the real mobile tunnel URL.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gamelearn_app/core/config/app_config.dart';
import 'package:gamelearn_app/core/network/api_client.dart';

const _ngrokBase = 'https://idealness-esquire-upriver.ngrok-free.dev';

void main() {
  test('base URL resolution is exact and slash-safe', () {
    final base = AppConfig.apiBaseUrl;
    // In ngrok-configured runs (dart-define), the tunnel URL must
    // resolve byte-exact.
    if (base == _ngrokBase) {
      expect(AppConfig.apiBaseUrl, _ngrokBase);
      expect(
        AppConfig.resolve('/api/v1/auth/login').toString(),
        '$_ngrokBase/api/v1/auth/login',
      );
      expect(
        AppConfig.resolve('/api/v1/realms').toString(),
        '$_ngrokBase/api/v1/realms',
      );
      expect(
        AppConfig.resolve('/api/v1/progress/abc').toString(),
        '$_ngrokBase/api/v1/progress/abc',
      );
    }
    // Structural guarantees hold for every base (default or tunnel):
    // exactly one slash between base and path, path preserved.
    final resolved = AppConfig.resolve('/api/v1/auth/login').toString();
    expect(resolved, '$base/api/v1/auth/login');
    expect(resolved.contains('///'), isFalse);
  });

  test('central client sends ngrok header and preserves auth', () async {
    Map<String, String>? seenHeaders;
    Uri? seenUri;
    String? seenBody;
    final client = ApiClient(
      client: MockClient((request) async {
        seenHeaders = Map.of(request.headers);
        seenUri = request.url;
        seenBody = request.body;
        return http.Response(jsonEncode({'ok': true}), 200);
      }),
    );
    client.tokenProvider = () => 'test-token-123';

    await client.getJson('/api/v1/realms');

    expect(
      seenUri.toString(),
      '${AppConfig.apiBaseUrl}/api/v1/realms',
    );
    expect(seenHeaders!['ngrok-skip-browser-warning'], 'true');
    expect(seenHeaders!['Authorization'], 'Bearer test-token-123');
    expect(seenHeaders!['Accept'], 'application/json');
  });

  test('POST keeps JSON content type alongside tunnel header', () async {
    Map<String, String>? seenHeaders;
    final client = ApiClient(
      client: MockClient((request) async {
        seenHeaders = Map.of(request.headers);
        return http.Response(jsonEncode({'ok': true}), 200);
      }),
    );

    await client.postJson('/api/v1/auth/login', {'email': 'a@b.c'});

    expect(seenHeaders!['ngrok-skip-browser-warning'], 'true');
    expect(seenHeaders!['Content-Type'], 'application/json');
    expect(seenHeaders!.containsKey('Authorization'), isFalse);
  });
}
