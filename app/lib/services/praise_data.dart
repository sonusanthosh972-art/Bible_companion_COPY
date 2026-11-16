import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// One praise statement from the bundled dataset.
class PraiseItem {
  const PraiseItem(this.id, this.text);
  final int id;
  final String text;
}

/// Loads the "1000 Praises of God" datasets bundled as assets. Text is local,
/// so selecting a count and starting a recitation is instant — no network is
/// used to fetch the praise words (only the text-to-speech audio is online).
class PraiseData {
  PraiseData._();

  static final Map<String, List<PraiseItem>> _cache = {};

  /// Returns the praise list for [lang]. Hindi uses the Hindi dataset; every
  /// other language (including Tamil, which has no dataset yet) uses English.
  static Future<List<PraiseItem>> load(String lang) async {
    final key = lang == 'hi' ? 'hi' : 'en';
    final cached = _cache[key];
    if (cached != null) return cached;

    final raw = await rootBundle.loadString('assets/praises/praises_$key.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final items = <PraiseItem>[
      for (final e in (data['items'] as List))
        PraiseItem((e['id'] as num).toInt(), (e['praise'] as String).trim()),
    ];
    _cache[key] = items;
    return items;
  }
}
