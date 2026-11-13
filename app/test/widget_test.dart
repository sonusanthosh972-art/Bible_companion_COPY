// Validates that the three locale files are complete and consistent:
// same key set, no empty values, and preserved placeholders.
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

Map<String, String> _load(String code) {
  final raw = File('assets/locales/$code.json').readAsStringSync();
  return (jsonDecode(raw) as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, v.toString()));
}

Iterable<String> _placeholders(String s) {
  final tokens = RegExp(r'\{[a-zA-Z0-9_]+\}')
      .allMatches(s)
      .map((m) => m.group(0)!)
      .toList();
  tokens.addAll(RegExp(r'%s').allMatches(s).map((m) => m.group(0)!));
  tokens.sort();
  return tokens;
}

void main() {
  final en = _load('en');
  final ta = _load('ta');
  final hi = _load('hi');

  test('all three locales have identical key sets', () {
    expect(ta.keys.toSet(), equals(en.keys.toSet()));
    expect(hi.keys.toSet(), equals(en.keys.toSet()));
  });

  test('Hindi has no empty values', () {
    final empty = hi.entries.where((e) => e.value.trim().isEmpty).map((e) => e.key);
    expect(empty, isEmpty, reason: 'empty Hindi values: $empty');
  });

  test('Hindi preserves every placeholder from English', () {
    for (final key in en.keys) {
      expect(
        _placeholders(hi[key]!),
        equals(_placeholders(en[key]!)),
        reason: 'placeholder mismatch for "$key"',
      );
    }
  });
}
