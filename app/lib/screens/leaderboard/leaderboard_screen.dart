import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/leaderboard_entry.dart';
import '../../state/app_state.dart';
import '../../widgets/language_sheet.dart';

/// Leaderboard with a top-3 podium and a ranked list, matching the original
/// app's layout. Data is the live XP leaderboard from the backend.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  int _category = 0; // Reading / Quiz / Mark / Word Link (cosmetic selector)
  bool _thisWeek = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().refreshLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = context.watch<AppState>();
    final entries = app.leaderboard;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(l.t('leaderboard')),
        actions: const [LanguageAction()],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AppState>().refreshLeaderboard(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _categorySelector(l),
            const SizedBox(height: 16),
            _timeFilter(l),
            const SizedBox(height: 20),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Text(app.online ? l.t('leaderboard_empty') : l.t('auth_error_network')),
                ),
              )
            else ...[
              _podium(context, l, entries),
              const SizedBox(height: 24),
              for (var i = 3; i < entries.length; i++)
                _rankRow(context, l, i + 1, entries[i]),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _categorySelector(AppLocalizations l) {
    final cats = [
      (Icons.menu_book_rounded, l.t('leaderboard_section_reading')),
      (Icons.quiz_outlined, l.t('leaderboard_section_quiz')),
      (Icons.timer_outlined, l.t('game_mark_quiz_title')),
      (Icons.hub_outlined, l.t('leaderboard_section_word_link')),
    ];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          for (var i = 0; i < cats.length; i++)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _category = i),
                child: Column(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _category == i ? AppColors.brand : Colors.white,
                      ),
                      child: Icon(cats[i].$1,
                          color: _category == i ? Colors.white : AppColors.brand, size: 22),
                    ),
                    const SizedBox(height: 6),
                    Text(cats[i].$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: _category == i ? FontWeight.w700 : FontWeight.w500)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _timeFilter(AppLocalizations l) {
    Widget chip(String label, bool selected, VoidCallback onTap) => GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.brand : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600)),
          ),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        chip(l.t('all_time'), !_thisWeek, () => setState(() => _thisWeek = false)),
        const SizedBox(width: 8),
        chip(l.t('this_week'), _thisWeek, () => setState(() => _thisWeek = true)),
      ],
    );
  }

  Widget _podium(BuildContext context, AppLocalizations l, List<LeaderboardEntry> e) {
    final second = e.length > 1 ? e[1] : null;
    final first = e[0];
    final third = e.length > 2 ? e[2] : null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _podiumSpot(context, l, 2, second, 70)),
        Expanded(child: _podiumSpot(context, l, 1, first, 88)),
        Expanded(child: _podiumSpot(context, l, 3, third, 70)),
      ],
    );
  }

  Widget _podiumSpot(BuildContext context, AppLocalizations l, int rank, LeaderboardEntry? e, double size) {
    if (e == null) return const SizedBox.shrink();
    final medal = {1: AppColors.accent, 2: const Color(0xFF9AA0A6), 3: const Color(0xFFCD7F32)};
    final name = (e.nickname?.isNotEmpty ?? false) ? e.nickname! : l.t('drawer_guest');
    return Column(
      children: [
        Text('$rank',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: medal[rank])),
        if (rank == 1)
          const Icon(Icons.emoji_events, color: AppColors.accent, size: 30)
        else
          const SizedBox(height: 30),
        const SizedBox(height: 4),
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.brand,
            border: Border.all(color: medal[rank]!, width: 3),
          ),
          alignment: Alignment.center,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '•',
            style: TextStyle(
                color: Colors.white, fontSize: size * 0.4, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 8),
        Text(name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_stories, size: 15, color: AppColors.accent),
            const SizedBox(width: 4),
            Text('${e.xp}',
                style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w800)),
          ],
        ),
      ],
    );
  }

  Widget _rankRow(BuildContext context, AppLocalizations l, int rank, LeaderboardEntry e) {
    final name = (e.nickname?.isNotEmpty ?? false) ? e.nickname! : l.t('drawer_guest');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text('$rank',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.card(context),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.brand.withValues(alpha: 0.85),
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : '•',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                  const Icon(Icons.auto_stories, size: 16, color: AppColors.accent),
                  const SizedBox(width: 5),
                  Text('${e.xp}',
                      style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
