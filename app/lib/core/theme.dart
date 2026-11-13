import 'package:flutter/material.dart';

/// Design system: a deep-navy devotional palette with soft surfaces, rounded
/// cards and gentle gradients. Colors and styling are original (Material icons
/// and gradients), tuned to feel familiar — no third-party artwork is used.
class AppColors {
  static const brand = Color(0xFF2B4C6E); // deep navy (primary)
  static const brandDeep = Color(0xFF1E3A57);
  static const accent = Color(0xFFC8912E); // gold — streaks / stars / hope
  static const rose = Color(0xFFC65B78); // emotions (healing / love)
  static const green = Color(0xFF3B8A68); // progress / peace / quiz
  static const teal = Color(0xFF2E8B7A); // counts / leaderboard numbers
  static const purple = Color(0xFF5A4A8F); // anxiety / word-link
}

class AppTheme {
  static ThemeData light({String lang = 'en'}) => _base(Brightness.light, lang);
  static ThemeData dark({String lang = 'en'}) => _base(Brightness.dark, lang);

  /// The primary font for a language. Using a script-complete font as the
  /// PRIMARY (not just a fallback) makes the whole text run — words *and* the
  /// spaces between them — shape with one font, so Hindi/Tamil word spacing and
  /// conjuncts render correctly.
  static String? _fontFor(String lang) => switch (lang) {
        'hi' => 'NotoSansDevanagari',
        'ta' => 'NotoSansTamil',
        _ => null, // English uses the Material default
      };

  static ThemeData _base(Brightness brightness, String lang) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: brightness,
    ).copyWith(primary: isDark ? const Color(0xFF7FA8CC) : AppColors.brand);
    final bg = isDark ? const Color(0xFF10151B) : const Color(0xFFEDEBE6);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      // Bundled fonts that properly shape Devanagari (Hindi) and Tamil so word
      // spaces and conjuncts render correctly instead of collapsing. The primary
      // font follows the current language; the fallbacks cover mixed scripts.
      fontFamily: _fontFor(lang),
      fontFamilyFallback: const ['NotoSansDevanagari', 'NotoSansTamil'],
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }

  /// Soft surface color for cards (works in both themes).
  static Color card(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF1A212B) : Colors.white;
  }

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF325777), Color(0xFF213F5C)],
  );

  // Game-card gradients (original colors).
  static const greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3F9B72), Color(0xFF2E7355)],
  );
  static const purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6A58A6), Color(0xFF4E3F85)],
  );
}
