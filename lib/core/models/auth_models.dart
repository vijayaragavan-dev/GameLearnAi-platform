import 'model_ids.dart';

/// AUTH-000..002 response (API Contract v1.4.0; AuthResponse record).
class AuthSession {
  const AuthSession({
    required this.token,
    required this.tokenType,
    required this.expiresInSeconds,
    required this.user,
  });

  final String token;
  final String tokenType;
  final int expiresInSeconds;
  final SessionUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final token = json['token'];
    if (token is! String || token.isEmpty) {
      throw const FormatException('AuthResponse.token missing');
    }
    final userJson = json['user'];
    if (userJson is! Map<String, dynamic>) {
      throw const FormatException('AuthResponse.user missing');
    }
    return AuthSession(
      token: token,
      tokenType: (json['tokenType'] as String?) ?? 'Bearer',
      expiresInSeconds: (json['expiresInSeconds'] as num?)?.toInt() ?? 0,
      user: SessionUser.fromJson(userJson),
    );
  }
}

class SessionUser {
  const SessionUser({
    required this.id,
    required this.email,
    required this.displayName,
  });

  final String id;
  final String email;
  final String displayName;

  factory SessionUser.fromJson(Map<String, dynamic> json) => SessionUser(
    id: uuidOf(json['id'], 'id'),
    email: (json['email'] as String?) ?? '',
    displayName: (json['displayName'] as String?) ?? 'Learner',
  );
}
