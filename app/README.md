# Bible Companion — Flutter App (EN / TA / HI)

A trilingual Bible companion app. The **entire UI switches language instantly**
between **English, Tamil and Hindi** from a single toggle. Built from scratch in
Flutter.

> Bible **verse** translation is not done here — that comes from your own data /
> API. This project ships the **app UI** fully translated in all three languages,
> plus a small sample verse database so the app runs end-to-end.

---

## What's inside

```
app/
├── pubspec.yaml                 # dependencies + asset registration
├── assets/
│   ├── locales/                 # the 3 UI translation files, 839 keys each
│   │   ├── en.json              #   English
│   │   ├── ta.json              #   Tamil
│   │   └── hi.json              #   Hindi   ← newly created, matches en/ta exactly
│   └── database/
│       └── bible_reading.db     # sample trilingual verse DB (replace with full data)
└── lib/
    ├── main.dart                # entry: loads saved language/theme, runs app
    ├── app.dart                 # MaterialApp; locale-driven whole-app rebuild
    ├── core/                    # config (API base URL), theme
    ├── l10n/app_localizations.dart   # loads assets/locales/<code>.json
    ├── state/settings_state.dart     # language + theme (persisted)
    ├── models/                  # user, verse, leaderboard
    ├── services/                # bible (SQLite), api_client, auth, content
    ├── widgets/language_sheet.dart   # the language switcher
    └── screens/                 # home, bible, play, settings + bottom nav
```

### How the "whole app translates" works
1. `SettingsState` holds the current `Locale` and persists it.
2. `app.dart` watches `SettingsState`, so changing the language rebuilds
   `MaterialApp` with a new `locale`.
3. Every screen reads strings via `AppLocalizations.of(context).t('key')`, which
   loads `assets/locales/<code>.json`. The whole UI updates in one frame.

To add a 4th language later: drop `assets/locales/<code>.json`, add the code to
`AppLocalizations.supportedLocales`, to `SettingsState`'s allow-list, and to
`LanguageSheet._options`.

---

## Run it

You need the Flutter SDK (this machine does **not** have it yet):

```bash
# 1. Install Flutter — https://docs.flutter.dev/get-started/install/macos
#    (or: brew install --cask flutter), then:
flutter doctor

# 2. From this app/ folder, generate the native project folders.
#    This does NOT touch lib/, assets/ or pubspec.yaml.
cd app
flutter create .

# 3. Fetch packages and run on your connected phone / emulator.
flutter pub get
flutter run
```

Switch language from the globe icon on Home, or Settings → language. The whole
app — tabs, titles, buttons, the lot — re-renders in Tamil or Hindi instantly.

### Optional: connect it to your backend
The app runs fully offline by default. To point auth/sync at the REST backend in
`../backend`, pass its URL at launch (10.0.2.2 = your computer, from an Android
emulator):

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/v1
```

---

## Replacing the sample Bible with your full data
The app reads `assets/database/bible_reading.db` (table `bible_verses`). Keep the
same columns and add your rows — including `hindi_verse` and `hindi_book_name`:

```
bible_verses(id, chapter_key, english_book_name, tamil_book_name, hindi_book_name,
             book_order, chapter, verse, english_verse, tamil_verse, hindi_verse)
```

Drop your populated `.db` at that path and rebuild — no code change needed.
