import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../l10n/app_localizations.dart';
import 'home/home_screen.dart';
import 'bible/bible_screen.dart';
import 'praise/praise_screen.dart';
import 'play/game_screen.dart';
import 'leaderboard/leaderboard_screen.dart';
import 'menu/menu_screen.dart';

/// Six-tab shell — Home · Bible · Praise · Game · Leaderboard · Menu.
class RootNav extends StatefulWidget {
  const RootNav({super.key});

  @override
  State<RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<RootNav> {
  int _index = 0;

  static const _pages = [
    HomeScreen(),
    BibleScreen(),
    PraiseScreen(),
    GameScreen(),
    LeaderboardScreen(),
    MenuScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = <(IconData, String)>[
      (Icons.home_rounded, l.t('home')),
      (Icons.menu_book_rounded, l.t('bible')),
      (Icons.music_note_rounded, l.t('praise')),
      (Icons.sports_esports_rounded, l.t('nav_game')),
      (Icons.leaderboard_rounded, l.t('leaderboard')),
      (Icons.menu_rounded, l.t('menu')),
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161C24) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _NavItem(
                      icon: items[i].$1,
                      label: items[i].$2,
                      selected: _index == i,
                      onTap: () => setState(() => _index = i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 46,
            height: 34,
            decoration: BoxDecoration(
              color: selected ? AppColors.brand : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon,
                size: 22, color: selected ? Colors.white : muted),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.brand : muted,
            ),
          ),
        ],
      ),
    );
  }
}
