import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/leaderboard_entry.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/content_service.dart';
import '../services/token_store.dart';

/// Holds the backend session and synced data for the whole app. Talks to the
/// Node.js REST backend via [ApiClient]. On startup it restores a saved session
/// or silently creates a guest one, so the app is always connected.
class AppState extends ChangeNotifier {
  AppState() {
    final api = ApiClient();
    _auth = AuthService(api, TokenStore());
    _content = ContentService(api);
  }

  late final AuthService _auth;
  late final ContentService _content;

  AppUser? _user;
  bool _online = false;
  bool _booting = true;
  List<LeaderboardEntry> _leaderboard = const [];

  // Gamification / progress (mirrored to the backend's /user/progress blob).
  int _xp = 0;
  int _streak = 0;
  int _longestStreak = 0;
  String? _lastReadDay; // 'yyyy-mm-dd' of the last completed reading day
  final Map<String, List<int>> _planDays = {}; // planId -> completed day numbers
  int _quizBest = 0;
  int _progressRev = 0;

  AppUser? get user => _user;
  bool get online => _online; // backend reachable
  bool get booting => _booting;
  bool get isGuest => _user?.isGuest ?? true;
  List<LeaderboardEntry> get leaderboard => _leaderboard;

  int get xp => _xp;
  int get level => 1 + _xp ~/ 100; // 100 XP per level
  int get xpIntoLevel => _xp % 100;
  int get streak => _streak;
  int get longestStreak => _longestStreak;
  int get quizBest => _quizBest;
  List<int> completedDays(String planId) => _planDays[planId] ?? const [];
  bool isDayDone(String planId, int day) => (_planDays[planId] ?? const []).contains(day);

  /// Restore or create a session. Never throws — offline is a valid state.
  Future<void> boot({required String language}) async {
    try {
      _user = await _auth.restore();
      _user ??= await _auth.guest(language: language);
      _online = _user != null;
    } on ApiException {
      _online = false; // offline: app still works with bundled data
    } catch (_) {
      _online = false;
    }
    _booting = false;
    notifyListeners();
    // Fire-and-forget loads.
    loadProgress();
    refreshLeaderboard();
  }

  /// Pulls the synced progress blob and hydrates XP / streak / plan state.
  Future<void> loadProgress() async {
    if (_user == null) return;
    try {
      final data = await _content.progress();
      final p = (data['progress'] as Map?)?.cast<String, dynamic>() ?? {};
      _progressRev = (data['rev'] as num?)?.toInt() ?? 0;
      _xp = (p['xp'] as num?)?.toInt() ?? 0;
      _streak = (p['streak'] as num?)?.toInt() ?? 0;
      _longestStreak = (p['longestStreak'] as num?)?.toInt() ?? 0;
      _lastReadDay = p['lastReadDay'] as String?;
      _quizBest = (p['quizBest'] as num?)?.toInt() ?? 0;
      _planDays.clear();
      final plans = (p['plans'] as Map?)?.cast<String, dynamic>() ?? {};
      plans.forEach((k, v) {
        _planDays[k] = (v as List).map((e) => (e as num).toInt()).toList();
      });
      notifyListeners();
    } on ApiException {
      // offline: keep local defaults
    }
  }

  Map<String, dynamic> _progressBlob() => {
        'xp': _xp,
        'streak': _streak,
        'longestStreak': _longestStreak,
        if (_lastReadDay != null) 'lastReadDay': _lastReadDay,
        'quizBest': _quizBest,
        'plans': _planDays,
      };

  Future<void> _saveProgress() async {
    if (_user == null) return;
    try {
      _progressRev = await _content.pushProgress(_progressBlob(), rev: _progressRev);
    } on ApiException catch (e) {
      // On a revision conflict, re-pull then retry once.
      if (e.statusCode == 409) {
        await loadProgress();
        try {
          _progressRev = await _content.pushProgress(_progressBlob(), rev: _progressRev);
        } on ApiException {
          // give up silently; local state is still correct for the session
        }
      }
    }
  }

  /// Awards XP, recomputes level, syncs progress + leaderboard.
  Future<void> addXp(int amount) async {
    if (amount <= 0) return;
    _xp += amount;
    notifyListeners();
    await _saveProgress();
    try {
      await _content.reportScore(_xp, level);
      await refreshLeaderboard();
    } on ApiException {
      // offline: leaderboard updates next time we're online
    }
  }

  /// Records today's best quiz score (keeps the max).
  Future<void> recordQuizScore(int correct) async {
    if (correct > _quizBest) {
      _quizBest = correct;
      await _saveProgress();
    }
  }

  /// Marks a reading-plan day complete; updates streak once per calendar day.
  Future<void> markReadingDay(String planId, int day) async {
    final days = _planDays.putIfAbsent(planId, () => []);
    if (!days.contains(day)) days.add(day);

    final today = _todayKey();
    if (_lastReadDay != today) {
      final yesterday = _dayKey(DateTime.now().subtract(const Duration(days: 1)));
      _streak = (_lastReadDay == yesterday) ? _streak + 1 : 1;
      if (_streak > _longestStreak) _longestStreak = _streak;
      _lastReadDay = today;
    }
    notifyListeners();
    await _saveProgress();
    await addXp(10); // reading a day is worth 10 XP
  }

  String _todayKey() => _dayKey(DateTime.now());
  String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> refreshLeaderboard() async {
    try {
      _leaderboard = await _content.leaderboard();
      _online = true;
      notifyListeners();
    } on ApiException {
      // keep whatever we had
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _user = await _auth.login(email: email, password: password);
      _online = true;
      notifyListeners();
      loadProgress();
      return true;
    } on ApiException {
      return false;
    }
  }

  Future<bool> register(String email, String password, String nickname,
      String language) async {
    try {
      _user = await _auth.register(
          email: email, password: password, nickname: nickname, language: language);
      _online = true;
      notifyListeners();
      loadProgress();
      return true;
    } on ApiException {
      return false;
    }
  }

  Future<void> setNickname(String nickname) async {
    if (_user == null) return;
    try {
      _user = await _auth.updateProfile(nickname: nickname);
      notifyListeners();
      refreshLeaderboard();
    } on ApiException {
      // ignore
    }
  }

  Future<void> syncLanguage(String language) async {
    if (_user == null || !_online) return;
    try {
      _user = await _auth.updateProfile(language: language);
    } on ApiException {
      // non-fatal
    }
  }

  Future<void> signOut({required String language}) async {
    await _auth.signOut();
    // Reset gamification state for the new (guest) identity.
    _xp = 0;
    _streak = 0;
    _longestStreak = 0;
    _lastReadDay = null;
    _quizBest = 0;
    _planDays.clear();
    _progressRev = 0;
    try {
      _user = await _auth.guest(language: language);
    } on ApiException {
      _user = null;
      _online = false;
    }
    notifyListeners();
    loadProgress();
  }
}
