import 'package:flutter/foundation.dart' show kIsWeb;

/// Build-time configuration. The backend URL is never hardcoded per
/// environment; it is injected via --dart-define at build/run time.
abstract final class AppConfig {
  static const String _envUrl = String.fromEnvironment('API_BASE_URL');
  static String get apiBaseUrl {
    if (_envUrl.isNotEmpty) return _envUrl;
    if (kIsWeb) return 'http://localhost:8080';
    return 'http://10.0.2.2:8080';
  }

  /// Human-readable environment tag shown only on the settings screen.
  static const String envName = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static Uri resolve(String path, {Map<String, String>? query}) {
    // Dart-define values may or may not end with '/'; repository paths
    // always start with '/'. Normalize so resolution never yields '//'.
    var base = apiBaseUrl;
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    return Uri.parse('$base$path').replace(queryParameters: query);
  }
}
