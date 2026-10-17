import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

/// Build-time configuration. The backend URL is never hardcoded per
/// environment; it is injected via --dart-define at build/run time.
///
/// A runtime override (Settings → Backend Base URL) is supported for
/// device testing against a tunnel; it is persisted in SharedPreferences
/// and never replaces the compile-time contract when unset.
abstract final class AppConfig {
  static const String _envUrl = String.fromEnvironment('API_BASE_URL');
  static const String _overridePrefKey = 'custom_backend_url';
  static String? _overrideUrl;

  static String get apiBaseUrl {
    final override = _overrideUrl;
    if (override != null && override.isNotEmpty) return override;
    if (_envUrl.isNotEmpty) return _envUrl;
    if (kIsWeb) return 'http://localhost:8080';
    return 'http://10.0.2.2:8080';
  }

  /// Sets the in-memory runtime override; empty/null clears it.
  /// Trailing slashes are normalized so resolution never yields '//'.
  static void setOverrideUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      _overrideUrl = null;
      return;
    }
    var trimmed = url.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    _overrideUrl = trimmed.isEmpty ? null : trimmed;
  }

  /// Restores a persisted runtime override, if one was saved.
  static Future<void> loadRuntimeOverride() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setOverrideUrl(prefs.getString(_overridePrefKey));
    } catch (_) {
      // Storage unavailable — compile-time configuration stands.
    }
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
