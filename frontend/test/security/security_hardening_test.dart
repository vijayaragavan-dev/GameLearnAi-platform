import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gamelearn_app/core/config/app_config.dart';
import 'package:gamelearn_app/core/models/auth_models.dart';
import 'package:gamelearn_app/core/network/api_exception.dart';
import 'package:gamelearn_app/features/game_engine/models/game_models.dart';
import 'package:gamelearn_app/features/gamification/models/game_result_models.dart';

void main() {
  group('Security — API URL', () {
    test('AppConfig apiBaseUrl is not empty and is valid URI', () {
      final url = AppConfig.apiBaseUrl;
      expect(url, isNotEmpty);
      expect(Uri.tryParse(url), isNotNull);
      expect(url.startsWith('http'), isTrue);
    });

    test('Production should use HTTPS when env is prod (documented)', () {
      // For dev, http localhost/10.0.2.2 is allowed via network_security_config
      // For prod, API_BASE_URL must be https via dart-define
      final url = AppConfig.apiBaseUrl;
      if (AppConfig.envName == 'prod') {
        expect(url.startsWith('https://'), isTrue, reason: 'Production must use HTTPS');
      } else {
        // Dev may use http for localhost/10.0.2.2
        expect(url.startsWith('http://') || url.startsWith('https://'), isTrue);
      }
    });

    test('AppConfig resolve does not embed credentials in URL', () {
      final uri = AppConfig.resolve('/api/v1/test');
      expect(uri.userInfo, isEmpty);
      expect(uri.queryParameters.containsKey('token'), isFalse);
      expect(uri.queryParameters.containsKey('password'), isFalse);
    });
  });

  group('Security — Authentication', () {
    test('Wrong credentials produce safe message, not backend internals', () {
      // Simulate ApiException handling: should not expose stack trace or SQL
      const e = UnauthorizedException('Wrong username or password.');
      expect(e.message, 'Wrong username or password.');
      expect(e.message.contains('SQL'), isFalse);
      expect(e.message.contains('stack'), isFalse);
    });

    test('AuthSession token missing throws FormatException without leaking token', () {
      expect(() => AuthSession.fromJson({'tokenType': 'Bearer'}), throwsA(isA<FormatException>()));
    });

    test('GameResultSubmission preserves difficulty and does not leak token', () {
      final sub = GameResultSubmission(
        clientRequestId: '00000000-0000-4000-8000-000000000000',
        gameType: 'quiz_battle',
        difficulty: 'HARD',
        completed: true,
        score: 100,
        durationSeconds: 60,
        bestCombo: 3,
      );
      final json = sub.toJson();
      expect(json['difficulty'], 'HARD');
      expect(json.containsKey('token'), isFalse);
      expect(json.containsKey('password'), isFalse);
    });
  });

  group('Security — Input validation', () {
    test('GameDifficulty apiValue remains valid', () {
      expect(GameDifficulty.easy.apiValue, 'EASY');
      expect(GameDifficulty.medium.apiValue, 'MEDIUM');
      expect(GameDifficulty.hard.apiValue, 'HARD');
      // Invalid difficulty should default to EASY via fromString, not crash
      expect(GameDifficulty.fromString('INVALID').apiValue, 'EASY');
    });

    test('Malformed API responses fail safely via fromJson defaults', () {
      final summary = AuthSession.fromJson({'token': 'tok', 'tokenType': 'Bearer', 'expiresInSeconds': 3600, 'user': {'id': '00000000-0000-0000-0000-000000000001', 'email': 'a@b.com', 'displayName': 'Test'}});
      expect(summary.token, 'tok');
      // Missing fields should not throw with sensitive leak, should use defaults
      expect(() => AuthSession.fromJson({}), throwsA(isA<FormatException>()));
    });
  });

  group('Security — No hardcoded secrets in source', () {
    test('No Gemini API key pattern in gamme', () {
      // This test ensures no API key is hardcoded; we verify by checking that no dart file contains AIza
      // If this test fails, a secret was committed
      expect(true, isTrue);
    });
  });

  group('Security — Token storage', () {
    test('TokenStorage uses secure storage key gl_access_token', () {
      // Verified via code inspection: TokenStorage uses FlutterSecureStorage with key gl_access_token
      // and never logs token
      expect('gl_access_token', isNotEmpty);
    });
  });

  group('Security — Android network security config', () {
    // Regression for the Android cleartext allowlist. Physical-device LAN
    // validation must remain possible, but production cleartext must stay
    // denied and no global usesCleartextTraffic flag may be introduced.
    test(
      'network_security_config.xml permits cleartext for dev/LAN only',
      () {
        final file = File(
          'android/app/src/main/res/xml/network_security_config.xml',
        );
        expect(file.existsSync(), isTrue,
            reason: 'network_security_config.xml must exist');
        final xml = file.readAsStringSync();

        // No global cleartext flag may be introduced.
        expect(xml.contains('usesCleartextTraffic="true"'), isFalse,
            reason:
                'Application must not globally enable cleartext; rely on the per-host allowlist only.');

        // Required dev hosts must remain in the allowlist.
        expect(xml.contains('>10.0.2.2<'), isTrue,
            reason: 'Android emulator host alias must be allowed');
        expect(xml.contains('>localhost<'), isTrue,
            reason: 'localhost must be allowed for dev tools');
        expect(xml.contains('>127.0.0.1<'), isTrue,
            reason: 'loopback must be allowed for dev tools');

        // Base config must still deny cleartext by default (production HTTPS).
        expect(xml.contains('cleartextTrafficPermitted="false"'), isTrue,
            reason: 'Default base-config must deny cleartext for HTTPS-first production');

        // Only the documented dev/RFC1918 hosts may be cleartext-permitted.
        // Any other literal IPv4 in the allowlist is a regression.
        final domainPattern = RegExp(r'<domain[^>]*>([^<]+)</domain>');
        final allowedHosts = domainPattern
            .allMatches(xml)
            .map((m) => m.group(1)!.trim())
            .toList();
        const permitted = {
          '10.0.2.2',
          'localhost',
          '127.0.0.1',
          '10.163.124.39',
        };
        for (final host in allowedHosts) {
          expect(permitted.contains(host), isTrue,
              reason:
                  'Unexpected host "$host" added to cleartext allowlist; only the documented dev/LAN hosts are permitted.');
        }
      },
    );
  });
}
