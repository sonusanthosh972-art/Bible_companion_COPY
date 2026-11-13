import 'dart:math';
import 'bible_service.dart';

typedef Reading = ({String bookId, String bookName, int chapter});

/// Builds day-by-day reading plans by evenly distributing all 1,189 Bible
/// chapters across the plan length. No bundled data — the chapter list comes
/// from the Bible API (localized book names included).
class ReadingPlanService {
  ReadingPlanService({BibleService? bible}) : _bible = bible ?? BibleService();
  final BibleService _bible;

  /// planId -> number of days
  static const Map<String, int> plans = {'1y': 365, '6m': 180, '3m': 90};

  final Map<String, List<Reading>> _flatCache = {}; // translation lang -> chapters

  Future<List<Reading>> _chapters(String lang) async {
    final cached = _flatCache[lang];
    if (cached != null) return cached;
    final books = await _bible.books(lang);
    final list = <Reading>[];
    for (final b in books) {
      for (var c = 1; c <= b.chapterCount; c++) {
        list.add((bookId: b.id, bookName: b.name, chapter: c));
      }
    }
    _flatCache[lang] = list;
    return list;
  }

  Future<int> totalChapters(String lang) async => (await _chapters(lang)).length;

  int chaptersPerDay(int totalChapters, String planId) =>
      (totalChapters / plans[planId]!).ceil();

  /// The readings scheduled for [day] (1-based) of [planId].
  Future<List<Reading>> readingsForDay(String lang, String planId, int day) async {
    final all = await _chapters(lang);
    final per = chaptersPerDay(all.length, planId);
    final start = (day - 1) * per;
    if (start >= all.length) return const [];
    final end = min(start + per, all.length);
    return all.sublist(start, end);
  }
}
