// Lightweight models for the online Bible (Free Use Bible API).
//
// The API returns each translation with its book names already localized,
// so we no longer carry parallel language columns on a single row.

/// The 39 Old Testament books by USFM id. Used to split Books into
/// Old/New Testament independently of array position or book count, so the
/// division stays correct across every translation (English, Hindi, Tamil).
const Set<String> kOldTestamentIds = {
  'GEN',
  'EXO',
  'LEV',
  'NUM',
  'DEU',
  'JOS',
  'JDG',
  'RUT',
  '1SA',
  '2SA',
  '1KI',
  '2KI',
  '1CH',
  '2CH',
  'EZR',
  'NEH',
  'EST',
  'JOB',
  'PSA',
  'PRO',
  'ECC',
  'SNG',
  'ISA',
  'JER',
  'LAM',
  'EZK',
  'DAN',
  'HOS',
  'JOL',
  'AMO',
  'OBA',
  'JON',
  'MIC',
  'NAM',
  'HAB',
  'ZEP',
  'HAG',
  'ZEC',
  'MAL',
};

/// A book of the Bible (localized name for the chosen translation).
class BibleBook {
  final String id; // USFM id, e.g. "GEN", "MAT" — stable across translations
  final String name; // localized display name for the chosen translation
  final int order; // 1-based canonical order
  final int chapterCount;

  const BibleBook({
    required this.id,
    required this.name,
    required this.order,
    required this.chapterCount,
  });

  /// True for the 39 Old Testament books; false for the 27 New Testament ones.
  bool get isOldTestament => kOldTestamentIds.contains(id);
}

class BibleVerse {
  final int number;
  final String text;

  const BibleVerse({required this.number, required this.text});
}

/// A verse-of-the-day with its localized reference (e.g. "यूहन्ना 3:16").
class DailyVerse {
  final String text;
  final String reference;

  const DailyVerse({required this.text, required this.reference});
}
