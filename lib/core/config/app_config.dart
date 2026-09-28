import 'package:flutter/foundation.dart' show kIsWeb;

/// Build-time and runtime configuration for backend API connectivity.
/// The backend URL can be configured via:
/// 1. `--dart-define-from-file=.env` or `--dart-define=API_BASE_URL=...`
/// 2. In-app runtime override saved in SharedPreferences
/// 3. Default fallback to active backend tunnel or localhost
abstract final class AppConfig {
  static const String _envUrl = String.fromEnvironment('API_BASE_URL');
  static String? _overrideUrl;

  /// Active default remote backend tunnel URL
  static const String defaultRemoteUrl =
      'https://idealness-esquire-upriver.ngrok-free.dev';

  /// Set runtime override for backend URL.
  /// Automatically strips trailing slashes and trims whitespace.
  static void setOverrideUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      _overrideUrl = null;
    } else {
      var trimmed = url.trim();
      while (trimmed.endsWith('/')) {
        trimmed = trimmed.substring(0, trimmed.length - 1);
      }
      _overrideUrl = trimmed;
    }
  }

  /// Returns the sanitized, single-slash normalized base URL.
  static String get apiBaseUrl {
    if (_overrideUrl != null && _overrideUrl!.isNotEmpty) {
      return _overrideUrl!;
    }
    if (_envUrl.isNotEmpty) {
      var trimmed = _envUrl.trim();
      while (trimmed.endsWith('/')) {
        trimmed = trimmed.substring(0, trimmed.length - 1);
      }
      return trimmed;
    }
    return defaultRemoteUrl;
  }

  /// Human-readable environment tag shown on the settings screen.
  static const String envName = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  /// Resolves an API path against [apiBaseUrl].
  /// Guarantees exact single slash between base URL and endpoint path,
  /// preventing double-slash 404s or missing-slash failures.
  /// Automatically includes ngrok bypass query parameters if tunneling through ngrok.
  static Uri resolve(String path, {Map<String, String>? query}) {
    final base = apiBaseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final queryParams = <String, String>{
      if (query != null) ...query,
      if (base.contains('ngrok')) 'ngrok-skip-browser-warning': '69420',
    };
    final uri = Uri.parse('$base$cleanPath');
    return queryParams.isEmpty ? uri : uri.replace(queryParameters: queryParams);
  }
}
