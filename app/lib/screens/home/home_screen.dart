import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/bible_models.dart';
import '../../services/bible_service.dart';
import '../../state/app_state.dart';
import '../../state/settings_state.dart';
import '../../widgets/language_sheet.dart';
import '../discover/discover_screen.dart';
import '../plan/reading_plan_screen.dart';
import '../profile/profile_screen.dart';
import '../share/share_verse_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _bible = BibleService();
  DailyVerse? _verse;
  String? _loadedLang;

  // Emotion chips shown on home (id, icon, color).
  static const _emotions = [
    ('anxiety', Icons.cloud_outlined, AppColors.purple),
    ('peace', Icons.spa_outlined, AppColors.green),
    ('hope', Icons.wb_twilight, AppColors.accent),
    ('fear', Icons.shield_outlined, AppColors.brand),
    ('strength', Icons.fitness_center, AppColors.purple),
    ('healing', Icons.healing_outlined, AppColors.rose),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = Provider.of<SettingsState>(context).languageCode;
    if (lang != _loadedLang) {
      _loadedLang = lang;
      _loadVerse();
    }
  }

  Future<void> _loadVerse() async {
    final lang = context.read<SettingsState>().languageCode;
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
    final v = await _bible.dailyVerse(dayOfYear, lang);
    if (mounted) setState(() => _verse = v);
  }

  String _greetingName(AppState app, AppLocalizations l) =>
      // Guests get the localized "Guest" label; the backend stores it as the
      // English "Guest" display name, which would otherwise show on Hindi/Tamil.
      app.isGuest ? l.t('drawer_guest') : (app.user?.displayName ?? l.t('drawer_guest'));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final a = context.read<AppState>();
            await _loadVerse();
            await a.refreshLeaderboard();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _header(context, l),
              const SizedBox(height: 18),
              // Only the greeting depends on the user's name — scope the rebuild
              // so leaderboard/XP refreshes don't rebuild the whole screen.
              Selector<AppState, String>(
                selector: (_, app) => _greetingName(app, l),
                builder: (context, name, _) => _greeting(context, name),
              ),
              const SizedBox(height: 16),
              _verseCard(context, l),
              const SizedBox(height: 22),
              _feelingRow(context, l),
              const SizedBox(height: 22),
              // Reading progress is the only other AppState-dependent piece.
              Consumer<AppState>(
                builder: (context, app, _) => _readingCard(context, l, app),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Header: logo + title + globe/theme ----
  Widget _header(BuildContext context, AppLocalizations l) {
    final settings = context.watch<SettingsState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.brand.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.menu_book_rounded, color: AppColors.brand),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bible',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, height: 1)),
            Text('Companion',
                style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.1)),
          ],
        ),
        const Spacer(),
        IconButton(
          tooltip: l.t('select_language'),
          icon: const Icon(Icons.language),
          onPressed: () => LanguageSheet.show(context),
        ),
        IconButton(
          tooltip: l.t('theme'),
          icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
          onPressed: () =>
              settings.setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark),
        ),
      ],
    );
  }

  Widget _greeting(BuildContext context, String name) {
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(l.t('greeting_hello').replaceAll('{name}', name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.brand,
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '•',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }

  // ---- Daily verse ----
  Widget _verseCard(BuildContext context, AppLocalizations l) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.t('daily_verse'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  Text(_todayLabel(),
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
              const Spacer(),
              _circleIcon(Icons.favorite_border, l.t('like')),
              const SizedBox(width: 8),
              _circleIcon(
                Icons.share,
                l.t('share'),
                onTap: _verse == null
                    ? null
                    : () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ShareVerseScreen(
                            verse: _verse!.text,
                            reference: _verse!.reference,
                            lang: l.locale.languageCode,
                            userName: context.read<AppState>().isGuest
                                ? null
                                : context.read<AppState>().user?.displayName,
                          ),
                        )),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _verse?.text ?? '…',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                height: 1.5,
                fontWeight: FontWeight.w500),
          ),
          if (_verse != null) ...[
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_verse!.reference,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _circleIcon(IconData icon, String tooltip, {VoidCallback? onTap}) =>
      Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      );

  String _todayLabel() {
    final d = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  // ---- Emotion chips ----
  Widget _feelingRow(BuildContext context, AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(l.t('how_are_you_feeling'),
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700)),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DiscoverScreen())),
              child: Text(l.t('view_all'),
                  style: const TextStyle(
                      color: AppColors.brand, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _emotions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final (id, icon, color) = _emotions[i];
              return GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      EmotionDetailScreen(id: id, icon: icon, color: color),
                )),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(l.t('emotion_${id}_title'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---- Bible reading progress ----
  Widget _readingCard(BuildContext context, AppLocalizations l, AppState app) {
    const total = 365;
    final done = app.completedDays('1y').length;
    final remaining = (total - done).clamp(0, total);
    final pct = done / total;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.t('bible_reading'),
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 84,
                height: 84,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 84,
                      height: 84,
                      child: CircularProgressIndicator(
                        value: pct,
                        strokeWidth: 8,
                        backgroundColor: Theme.of(context).dividerColor,
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.brand),
                      ),
                    ),
                    Text('${(pct * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _readingStat(Icons.check_circle, AppColors.green,
                        l.t('days_completed'), '$done'),
                    const SizedBox(height: 12),
                    _readingStat(Icons.schedule, AppColors.brand,
                        l.t('remaining'), '$remaining'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ReadingPlanScreen())),
            icon: const Icon(Icons.calendar_month),
            label: Text(l.t('bible_reading_plan')),
          ),
        ],
      ),
    );
  }

  Widget _readingStat(IconData icon, Color color, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text('$label: ',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ],
    );
  }
}
