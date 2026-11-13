# Bible Companion — Reverse Engineering Analysis

Evidence-driven static analysis of the Android app **Bible Companion**, performed locally with REA-style methodology (pull from device → verify signature → decode manifest → decompile DEX → mine the Flutter Dart snapshot → inspect bundled data). No code was executed; the app was only read.

**Package**: `com.littyshabini.biblecompanion`
**Version**: 2.4.11 (versionCode 54) · **Updated**: Nov 3, 2026 (Play) / device build Nov 7, 2026
**Developer**: Evolvant systems — evolvantsystems.com (`evolvantsystems@gmail.com`, `littydinesh@gmail.com`)
**Category**: Books & Reference · Free · no ads · no in-app purchases · Everyone
**Play listing**: https://play.google.com/store/apps/details?id=com.littyshabini.biblecompanion

---

## 0. How this was analyzed (provenance)

| Step | Tool | Evidence produced |
| --- | --- | --- |
| Locate install | `adb shell pm path` | 11 split APKs (base + arm64 + 8 languages + xxhdpi) |
| Pull package | `adb pull` | `base.apk` (40 MB) + splits |
| Verify authenticity | `apksigner verify --print-certs` | Signed by Google Play App Signing |
| Decode manifest/resources | `apktool d -s` | AndroidManifest, `strings.xml` (Firebase config) |
| Decompile Java/Kotlin | `jadx` | Plugin registrant, Firebase/GMS glue |
| Mine Dart logic | `strings` on `libapp.so` | API endpoints, package list, full source file tree |
| Inspect bundled data | `sqlite3` / Python | `bible_reading.db` schema + row counts |

**Confidence**: *certain* for anything read directly from the binary/manifest/DB; *probable* where behavior is inferred from file/service names.

**Authenticity (certain)**: `base.apk` is signed by **Google Play App Signing** — `V3.0 Signer DN: CN=Android, O=Google Inc.`, SHA-256 `9d79…75cc`, plus a Google **Source Stamp** (`3257…bd6d`). This is a genuine Play-delivered build, not a repackaged mirror copy.

---

## 1. What the app is

A bilingual (**English + Tamil**) Bible reading, devotion, and gamification app. Core offering:

- Full Bible in English + Tamil, with audio read-aloud (TTS) and voice search
- Reading plans (1 year / 6 months / 3 months) with streaks and progress tracking
- Daily verse + daily Bible quiz; "Praise" audio devotions
- Emotion-based verse finder (anxiety, fear, strength, healing, hope…)
- Bible games: quizzes, "Mark" quiz, Word Link / Word Builder — XP, levels, 26 badges, leaderboards
- Verse-image sharing; prayer requests (WhatsApp/email)
- Cross-device sync via account (Google / email / guest), biometric or PIN app-lock

---

## 2. Technology stack (certain)

This is a **Flutter** application — business logic is AOT-compiled Dart in `libapp.so`, not Java/Kotlin.

| Layer | Technology | Evidence |
| --- | --- | --- |
| UI / app framework | **Flutter** (Dart AOT) | `lib/arm64-v8a/libflutter.so`, `libapp.so` |
| App Dart package | `bible_tracker_flutter` | source paths in snapshot |
| Local storage | **SQLite** (`sqflite`) + `shared_preferences` + `flutter_secure_storage` | plugins + bundled `.db` |
| Backend | **Custom REST API** `api.biblecompanion.in/v1` + **web** `app.biblecompanion.in` (Next.js/Turbopack) | URLs in snapshot |
| Cloud | **Firebase**: Auth, Firestore, Cloud Messaging, Analytics, Remote Config | `strings.xml`, plugin list |
| Identity | Google Sign-In + Firebase Auth (email/password, IdP, reCAPTCHA) | GMS/Firebase activities |
| Analytics | Firebase Analytics + **Amplitude** (`amplitude_flutter`) | plugin + consent modal |
| Integrity | **PairIP** license check / anti-tamper (`com.pairip.licensecheck`) | manifest component |
| Native libs | `libapp.so`, `libflutter.so`, `libdatastore_shared_counter.so` | arm64 split |

**Firebase project** (certain, from `res/values/strings.xml`):
- `project_id`: `bible-companion-109c5`
- `google_app_id`: `1:772918151232:android:a3a4baa2b45fb4c156f7a5`
- Sender ID: `772918151232`
- Storage bucket: `bible-companion-109c5.firebasestorage.app`
- Android API key: `AIzaSyB…uWlo` *(public client key — designed to be shipped; not a secret)*

---

## 3. Backend API surface (certain — strings in `libapp.so`)

Base: **`https://api.biblecompanion.in/v1`**

| Endpoint | Likely purpose |
| --- | --- |
| `/v1/app/firebase-token` | Exchange app session for a Firebase custom token |
| `/v1/content/daily-verses/edits` | Pull server-side edits/overrides to daily-verse content |

Web auth bridge: **`https://app.biblecompanion.in/app-auth`** with `/authorize`, `/user`, `/settings` — the account/auth flow is handled through the Next.js web app (deep-linked back into the app). `wa.me` is used for WhatsApp prayer-request/share links.

> Only two `/v1/...` paths are stored as literal strings; most REST paths are likely composed at runtime (base + segment), so the full API is larger than what appears statically.

---

## 4. App architecture (recovered Dart source tree)

The Dart snapshot preserves source file paths, so the internal structure of `package:bible_tracker_flutter` is fully recoverable — ~100+ files across `pages/`, `components/`, `services/`, `models/`, `database/migrations/`.

