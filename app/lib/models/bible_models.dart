// Lightweight models for the online Bible (Free Use Bible API).
//
// The API returns each translation with its book names already localized,
// so we no longer carry parallel language columns on a single row.

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
