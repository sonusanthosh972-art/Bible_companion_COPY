import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../state/settings_state.dart';
import '../../widgets/language_sheet.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _languageNative(String code) => switch (code) {
        'ta' => 'தமிழ்',
        'hi' => 'हिन्दी',
        _ => 'English',
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final settings = context.watch<SettingsState>();

    return Scaffold(
      appBar: AppBar(title: Text(l.t('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _sectionTitle(context, l.t('select_language')),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language),
              title: Text(_languageNative(settings.languageCode)),
              subtitle: Text(l.t('select_language_description')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => LanguageSheet.show(context),
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle(context, l.t('theme')),
          Card(
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  groupValue: settings.themeMode,
                  onChanged: (m) => context.read<SettingsState>().setThemeMode(m!),
                  title: Text(l.t('theme_light')),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  groupValue: settings.themeMode,
                  onChanged: (m) => context.read<SettingsState>().setThemeMode(m!),
                  title: Text(l.t('theme_dark')),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  groupValue: settings.themeMode,
                  onChanged: (m) => context.read<SettingsState>().setThemeMode(m!),
                  title: Text(l.t('system_theme')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle(context, l.t('about')),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l.t('app_name')),
                  subtitle: Text(l.t('bible_attribution')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
      );
}
