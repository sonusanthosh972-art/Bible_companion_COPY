import '../models/leaderboard_entry.dart';
import 'api_client.dart';

/// Read-only content endpoints + progress sync.
class ContentService {
  ContentService(this._api);
  final ApiClient _api;

  Future<List<LeaderboardEntry>> leaderboard({String scope = 'all'}) async {
    final data = await _api.get('/content/leaderboard?scope=$scope');
    final list = (data['entries'] as List).cast<Map<String, dynamic>>();
    return list.map(LeaderboardEntry.fromJson).toList();
  }

  /// Daily-verse overrides newer than [since] (ISO string), for patching the
  /// bundled offline DB. Returns an empty list on failure (non-fatal).
  Future<List<Map<String, dynamic>>> dailyVerseEdits({String? since}) async {
    final q = since != null ? '?since=${Uri.encodeComponent(since)}' : '';
    final data = await _api.get('/content/daily-verses/edits$q');
    return (data['edits'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> progress() async {
    final data = await _api.get('/user/progress', auth: true);
    return (data as Map).cast<String, dynamic>();
  }

  /// Pushes progress with optimistic concurrency. Returns the new revision.
  Future<int> pushProgress(Map<String, dynamic> progress, {int? rev}) async {
    final data = await _api.put('/user/progress', auth: true, body: {
      'progress': progress,
      if (rev != null) 'rev': rev,
    });
    return (data['rev'] as num).toInt();
  }

  /// Reports the user's current XP + level to the leaderboard.
  Future<void> reportScore(int xp, int level) async {
    await _api.post('/leaderboard/score', auth: true, body: {'xp': xp, 'level': level});
  }
}
