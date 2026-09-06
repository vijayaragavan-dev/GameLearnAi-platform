import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_exception.dart';

/// Single HTTP entry point. Adds base URL, JSON headers, bearer token and
/// timeout; normalizes every failure into [ApiException]. Request logging is
/// dev-only and NEVER logs authorization material or bodies with secrets.
class ApiClient {
  ApiClient({
    http.Client? client,
    Duration timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client(),
       _timeout = timeout;

  final http.Client _client;
  final Duration _timeout;

  String Function()? _tokenProvider;
  void Function()? _onUnauthorized;

  /// Wired by the session provider; returns null when signed out.
  set tokenProvider(String Function()? provider) => _tokenProvider = provider;

  /// Invoked once when any endpoint answers 401, so the session can be
  /// invalidated and the router can redirect to sign-in.
  set onUnauthorized(void Function()? callback) => _onUnauthorized = callback;

  /// Endpoints whose own 401 must not trigger global invalidation.
  static const Set<String> _authPaths = {
    '/api/v1/auth/login',
    '/api/v1/auth/register',
    '/api/v1/auth/validate',
  };

  Map<String, String> _headers({bool jsonBody = false}) {
    final h = <String, String>{'Accept': 'application/json'};
    if (jsonBody) h['Content-Type'] = 'application/json';
    final token = _tokenProvider?.call();
    if (token != null && token.isNotEmpty) h['Authorization'] = 'Bearer $token';
    return h;
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
    Duration? timeout,
  }) async => _runJson(
    'GET',
    path,
    () => _client
        .get(AppConfig.resolve(path, query: query), headers: _headers())
        .timeout(timeout ?? _timeout),
  );

  /// [timeout] lets long-running AI endpoints (PATH-002 budget ~45s,
  /// AI-001 ~35s server-side incl. one approved retry) exceed the default
  /// 15s without weakening timeouts everywhere else.
  Future<Map<String, dynamic>> postJson(
    String path,
    Object? body, {
    bool expectBody = true,
    Duration? timeout,
  }) => _runJson('POST', path, () {
    final uri = AppConfig.resolve(path);
    final effectiveTimeout = timeout ?? _timeout;
    return body == null
        ? _client.post(uri, headers: _headers()).timeout(effectiveTimeout)
        : _client
              .post(
                uri,
                headers: _headers(jsonBody: true),
                body: jsonEncode(body),
              )
              .timeout(effectiveTimeout);
  }).then((value) => expectBody ? value : <String, dynamic>{});

  Future<List<dynamic>> getList(
    String path, {
    Map<String, String>? query,
  }) async {
    final response = await _guard(
      () => _client
          .get(AppConfig.resolve(path, query: query), headers: _headers())
          .timeout(_timeout),
      requestPath: path,
    );
    final decoded = _decodeBody(response);
    if (decoded is! List) throw const MalformedResponseException();
    return decoded;
  }

  Future<Map<String, dynamic>> _runJson(
    String method,
    String path,
    Future<http.Response> Function() send,
  ) async {
    final response = await _guard(send, requestPath: path);
    if (response.statusCode == 204) return <String, dynamic>{};
    final decoded = _decodeBody(response);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const MalformedResponseException();
  }

  Object? _decodeBody(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const MalformedResponseException();
    }
  }

  Future<http.Response> _guard(
    Future<http.Response> Function() send, {
    String requestPath = '',
  }) async {
    http.Response response;
    try {
      response = await send();
    } on http.ClientException {
      throw const NetworkException();
    } on TimeoutException {
      throw const TimeoutApiException();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw const NetworkException();
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }
    final error = _errorFrom(response);
    if (error is UnauthorizedException && !_authPaths.contains(requestPath)) {
      _onUnauthorized?.call();
    }
    throw error;
  }

  /// Maps the backend ErrorResponse envelope onto the exception hierarchy.
  ApiException _errorFrom(http.Response response) {
    String code = '';
    String message = '';
    Map<String, String>? fieldErrors;
    try {
      if (response.body.isNotEmpty) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body is Map<String, dynamic>) {
          code = (body['errorCode'] as String?) ?? '';
          message = (body['message'] as String?) ?? '';
          final fe = body['fieldErrors'];
          if (fe is Map<String, dynamic>) {
            fieldErrors = fe.map((k, v) => MapEntry(k, v.toString()));
          }
        }
      }
    } on FormatException {
      // fall through to generic handling below
    }
    switch (response.statusCode) {
      case 400:
        if (fieldErrors != null && fieldErrors.isNotEmpty) {
          return ValidationException(
            message.isEmpty ? 'Check your input' : message,
            fieldErrors: fieldErrors,
            errorCode: code.isEmpty ? 'VALIDATION_FAILED' : code,
          );
        }
        return ValidationException(
          message.isEmpty ? 'Invalid request' : message,
          errorCode: code.isEmpty ? 'MALFORMED_REQUEST' : code,
        );
      case 401:
        return UnauthorizedException(
          message.isEmpty ? 'Session expired' : message,
        );
      case 402:
        return InsufficientCreditsException(
          message.isEmpty ? 'Not enough credits' : message,
        );
      case 403:
        if (code == 'AVATAR_REQUIREMENTS_NOT_MET') {
          return RequirementsNotMetException(
            message.isEmpty ? 'Requirements not met' : message,
          );
        }
        return ForbiddenException(message.isEmpty ? 'Not permitted' : message);
      case 404:
        return NotFoundException(message.isEmpty ? 'Not found' : message);
      case 409:
        return ConflictException(message.isEmpty ? 'Conflict' : message);
      case 429:
        return RateLimitedException(
          message.isEmpty ? 'Too many requests' : message,
        );
      case 503:
        return AiUnavailableException(
          message.isEmpty ? 'AI service unavailable' : message,
        );
      default:
        return ServerErrorException(
          message.isEmpty ? 'Something went wrong' : message,
        );
    }
  }

  void dispose() => _client.close();
}
