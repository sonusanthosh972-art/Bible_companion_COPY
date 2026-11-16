import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import 'token_store.dart';

/// Plays text-to-speech by calling YOUR backend's `/tts` proxy (which holds the
/// OpenRouter key server-side) and streaming the returned MP3 to the speaker.
///
/// Supports a single clip ([toggle]) and a back-to-back [playSequence] that
/// auto-advances through a playlist (used by the continuous Praise recitation).
typedef _Clip = ({Uint8List bytes, String mime});

class TtsService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final TokenStore _tokens = TokenStore();
  bool _busy = false; // fetching audio for the current item
  String? _activeId; // which UI element is currently speaking
  String? _lang; // language of the current request (routes hi/ta -> Sarvam)

  // Sequence (playlist) state.
  List<String> _seq = const [];
  int _seqPos = 0;
  bool _stopped = true;
  void Function(int index)? _onSeqIndex;
  void Function()? _onSeqError;
  // Audio for the NEXT item, fetched while the current item plays (no gap).
  Future<_Clip?>? _nextClip;

  TtsService() {
    _player.onPlayerComplete.listen((_) => _onClipComplete());
  }

  bool get busy => _busy;
  String? get activeId => _activeId;
  bool isActive(String id) => _activeId == id;

  /// Current position within a running sequence (0 = first item). Meaningful
  /// only while a sequence is active.
  int get seqPos => _seqPos;
  int get seqLength => _seq.length;
  bool get inSequence => _seq.isNotEmpty;

  void _onClipComplete() {
    // Advance the sequence if one is running.
    if (!_stopped && _seq.isNotEmpty) {
      _seqPos += 1;
      if (_seqPos < _seq.length) {
        _playSeqItem();
        return;
      }
    }
    // Single clip finished, or sequence reached the end.
    _resetState();
    notifyListeners();
  }

  void _resetState() {
    _seq = const [];
    _seqPos = 0;
    _onSeqIndex = null;
    _onSeqError = null;
    _nextClip = null;
    _activeId = null;
    _busy = false;
    _stopped = true;
  }

  // Fetch that never throws — used for prefetching the next clip.
  Future<_Clip?> _tryFetch(String text) async {
    try {
      return await _fetch(text);
    } catch (_) {
      return null;
    }
  }

  Future<_Clip> _fetch(String text) async {
    final token = await _tokens.read();
    final res = await http
        .post(
          Uri.parse('${AppConfig.apiBaseUrl}/tts'),
          headers: {
            'content-type': 'application/json',
            if (token != null && token.isNotEmpty) 'authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'text': _trim(text),
            if (_lang != null) 'lang': _lang,
          }),
        )
        .timeout(const Duration(seconds: 45));
    if (res.statusCode != 200) {
      throw Exception('TTS ${res.statusCode}');
    }
    // Sarvam returns WAV (hi/ta); OpenRouter returns MP3 (en).
    final mime = res.headers['content-type']?.split(';').first.trim() ?? 'audio/mpeg';
    return (bytes: res.bodyBytes, mime: mime);
  }

  /// Speaks a single [text] in [lang] (routes Hindi/Tamil to Sarvam). Tapping
  /// the same [id] again stops it (toggle).
  Future<void> toggle(String id, String text, {String? lang}) async {
    if (_activeId == id) {
      await stop();
      return;
    }
    await stop();
    _stopped = false;
    _lang = lang;
    _busy = true;
    _activeId = id;
    notifyListeners();
    try {
      final clip = await _fetch(text);
      if (_stopped) return;
      _busy = false;
      notifyListeners();
      await _player.play(BytesSource(clip.bytes, mimeType: clip.mime));
    } catch (_) {
      _resetState();
      notifyListeners();
      rethrow;
    }
  }

  /// Plays [texts] back-to-back, auto-advancing as each finishes. [onIndex]
  /// fires as each item begins (so the UI can show what's playing); [onError]
  /// fires if a mid-sequence item fails. Throws if the very first item fails.
  Future<void> playSequence(
    String id,
    List<String> texts, {
    String? lang,
    void Function(int index)? onIndex,
    void Function()? onError,
  }) async {
    await stop();
    if (texts.isEmpty) return;
    _stopped = false;
    _lang = lang;
    _seq = List.unmodifiable(texts);
    _seqPos = 0;
    _onSeqIndex = onIndex;
    _onSeqError = onError;
    _activeId = id;
    notifyListeners();
    await _playSeqItem();
  }

  Future<void> _playSeqItem() async {
    if (_stopped || _seqPos >= _seq.length) return;
    final isFirst = _seqPos == 0;
    _onSeqIndex?.call(_seqPos);
    _busy = true;
    notifyListeners();
    try {
      // Use the prefetched clip if ready, otherwise fetch this one now.
      final pending = _nextClip;
      _nextClip = null;
      _Clip? clip = pending != null ? await pending : null;
      clip ??= await _fetch(_seq[_seqPos]);
      if (_stopped) return;
      _busy = false;
      notifyListeners();
      // Start fetching the NEXT clip while this one plays — so the following
      // praise begins instantly with no loading gap.
      final next = _seqPos + 1;
      _nextClip = next < _seq.length ? _tryFetch(_seq[next]) : null;
      await _player.play(BytesSource(clip.bytes, mimeType: clip.mime));
    } catch (_) {
      final notify = _onSeqError;
      _resetState();
      notifyListeners();
      if (isFirst) {
        rethrow; // surface immediately — nothing played yet
      } else {
        notify?.call();
      }
    }
  }

  Future<void> stop() async {
    _resetState();
    await _player.stop();
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
