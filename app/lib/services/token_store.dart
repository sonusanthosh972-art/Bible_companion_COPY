import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the auth token in the platform keystore/keychain
/// (mirrors the original app's `flutter_secure_storage` usage).
class TokenStore {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _key = 'auth_token';

  Future<void> save(String token) => _storage.write(key: _key, value: token);
  Future<String?> read() => _storage.read(key: _key);
  Future<void> clear() => _storage.delete(key: _key);
}
