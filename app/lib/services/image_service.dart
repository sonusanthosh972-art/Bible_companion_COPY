import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import 'token_store.dart';

/// A stock image with attribution, returned by the backend image proxy.
class SectionImage {
  const SectionImage({
    required this.url,
    this.photographer,
    this.photographerUrl,
    required this.source,
    this.license,
  });

  final String url;
  final String? photographer;
  final String? photographerUrl;
  final String source; // "Pexels", "Unsplash" or "Wikimedia Commons"
  final String? license; // e.g. "CC BY 2.0" (Wikimedia)

  factory SectionImage.fromJson(Map<String, dynamic> j) => SectionImage(
        url: j['url'] as String,
        photographer: j['photographer'] as String?,
        photographerUrl: j['photographerUrl'] as String?,
        source: (j['source'] as String?) ?? 'Pexels',
        license: j['license'] as String?,
      );

  /// A compact credit line suitable for a small overlay.
  String get credit {
    final who = (photographer != null && photographer!.isNotEmpty)
        ? photographer
        : source;
    final lic = (license != null && license!.isNotEmpty) ? ' · $license' : '';
    return 'Photo: $who$lic · $source';
  }
}

/// Fetches section/emotion background images from YOUR backend proxy (which
/// holds the Pexels/Unsplash keys and caches results). A per-session memory
/// cache avoids repeat requests; the backend and `cached_network_image` add
/// server-side and on-disk caching on top.
class ImageService {
  final TokenStore _tokens = TokenStore();
  static final Map<String, SectionImage?> _cache = {};

  Future<SectionImage?> forQuery(String query, {String orientation = 'portrait'}) async {
    final key = '$orientation:$query';
    if (_cache.containsKey(key)) return _cache[key];
    try {
      final token = await _tokens.read();
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/images').replace(
        queryParameters: {'query': query, 'orientation': orientation},
      );
      final res = await http.get(
        uri,
        headers: {
          if (token != null && token.isNotEmpty) 'authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final img = SectionImage.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
        _cache[key] = img;
        return img;
      }
    } catch (_) {
      // ignore — caller falls back to a gradient
    }
    _cache[key] = null; // remember the miss for this session
    return null;
  }
}
