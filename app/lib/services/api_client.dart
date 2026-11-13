import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config.dart';

/// Thrown for any non-2xx API response or transport failure.
class ApiException implements Exception {
  final int statusCode; // 0 == transport/no-network
  final String code;
  final String message;
  ApiException(this.statusCode, this.code, this.message);

  bool get isNetwork => statusCode == 0;

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}

/// Thin REST client for YOUR backend. A token provider is injected so the
/// client stays decoupled from storage.
class ApiClient {
  ApiClient({http.Client? httpClient, Future<String?> Function()? tokenProvider})
      : _http = httpClient ?? http.Client(),
        _tokenProvider = tokenProvider;

  final http.Client _http;
  Future<String?> Function()? _tokenProvider;

  set tokenProvider(Future<String?> Function()? provider) =>
      _tokenProvider = provider;

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = {'content-type': 'application/json'};
    if (auth && _tokenProvider != null) {
      final token = await _tokenProvider!();
      if (token != null && token.isNotEmpty) {
        headers['authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<dynamic> get(String path, {bool auth = false}) =>
      _send('GET', path, auth: auth);

  Future<dynamic> post(String path, {Object? body, bool auth = false}) =>
      _send('POST', path, body: body, auth: auth);

  Future<dynamic> put(String path, {Object? body, bool auth = false}) =>
      _send('PUT', path, body: body, auth: auth);

  Future<dynamic> _send(String method, String path,
      {Object? body, bool auth = false}) async {
    final uri = _uri(path);
    final headers = await _headers(auth: auth);
    try {
      late http.Response res;
      final future = switch (method) {
        'GET' => _http.get(uri, headers: headers),
        'POST' => _http.post(uri, headers: headers, body: jsonEncode(body)),
        'PUT' => _http.put(uri, headers: headers, body: jsonEncode(body)),
        _ => throw ArgumentError('Unsupported method $method'),
      };
      res = await future.timeout(AppConfig.apiTimeout);

      final decoded = res.body.isEmpty ? null : jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) return decoded;

      final map = decoded is Map ? decoded : const {};
      throw ApiException(
        res.statusCode,
        (map['error'] ?? 'http_error').toString(),
        (map['message'] ?? 'Request failed (${res.statusCode})').toString(),
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(0, 'timeout', 'The request timed out.');
    } catch (e) {
      throw ApiException(0, 'network', e.toString());
    }
  }

  void close() => _http.close();
}
