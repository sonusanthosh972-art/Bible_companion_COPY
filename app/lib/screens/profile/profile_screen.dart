import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../state/settings_state.dart';
import '../../widgets/common.dart';
import '../../widgets/language_sheet.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = context.watch<AppState>();
    final name = app.user?.displayName ?? l.t('drawer_guest');

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('profile')),
        actions: const [LanguageAction()],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AppState>().refreshLeaderboard(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.brandGradient,
                borderRadius: BorderRadius.circular(22),
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '•',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Row(children: [
                          Icon(app.online ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                              color: Colors.white70, size: 15),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              app.isGuest ? l.t('drawer_guest') : (app.user?.email ?? ''),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: StatTile(icon: Icons.local_fire_department, value: '${app.streak}', label: l.t('day_streak'), color: AppColors.accent)),
                const SizedBox(width: 12),
                Expanded(child: StatTile(icon: Icons.star_rounded, value: '${app.xp}', label: l.t('profile_xp'), color: AppColors.brand)),
                const SizedBox(width: 12),
                Expanded(child: StatTile(icon: Icons.military_tech_outlined, value: '${app.level}', label: l.t('profile_level'), color: AppColors.green)),
              ],
            ),
            const SizedBox(height: 8),
            if (app.isGuest) _guestPrompt(context, l),
            SectionHeader(l.t('leaderboard'),
                trailing: l.t('game_retry'),
                onTrailingTap: () => context.read<AppState>().refreshLeaderboard()),
            _leaderboard(context, l, app),
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
      ),
    );
  }

  Widget _guestPrompt(BuildContext context, AppLocalizations l) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AppCard(
          color: AppColors.brand.withValues(alpha: 0.08),
          child: Row(children: [
            const Icon(Icons.info_outline, color: AppColors.brand),
            const SizedBox(width: 12),
            Expanded(child: Text(l.t('guest_reminder_backup'))),
          ]),
        ),
      );

  Widget _leaderboard(BuildContext context, AppLocalizations l, AppState app) {
    if (app.leaderboard.isEmpty) {
      return AppCard(
        child: Row(children: [
          const Icon(Icons.leaderboard_outlined),
          const SizedBox(width: 12),
          Expanded(child: Text(app.online ? l.t('leaderboard_empty') : l.t('auth_error_network'))),
        ]),
      );
    }
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          for (var i = 0; i < app.leaderboard.length; i++)
            ListTile(
              leading: _rankBadge(i + 1),
              title: Text(app.leaderboard[i].nickname ?? l.t('drawer_guest')),
              subtitle: Text('${l.t('profile_level')} ${app.leaderboard[i].level}'),
              trailing: Text('${app.leaderboard[i].xp} ${l.t('profile_xp')}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.brand)),
            ),
        ],
      ),
    );
  }

  Widget _rankBadge(int rank) {
    final colors = {1: const Color(0xFFE8A13A), 2: const Color(0xFF9AA0A6), 3: const Color(0xFFCD7F32)};
    final c = colors[rank] ?? AppColors.brand.withValues(alpha: 0.4);
    return CircleAvatar(
      radius: 16,
      backgroundColor: c.withValues(alpha: 0.18),
      child: Text('$rank', style: TextStyle(color: c, fontWeight: FontWeight.w800)),
    );
  }
}
