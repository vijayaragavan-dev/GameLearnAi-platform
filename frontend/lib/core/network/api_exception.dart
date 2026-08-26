/// Normalized API failure hierarchy mapped from the backend ErrorResponse
/// envelope (API Contract v1.4.0 section 2.4) and transport failures.
///
/// Never expose raw exceptions to UI; map to a safe user message instead.
sealed class ApiException implements Exception {
  const ApiException(this.message, {this.errorCode, this.statusCode});

  final String message;
  final String? errorCode;
  final int? statusCode;

  @override
  String toString() =>
      '$runtimeType(${errorCode ?? '-'}, '
      'status: ${statusCode ?? '-'}, message: $message)';
}

final class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Session expired'])
    : super(statusCode: 401, errorCode: 'UNAUTHORIZED');
}

final class ForbiddenException extends ApiException {
  const ForbiddenException([super.message = 'Not permitted'])
    : super(statusCode: 403, errorCode: 'FORBIDDEN');
}

final class ValidationException extends ApiException {
  ValidationException(
    super.message, {
    Map<String, String>? fieldErrors,
    int super.statusCode = 400,
    super.errorCode,
  }) : fieldErrors = fieldErrors ?? const <String, String>{};

  final Map<String, String> fieldErrors;

  String? fieldError(String field) => fieldErrors[field];
}

final class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Not found'])
    : super(statusCode: 404, errorCode: 'RESOURCE_NOT_FOUND');
}

final class ConflictException extends ApiException {
  const ConflictException(super.message)
    : super(statusCode: 409, errorCode: 'DATA_CONFLICT');
}

final class RateLimitedException extends ApiException {
  const RateLimitedException(super.message)
    : super(statusCode: 429, errorCode: 'AI_RATE_LIMITED');
}

final class AiUnavailableException extends ApiException {
  const AiUnavailableException([super.message = 'AI service unavailable'])
    : super(statusCode: 503, errorCode: 'AI_SERVICE_UNAVAILABLE');
}

final class ServerErrorException extends ApiException {
  const ServerErrorException([super.message = 'Server error'])
    : super(statusCode: 500, errorCode: 'INTERNAL_ERROR');
}

final class TimeoutApiException extends ApiException {
  const TimeoutApiException()
    : super('Request timed out', errorCode: 'TIMEOUT');
}

final class NetworkException extends ApiException {
  const NetworkException()
    : super('No connection to the server', errorCode: 'NETWORK');
}

final class MalformedResponseException extends ApiException {
  const MalformedResponseException([
    super.message = 'Unexpected response from server',
  ]) : super(errorCode: 'MALFORMED_RESPONSE');
}
