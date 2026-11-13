import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bible_models.dart';

/// Thrown when the Bible API is unreachable or returns an error.
class BibleException implements Exception {
  final String message;
  BibleException(this.message);
  @override
  String toString() => 'BibleException: $message';
}

/// Online Bible backed by the Free Use Bible API (https://bible.helloao.org).
///
/// No API key required. One translation is wired per app language:
///   • English → BSB      (Berean Standard Bible, public domain)
///   • Tamil   → tam_irv   (Tamil Indian Revised Version)
///   • Hindi   → hin_cvb   (Biblica® Hindi Contemporary Version — clean, modern
///                          Hindi without the inline study-footnotes that the
///                          Hindi IRV text bakes into some verses)
///
/// Book ids (GEN, EXO, … MAT) are identical across translations, so switching
/// language only swaps the translation — navigation state stays valid.
class BibleService {
  BibleService({http.Client? client}) : _http = client ?? http.Client();

  static const _base = 'https://bible.helloao.org/api';
  static const _timeout = Duration(seconds: 20);

  final http.Client _http;

  // In-memory caches so re-opening a book/chapter is instant and offline-safe
  // within a session. Static so every screen's BibleService shares one cache —
  // the books list (and any opened chapter) is fetched once app-wide.
  static final Map<String, List<BibleBook>> _booksCache = {};
  static final Map<String, List<BibleVerse>> _chapterCache = {};

  /// Well-known verses cycled by day-of-year for the home screen.
  static const _dailyRefs = <(String, int, int)>[
    ('JHN', 3, 16), ('PSA', 23, 1), ('PHP', 4, 13), ('ROM', 8, 28),
    ('JER', 29, 11), ('PRO', 3, 5), ('ISA', 41, 10), ('MAT', 6, 33),
    ('PSA', 46, 1), ('JOS', 1, 9), ('PHP', 4, 6), ('ROM', 12, 2),
    ('2CO', 5, 7), ('PSA', 118, 24), ('1CO', 13, 4), ('GAL', 2, 20),
    ('HEB', 11, 1), ('PSA', 37, 4), ('MAT', 11, 28), ('ISA', 40, 31),
  ];

  String translationFor(String lang) => switch (lang) {
        'hi' => 'hin_cvb',
        'ta' => 'tam_irv',
        _ => 'BSB',
      };

  Future<Map<String, dynamic>> _getJson(String path) async {
    try {
      final res = await _http.get(Uri.parse('$_base$path')).timeout(_timeout);
      if (res.statusCode != 200) {
        throw BibleException('Server returned ${res.statusCode}');
      }
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } on BibleException {
      rethrow;
    } catch (_) {
      throw BibleException('No internet connection');
    }
  }

  /// All 66 books for the given app language, in canonical order.
  Future<List<BibleBook>> books(String lang) async {
    final t = translationFor(lang);
    final cached = _booksCache[t];
    if (cached != null) return cached;

    final data = await _getJson('/$t/books.json');
    final list = (data['books'] as List?) ?? const [];
    final books = <BibleBook>[];
    for (var i = 0; i < list.length; i++) {
      final b = list[i] as Map<String, dynamic>;
      books.add(BibleBook(
        id: b['id'] as String,
        name: (b['commonName'] ?? b['name'] ?? b['id']) as String,
        order: i + 1,
        chapterCount: (b['numberOfChapters'] as num?)?.toInt() ?? 1,
      ));
    }
    _booksCache[t] = books;
    return books;
  }

  /// Verses of a chapter for the given app language.
  Future<List<BibleVerse>> chapterVerses(
      String lang, String bookId, int chapter) async {
    final t = translationFor(lang);
    final key = '$t/$bookId/$chapter';
    final cached = _chapterCache[key];
    if (cached != null) return cached;

    final data = await _getJson('/$t/$bookId/$chapter.json');
    final content = ((data['chapter'] as Map?)?['content'] as List?) ?? const [];
    final verses = <BibleVerse>[];
    for (final item in content) {
      if (item is Map && item['type'] == 'verse') {
        verses.add(BibleVerse(
          number: (item['number'] as num?)?.toInt() ?? 0,
          text: _joinText(item['content'] as List? ?? const []),
        ));
      }
    }
    _chapterCache[key] = verses;
    return verses;
  }

  /// Flattens a verse's content list into plain text, skipping footnote markers.
  String _joinText(List content) {
    final buf = StringBuffer();
    for (final seg in content) {
      if (seg is String) {
        buf.write(seg);
      } else if (seg is Map && seg['text'] is String) {
        // Word/poetry segments carry 'text'; footnote refs ({noteId:..}) don't.
        buf.write(seg['text']);
      }
    }
    return buf.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// A single verse with its localized reference (e.g. for emotion lists).
  Future<({String text, String reference})?> verseAt(
      String lang, String bookId, int chapter, int verse) async {
    final t = translationFor(lang);
    try {
      final data = await _getJson('/$t/$bookId/$chapter.json');
      final bookName = ((data['book'] as Map?)?['name'] as String?) ?? bookId;
      final content =
          ((data['chapter'] as Map?)?['content'] as List?) ?? const [];
      for (final item in content) {
        if (item is Map && item['type'] == 'verse' && item['number'] == verse) {
          return (
            text: _joinText(item['content'] as List? ?? const []),
            reference: '$bookName $chapter:$verse',
          );
        }
      }
    } catch (_) {
      // swallowed; caller treats null as "unavailable"
    }
    return null;
  }

  /// Today's verse (by day-of-year) in the requested language, with reference.
  Future<DailyVerse?> dailyVerse(int dayOfYear, String lang) async {
    final (book, chapter, verse) = _dailyRefs[dayOfYear % _dailyRefs.length];
    final t = translationFor(lang);
    try {
      final data = await _getJson('/$t/$book/$chapter.json');
      final bookName = ((data['book'] as Map?)?['name'] as String?) ?? book;
      final content =
          ((data['chapter'] as Map?)?['content'] as List?) ?? const [];
      for (final item in content) {
        if (item is Map && item['type'] == 'verse' && item['number'] == verse) {
          return DailyVerse(
            text: _joinText(item['content'] as List? ?? const []),
            reference: '$bookName $chapter:$verse',
          );
        }
      }
    } catch (_) {
      // Offline or API error → caller shows a fallback message.
    }
    return null;
  }

  void dispose() => _http.close();
}
