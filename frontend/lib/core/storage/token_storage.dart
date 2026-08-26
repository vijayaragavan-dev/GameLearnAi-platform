import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// JWT lives ONLY in secure storage - never in plain preferences, never in
/// logs, never in source.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _key = 'gl_access_token';

  Future<String?> read() => _readSafe();

  Future<void> write(String token) => _storage.write(key: _key, value: token);

  Future<void> clear() => _storage.delete(key: _key);

  /// Secure storage can throw on some desktop test hosts; degrade to null.
  Future<String?> _readSafe() async {
    try {
      return await _storage.read(key: _key);
    } on Exception {
      return null;
    }
  }
}
