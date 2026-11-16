import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/music_service.dart';
import 'services/tts_service.dart';
import 'state/app_state.dart';
import 'state/settings_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved language/theme before the first frame so the app opens correctly.
  final settings = SettingsState();
  await settings.load();

  // Create the backend-backed app state and start a session (restore or guest).
  final appState = AppState();
  // Not awaited: the UI shows immediately; the session fills in when ready.
  appState.boot(language: settings.languageCode);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: appState),
        ChangeNotifierProvider(create: (_) => TtsService()),
        ChangeNotifierProvider(create: (_) => MusicService()),
      ],
      child: const BibleCompanionApp(),
    ),
  );
}
