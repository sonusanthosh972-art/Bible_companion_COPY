import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../state/settings_state.dart';

/// AppBar action that opens the language switcher — drop into any screen's
/// `AppBar(actions: [...])` so users can change language from any page.
class LanguageAction extends StatelessWidget {
  const LanguageAction({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return IconButton(
      tooltip: l.t('select_language'),
      icon: const Icon(Icons.translate),
      onPressed: () => LanguageSheet.show(context),
    );
  }
}

/// Bottom sheet to switch the whole app's language. Selecting an option updates
/// [SettingsState], which rebuilds MaterialApp with the new locale instantly.
class LanguageSheet extends StatelessWidget {
  const LanguageSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (_) => const LanguageSheet(),
      );

  // Native language names are intentionally hard-coded (not translated).
  static const _options = [
    (code: 'en', native: 'English', labelKey: 'english'),
    (code: 'ta', native: 'தமிழ்', labelKey: 'tamil'),
    (code: 'hi', native: 'हिन्दी', labelKey: 'hindi'),
  ];

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text(
              l.t('select_language'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          for (final o in _options)
            RadioListTile<String>(
              value: o.code,
              groupValue: settings.languageCode,
              onChanged: (code) {
                if (code != null) {
                  context.read<SettingsState>().setLanguage(code);
                  Navigator.of(context).pop();
                }
              },
              title: Text(o.native),
              subtitle: Text(l.t(o.labelKey)),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
