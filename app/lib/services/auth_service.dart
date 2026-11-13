import '../models/user.dart';
import 'api_client.dart';
import 'token_store.dart';

/// Wraps the auth endpoints and persists the session token securely.
class AuthService {
  AuthService(this._api, this._tokens) {
    _api.tokenProvider = _tokens.read;
  }

  final ApiClient _api;
  final TokenStore _tokens;

  Future<String?> currentToken() => _tokens.read();

  Future<AppUser> register({
    required String email,
    required String password,
    String? nickname,
    String language = 'en',
  }) async {
    final data = await _api.post('/auth/register', body: {
      'email': email,
      'password': password,
      if (nickname != null && nickname.isNotEmpty) 'nickname': nickname,
      'language': language,
    });
    return _handleAuth(data);
  }

  Future<AppUser> login({required String email, required String password}) async {
    final data = await _api.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    return _handleAuth(data);
  }

  Future<AppUser> guest({String language = 'en'}) async {
    final data = await _api.post('/auth/guest', body: {'language': language});
    return _handleAuth(data);
  }

  /// Loads the current user from a stored token, or null if none/invalid.
  Future<AppUser?> restore() async {
    final token = await _tokens.read();
    if (token == null || token.isEmpty) return null;
    try {
      final data = await _api.get('/user', auth: true);
      return AppUser.fromJson((data['user'] as Map).cast<String, dynamic>());
    } on ApiException catch (e) {
      if (e.statusCode == 401) await _tokens.clear();
      return null;
    }
  }

  Future<AppUser> updateProfile({
    String? nickname,
    String? avatar,
    String? language,
  }) async {
    final data = await _api.put('/user', auth: true, body: {
      if (nickname != null) 'nickname': nickname,
      if (avatar != null) 'avatar': avatar,
      if (language != null) 'language': language,
    });
    return AppUser.fromJson((data['user'] as Map).cast<String, dynamic>());
  }

  Future<void> signOut() => _tokens.clear();

  Future<AppUser> _handleAuth(dynamic data) async {
    final token = data['token'] as String;
    await _tokens.save(token);
    return AppUser.fromJson((data['user'] as Map).cast<String, dynamic>());
  }
}
