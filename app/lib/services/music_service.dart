import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config.dart';

/// Soft, looping background music for the emotion pages. Streams an instrumental
/// track (by mood) from the backend's /music endpoint. Starts playing by
/// default; the user can mute/unmute, and the choice is remembered.
class MusicService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  static const double _volume = 0.35; // gentle, sits under the narration
  static const _prefKey = 'music_muted';

  bool _muted = false;
  bool _loaded = false;
  String? _mood;

  bool get muted => _muted;

  MusicService() {
    _player.setReleaseMode(ReleaseMode.loop);
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _muted = prefs.getBool(_prefKey) ?? false;
    } catch (_) {
      _muted = false;
    }
    _loaded = true;
    notifyListeners();
  }

  /// Starts (or switches to) the track for [mood]. No-op if already on it.
  Future<void> playMood(String mood) async {
    if (!_loaded) await _load();
    if (_mood == mood && _player.state == PlayerState.playing) return;
    _mood = mood;
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(_muted ? 0 : _volume);
      await _player.play(
        UrlSource('${AppConfig.apiBaseUrl}/music/$mood.mp3'),
        volume: _muted ? 0 : _volume,
      );
    } catch (_) {
      // No track available yet — stay silent; the toggle still works.
    }
    notifyListeners();
  }

  Future<void> toggleMute() async {
    _muted = !_muted;
    try {
      await _player.setVolume(_muted ? 0 : _volume);
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, _muted);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> stop() async {
    _mood = null;
    try {
      await _player.stop();
    } catch (_) {}
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
