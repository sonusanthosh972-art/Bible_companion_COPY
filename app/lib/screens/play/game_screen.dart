import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../widgets/language_sheet.dart';
import 'bible_quiz_game.dart';

/// Game hub — achievements strip + large gradient game cards, matching the
/// original app's layout (original gradients/icons).
class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  static const int totalBadges = 26;

  int _earned(AppState app) {
    var n = 0;
    if (app.xp >= 50) n++;
    if (app.xp >= 200) n++;
    if (app.xp >= 500) n++;
    if (app.streak >= 3) n++;
    if (app.streak >= 7) n++;
    if (app.quizBest >= 5) n++;
    if (app.quizBest >= 10) n++;
    if (app.level >= 5) n++;
    return n;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = context.watch<AppState>();
    final earned = _earned(app);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('nav_game')),
        actions: const [LanguageAction()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Achievements
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l.t('achievements'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Text(
                l.t('achievements_earned')
                    .replaceAll('{earned}', '$earned')
                    .replaceAll('{total}', '$totalBadges'),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                Expanded(child: _badge(context, unlocked: i < earned)),
                if (i < 3) const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // Game cards
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _gameCard(
                    context,
                    title: l.t('game_bible_quiz'),
                    icon: Icons.menu_book_rounded,
                    gradient: AppTheme.greenGradient,
                    onPlay: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BibleQuizGame()),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _gameCard(
                    context,
                    title: l.t('game_mark_quiz_title'),
                    icon: Icons.timer_outlined,
                    gradient: AppTheme.brandGradient,
                    onPlay: () => _soon(context, l),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _gameCard(
            context,
            title: l.t('game_word_builder_title'),
            icon: Icons.grid_view_rounded,
            gradient: AppTheme.purpleGradient,
            wide: true,
            onPlay: () => _soon(context, l),
          ),
        ],
      ),
    );
  }

  void _soon(BuildContext context, AppLocalizations l) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.t('this_feature_is_coming_soon'))),
      );

  Widget _badge(BuildContext context, {required bool unlocked}) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: unlocked
              ? AppColors.accent.withValues(alpha: 0.18)
              : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          border: Border.all(
            color: unlocked ? AppColors.accent : Theme.of(context).dividerColor,
            width: 1.5,
          ),
        ),
        child: Icon(
          unlocked ? Icons.emoji_events : Icons.lock_outline,
          color: unlocked ? AppColors.accent : Theme.of(context).colorScheme.onSurfaceVariant,
          size: 26,
        ),
      ),
    );
  }

  Widget _gameCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onPlay,
    bool wide = false,
  }) {
    final l = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          SizedBox(height: wide ? 16 : 40),
          Text(title,
              style: const TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onPlay,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.brand,
                minimumSize: const Size.fromHeight(46),
              ),
              child: Text(l.t('game_play'),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
