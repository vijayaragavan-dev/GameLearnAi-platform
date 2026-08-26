import '../network/api_exception.dart';

/// Maps exceptions onto safe, context-specific Nova-style messages.
/// Raw backend errors never reach the UI.
class UserFacingError {
  const UserFacingError(this.title, this.message, {this.retryable = true});

  final String title;
  final String message;
  final bool retryable;
}

UserFacingError describeError(Object error) {
  if (error is UnauthorizedException) {
    return const UserFacingError(
      'Signal lost',
      'Your session ended. Sign in again to resume your adventure.',
    );
  }
  if (error is ForbiddenException) {
    return const UserFacingError(
      'Access denied',
      'This area is locked for your account.',
    );
  }
  if (error is NotFoundException) {
    return const UserFacingError(
      'Nothing here',
      'This mission seems to have drifted away.',
    );
  }
  if (error is ConflictException) {
    return UserFacingError(
      'Already done',
      error.message.isEmpty
          ? 'That step was already completed.'
          : error.message,
    );
  }
  if (error is ValidationException) {
    return UserFacingError(
      'Check your input',
      error.message.isEmpty ? 'Some details need another look.' : error.message,
    );
  }
  if (error is RateLimitedException) {
    return const UserFacingError(
      'Slow down',
      'Too many requests right now. Give it a little while and try again.',
    );
  }
  if (error is AiUnavailableException) {
    return const UserFacingError(
      'Nova is offline',
      'The AI service could not be reached. Try again soon.',
    );
  }
  if (error is TimeoutApiException) {
    return const UserFacingError(
      'Signal interrupted',
      'The server took too long to respond.',
    );
  }
  if (error is NetworkException) {
    return const UserFacingError(
      "You're offline",
      "We can't reach the adventure servers. Check your connection.",
    );
  }
  return const UserFacingError(
    'Something interrupted your adventure',
    'An unexpected error occurred. Try again in a moment.',
  );
}
