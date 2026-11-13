import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Lightweight JSON-backed localization (en / ta / hi), loaded from
/// `assets/locales/<code>.json`. Mirrors the original app's locale-file approach
/// and avoids code generation so the project builds with a plain `flutter run`.
class AppLocalizations {
  AppLocalizations(this.locale, this._strings);

  final Locale locale;
  final Map<String, String> _strings;

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ta'),
    Locale('hi'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final l = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(l != null, 'No AppLocalizations found in context');
    return l!;
  }

  /// Returns the translated string, falling back to the key itself if missing.
  String t(String key) => _strings[key] ?? key;

  static Future<AppLocalizations> load(Locale locale) async {
    final code = _resolve(locale.languageCode);
    final jsonStr = await rootBundle.loadString('assets/locales/$code.json');
    final map = (jsonDecode(jsonStr) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v.toString()));
    return AppLocalizations(Locale(code), map);
  }

  static String _resolve(String code) =>
      ['en', 'ta', 'hi'].contains(code) ? code : 'en';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'ta', 'hi'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) =>
      AppLocalizations.load(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Convenience extension: `context.tr('home')`.
extension LocalizedContext on BuildContext {
  String tr(String key) => AppLocalizations.of(this).t(key);
}

@visibleForTesting
Future<Map<String, String>> debugLoadLocale(String code) async {
  final jsonStr = await rootBundle.loadString('assets/locales/$code.json');
  return (jsonDecode(jsonStr) as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, v.toString()));
}
