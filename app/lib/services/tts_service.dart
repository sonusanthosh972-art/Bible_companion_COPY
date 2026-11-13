import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import 'token_store.dart';

/// Plays text-to-speech by calling YOUR backend's `/tts` proxy (which holds the
/// OpenRouter key server-side) and streaming the returned MP3 to the speaker.
class TtsService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final TokenStore _tokens = TokenStore();
  bool _busy = false; // fetching audio
  String? _activeId; // which UI element is currently speaking

  TtsService() {
    _player.onPlayerComplete.listen((_) {
      _activeId = null;
      notifyListeners();
    });
  }

  bool get busy => _busy;
  String? get activeId => _activeId;
  bool isActive(String id) => _activeId == id;

  /// Speaks [text]. [id] lets the UI show which button is active; tapping the
  /// same id again stops playback (toggle).
  Future<void> toggle(String id, String text) async {
    if (_activeId == id) {
      await stop();
      return;
    }
    await stop();
    _busy = true;
    _activeId = id;
    notifyListeners();
    try {
      final token = await _tokens.read();
      final res = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/tts'),
            headers: {
              'content-type': 'application/json',
              if (token != null && token.isNotEmpty) 'authorization': 'Bearer $token',
            },
            body: jsonEncode({'text': _trim(text)}),
          )
          .timeout(const Duration(seconds: 45));
      if (res.statusCode != 200) {
        throw Exception('TTS ${res.statusCode}');
      }
      _busy = false;
      notifyListeners();
      await _player.play(BytesSource(res.bodyBytes, mimeType: 'audio/mpeg'));
    } catch (_) {
      _busy = false;
      _activeId = null;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _busy = false;
    _activeId = null;
    notifyListeners();
  }

  // The free model caps input length; keep requests well under it.
  String _trim(String t) => t.length > 3500 ? t.substring(0, 3500) : t;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
