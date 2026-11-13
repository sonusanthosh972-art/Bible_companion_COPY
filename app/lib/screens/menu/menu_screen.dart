import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../state/settings_state.dart';
import '../../widgets/common.dart';
import '../../widgets/language_sheet.dart';
import '../discover/discover_screen.dart';
import '../plan/reading_plan_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';

/// Menu tab — profile header + a list of destinations and account actions.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = context.watch<AppState>();
    final name = app.user?.displayName ?? l.t('drawer_guest');

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('menu')),
        actions: const [LanguageAction()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile header
          AppCard(
            onTap: () => _push(context, const ProfileScreen()),
            child: Row(
              children: [
                InitialAvatar(name, radius: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(app.isGuest ? l.t('drawer_guest') : (app.user?.email ?? ''),
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _tile(context, Icons.event_note_outlined, l.t('bible_reading_plan'),
              () => _push(context, const ReadingPlanScreen())),
          _tile(context, Icons.favorite_outline, l.t('emotional_wellness_title'),
              () => _push(context, const DiscoverScreen())),
          _tile(context, Icons.translate, l.t('select_language'),
              () => LanguageSheet.show(context)),
          _tile(context, Icons.settings_outlined, l.t('settings'),
              () => _push(context, const SettingsScreen())),
          _tile(context, Icons.note_alt_outlined, l.t('notes'),
              () => _soon(context, l)),
          _tile(context, Icons.privacy_tip_outlined, l.t('privacy_policy'),
              () => _soon(context, l)),

          const SizedBox(height: 16),
          if (!app.isGuest)
            OutlinedButton.icon(
              onPressed: () => context
                  .read<AppState>()
                  .signOut(language: context.read<SettingsState>().languageCode),
              icon: const Icon(Icons.logout),
              label: Text(l.t('auth_sign_out')),
            ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.brand, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  void _soon(BuildContext context, AppLocalizations l) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.t('this_feature_is_coming_soon'))),
      );
}
