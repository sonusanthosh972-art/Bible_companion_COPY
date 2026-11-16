// Curated verse references per emotion (USFM book ids).
// Verse *text* is fetched live from the Bible API in the user's language, so
// this map stays tiny and works for English, Tamil and Hindi alike.

/// (bookId, chapter, verse)
typedef VerseRef = (String, int, int);

const Map<String, List<VerseRef>> kEmotionVerses = {
  'peace': [
    ('JHN', 14, 27), ('PHP', 4, 7), ('ISA', 26, 3), ('PSA', 29, 11), ('COL', 3, 15),
  ],
  'hope': [
    ('JER', 29, 11), ('ROM', 15, 13), ('ROM', 5, 5), ('PSA', 39, 7), ('HEB', 11, 1),
  ],
  'strength': [
    ('ISA', 40, 31), ('PHP', 4, 13), ('PSA', 46, 1), ('ISA', 41, 10), ('2CO', 12, 9),
  ],
  'fear': [
    ('ISA', 41, 10), ('2TI', 1, 7), ('PSA', 34, 4), ('JOS', 1, 9), ('PSA', 27, 1),
  ],
  'healing': [
    ('JER', 17, 14), ('PSA', 147, 3), ('ISA', 53, 5), ('EXO', 15, 26), ('JAS', 5, 15),
  ],
  'joy': [
    ('PSA', 16, 11), ('NEH', 8, 10), ('JHN', 15, 11), ('ROM', 15, 13), ('PSA', 30, 5),
  ],
  'love': [
    ('1CO', 13, 4), ('JHN', 3, 16), ('ROM', 8, 38), ('1JN', 4, 19), ('1JN', 4, 7),
  ],
  'wisdom': [
    ('PRO', 3, 5), ('JAS', 1, 5), ('PRO', 2, 6), ('PSA', 111, 10), ('PRO', 9, 10),
  ],
  'trust': [
    ('PRO', 3, 5), ('PSA', 56, 3), ('PSA', 37, 5), ('ISA', 26, 4), ('PSA', 9, 10),
  ],
  'grief': [
    ('PSA', 34, 18), ('MAT', 5, 4), ('REV', 21, 4), ('PSA', 147, 3), ('2CO', 1, 3),
  ],
  'forgiveness': [
    ('1JN', 1, 9), ('EPH', 4, 32), ('COL', 3, 13), ('MAT', 6, 14), ('PSA', 103, 12),
  ],
  'worry': [
    ('MAT', 6, 34), ('PHP', 4, 6), ('1PE', 5, 7), ('MAT', 6, 25), ('PSA', 55, 22),
  ],
  'anxiety': [
    ('PHP', 4, 6), ('1PE', 5, 7), ('PSA', 94, 19), ('MAT', 11, 28), ('ISA', 41, 10),
  ],
};

/// Wholesome, nature-focused stock-image search terms per emotion. Sent to the
/// backend image proxy; chosen to stay peaceful, spiritual and non-figurative.
// Broad (2–3 word) nature terms so Wikimedia returns many candidates — the
// detail page shows a different one per verse. Keep them wholesome/scenic.
const Map<String, String> kEmotionImageQuery = {
  'peace': 'calm lake mountains',
  'hope': 'sunrise sky clouds',
  'strength': 'mountain landscape',
  'fear': 'peaceful nature landscape',
  'healing': 'forest sunlight path',
  'joy': 'sunset golden sky',
  'love': 'warm sunset sky',
  'wisdom': 'mountain landscape sky',
  'trust': 'forest sunlight path',
  'grief': 'still water reflection',
  'forgiveness': 'sunrise sky clouds',
  'worry': 'ocean sea calm',
  'anxiety': 'still water reflection',
};

/// Each emotion maps to one of three instrumental music moods, served by the
/// backend at /v1/music/<mood>.mp3 and looped softly behind the verses.
const Map<String, String> kEmotionMood = {
  'peace': 'calm',
  'trust': 'calm',
  'healing': 'calm',
  'grief': 'calm',
  'worry': 'calm',
  'anxiety': 'calm',
  'forgiveness': 'calm',
  'fear': 'calm',
  'hope': 'hopeful',
  'joy': 'hopeful',
  'love': 'hopeful',
  'strength': 'strong',
  'wisdom': 'strong',
};