### Services layer (business logic) — certain
`auth_service`, `account_backup_service`, `account_backup_merge`, `account_setup_service`, `firestore_sync_service`, `user_service`, `user_data_changes`, `device_service`, `secure_token_store`, `fcm_service`, `deep_link_service`, `analytics_service`, `app_lock_service`, `biometric_gate`, `database_service`, `bible_service`, `bible_progress_service`, `daily_verse_service`, `daily_verse_sync`, `daily_quiz_service`, `emotion_verses_service`, `emotion_prayer_service`, `verse_notes_service`, `xp_service`, `xp_rules`, `daily_play_cap`, `word_builder_service`, `word_builder_data`, `achievements_data`, `sound_service`, `theme_service`, `review_prompt_service`, `update_check_service`.

### Pages (screens) — certain
Auth flow: `welcome`, `sign_in`, `create_account`, `check_email`, `forgot_password`, `new_password`, `guest_info`, `guest_reminder`, `auth_gate`.
Bible: `bible_page`, `bible_index_page`, `bible_progress_page`, `365_days_plan_page`, `bible_short_page`, `daily_word_page`, `notes_page`.
Games: `play_page`, `bible_quiz_game_page`, `quiz_level_page`, `mark_quiz_hub/page/complete`, `mark_match_page`, `word_builder_hub/page`, `word_link_*`, `level_complete_page`, `leaderboard_page`, `how_to_play_page`.
Other: `praise_page`, `praise_book_page`, `discover_page`, `profile_page`, `settings_page`, `privacy_policy_page`.

### Data layer
19 sequential SQLite migrations (`migration_002` → `migration_019`), orchestrated by `migrations.dart` — indicates an evolving on-device schema layered over the shipped seed DB.

---

## 5. Bundled data (certain — `assets/.../bible_reading.db`, 21 MB SQLite)

| Table | Rows | Contents |
| --- | --- | --- |
| `bible_verses` | **31,102** | Full Bible, EN + TA per verse (book names both languages, book_order, chapter, verse) |
| `daily_verses` | 365 | One devotion verse per day of year (EN + TA + reference) |
| `emotion_verses` | 226 | Verses grouped by emotion, with short reflection (EN + TA) |
| `emotion_prayer` | — | Prayers paired to emotions |
| `quiz_game_levels` | 225 | 4-option quiz questions (EN + TA) for game levels |
| `quiz_daily` | 415 | Daily quiz bank (EN + TA, category, answer tracking columns) |
| `reading_plans` | 638 | Day-by-day OT / NT / Psalms-Proverbs reading schedule |
| `app_metadata` | 2 | `content_version=21`, `app_version=1.0.0` |

Other bundled assets: 20 Bible-character avatars (`abraham…solomon`), worship audio (`peaceful_worship_piano.m4a`, `praise_harmony_of_heaven.m4a`) + game SFX, Google Fonts, EN/TA locale JSON. The app ships 10 language *resource* splits (bn, en, gu, hi, kn, mr, ta, te…) though content DB is EN/TA.

---

## 6. Permissions & components

### Permissions (from manifest)
`INTERNET`, `ACCESS_NETWORK_STATE`, `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`, `WAKE_LOCK`, `VIBRATE` (notifications/reminders) · `USE_BIOMETRIC` / `USE_FINGERPRINT` (app lock) · `RECORD_AUDIO` (voice search — *denied on device*) · `ACCESS_FINE/COARSE_LOCATION` (*granted on device*) · `READ/WRITE_EXTERNAL_STORAGE` (maxSdk 29, verse-image save) · FCM + `AD_ID` + Ad Services + install-referrer + licensing.

> **Note worth flagging**: the app requests **fine/coarse location** (geolocator plugin) and `AD_ID`. Location isn't obvious from the app's stated features — worth confirming against its Data-safety declaration and privacy policy. On the test device location was granted, microphone denied.

### Notable components
- `com.littyshabini.biblecompanion.MainActivity` (Flutter host), `BootReceiver` (reschedule reminders)
- `com.pairip.licensecheck.LicenseActivity` — Play integrity/anti-tamper
- Firebase Messaging / Auth / Analytics services; Google Sign-In hub; credentials-play-services
- Deep links: scheme `biblecompanion://`, hosts `auth-callback`, `firebase.auth`

---

## 7. Security observations

- ✅ Genuine, Google-signed build; PairIP anti-tamper present.
- ✅ No hardcoded secrets found beyond the public Firebase client key. Long hex strings in the snapshot are Dart/Flutter internal identifiers, not credentials.
- ✅ Tokens kept in `flutter_secure_storage` (`secure_token_store.dart`) → Android Keystore-backed.
- ✅ Analytics consent is explicit (`analytics_consent_modal.dart`, `privacy_policy_amplitude_note`).
- ⚠️ Location + advertising-ID permissions exceed the visible feature set — verify necessity/disclosure.
- ⚠️ Backend trust rests on `api.biblecompanion.in` + Firestore rules (server-side; not inspectable from the APK).

---

## 8. Summary

Bible Companion is a cleanly built **Flutter** app with a **Firebase + custom REST** backend. It ships a **21 MB, 31,102-verse bilingual Bible database** plus quiz/devotion content locally (offline-first), syncs user progress through Firebase Auth/Firestore and a Next.js web auth bridge, and gamifies reading with XP, badges and leaderboards. The build is authentic (Google-signed, PairIP-protected) and free of embedded secrets; the only items worth a second look are the **location** and **advertising-ID** permissions relative to the app's described purpose.

*All findings above are from local static analysis of version 2.4.11; server-side logic and Firestore security rules are out of scope.*
