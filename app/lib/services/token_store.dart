import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the auth token in the platform keystore/keychain
/// (mirrors the original app's `flutter_secure_storage` usage).
///
/// Reads are served from a process-wide in-memory cache so hot paths — every
/// text-to-speech clip, every image request, every authed API call — don't pay
/// for a platform-channel keystore round-trip each time. The cache stays correct
/// because every write goes through [save]/[clear], which update it in lock-step.
class TokenStore {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _key = 'auth_token';

  // In-memory cache. `_cached` holds the value; `_primed` tracks whether we've
  // read from storage yet (so a genuine null isn't mistaken for "not loaded").
  static String? _cached;
  static bool _primed = false;

  Future<void> save(String token) async {
    _cached = token;
    _primed = true;
    await _storage.write(key: _key, value: token);
  }

  Future<String?> read() async {
    if (_primed) return _cached;
    _cached = await _storage.read(key: _key);
    _primed = true;
    return _cached;
  }

  Future<void> clear() async {
    _cached = null;
    _primed = true;
    await _storage.delete(key: _key);
  }
}
