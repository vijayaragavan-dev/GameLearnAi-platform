import '../../../core/models/auth_models.dart';
import '../../../core/network/api_client.dart';

/// AUTH-000..003.
class AuthRepository {
  AuthRepository(this._client);

  final ApiClient _client;

  Future<AuthSession> login(String email, String password) async {
    final json = await _client.postJson('/api/v1/auth/login', {
      'email': email,
      'password': password,
    });
    return AuthSession.fromJson(json);
  }

  Future<AuthSession> register(
    String email,
    String password,
    String displayName,
  ) async {
    final json = await _client.postJson('/api/v1/auth/register', {
      'email': email,
      'password': password,
      'displayName': displayName,
    });
    return AuthSession.fromJson(json);
  }

  /// Session restore probe; throws UnauthorizedException on invalid tokens.
  Future<AuthSession> validate() async =>
      AuthSession.fromJson(await _client.getJson('/api/v1/auth/validate'));

  Future<void> logout() =>
      _client.postJson('/api/v1/auth/logout', null, expectBody: false);
}
