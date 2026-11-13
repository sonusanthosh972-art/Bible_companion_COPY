import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'l10n/app_localizations.dart';
import 'state/settings_state.dart';
import 'screens/root_nav.dart';

class BibleCompanionApp extends StatelessWidget {
  const BibleCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Watching SettingsState rebuilds MaterialApp when language/theme change,
    // so switching language re-renders the ENTIRE app instantly.
    final settings = context.watch<SettingsState>();

    return MaterialApp(
      title: 'Bible Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(lang: settings.languageCode),
      darkTheme: AppTheme.dark(lang: settings.languageCode),
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const RootNav(),
    );
  }
}
