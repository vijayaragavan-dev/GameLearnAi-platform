/// Build-time configuration. The backend URL is never hardcoded per
/// environment; it is injected via --dart-define at build/run time.
abstract final class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  /// Human-readable environment tag shown only on the settings screen.
  static const String envName = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static Uri resolve(String path, {Map<String, String>? query}) =>
      Uri.parse('$apiBaseUrl$path').replace(queryParameters: query);
}
