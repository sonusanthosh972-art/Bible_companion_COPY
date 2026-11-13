import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../data/emotions_data.dart';
import '../../l10n/app_localizations.dart';
import '../../services/bible_service.dart';
import '../../state/settings_state.dart';
import '../../widgets/common.dart';
import '../../widgets/language_sheet.dart';

/// "Emotional wellness" — browse Scripture by how you feel. Titles come from the
/// locale files; verse text is fetched live from the Bible API per language.
class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  // (emotionId, icon, color) — id maps to both the locale key and the verse map.
  static const _emotions = [
    ('peace', Icons.spa_outlined, Color(0xFF3FA66B)),
    ('hope', Icons.wb_twilight, Color(0xFFE8A13A)),
    ('strength', Icons.fitness_center, Color(0xFF5B55E0)),
    ('fear', Icons.shield_outlined, Color(0xFF4A90D9)),
    ('healing', Icons.healing_outlined, Color(0xFFD9607A)),
    ('joy', Icons.sentiment_very_satisfied_outlined, Color(0xFFE8A13A)),
    ('love', Icons.favorite_outline, Color(0xFFD9607A)),
    ('wisdom', Icons.lightbulb_outline, Color(0xFF5B55E0)),
    ('trust', Icons.handshake_outlined, Color(0xFF3FA66B)),
    ('grief', Icons.water_drop_outlined, Color(0xFF4A90D9)),
    ('forgiveness', Icons.volunteer_activism_outlined, Color(0xFFD9607A)),
    ('worry', Icons.cloud_outlined, Color(0xFF8A8A8A)),
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('emotional_wellness_title')),
        actions: const [LanguageAction()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.t('gods_promises_every_need'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(l.t('discover_subtitle'),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              for (final (id, icon, color) in _emotions)
                AppCard(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => EmotionDetailScreen(id: id, icon: icon, color: color),
                  )),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: color),
                      ),
                      Text(l.t('emotion_${id}_title'),
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class EmotionDetailScreen extends StatefulWidget {
  const EmotionDetailScreen({super.key, required this.id, required this.icon, required this.color});
  final String id;
  final IconData icon;
  final Color color;

  @override
  State<EmotionDetailScreen> createState() => _EmotionDetailState();
}

class _EmotionDetailState extends State<EmotionDetailScreen> {
  final _bible = BibleService();
  Future<List<({String text, String reference})>>? _future;
  String? _loadedLang;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = Provider.of<SettingsState>(context).languageCode;
    if (lang != _loadedLang) {
      _loadedLang = lang;
      _future = _loadVerses(lang);
    }
  }

  Future<List<({String text, String reference})>> _loadVerses(String lang) async {
    final refs = kEmotionVerses[widget.id] ?? const [];
    final results = await Future.wait(
      refs.map((r) => _bible.verseAt(lang, r.$1, r.$2, r.$3)),
    );
    return results.whereType<({String text, String reference})>().toList();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final titleKey = 'emotion_${widget.id}_title';
    return Scaffold(
      appBar: AppBar(
        title: Text(l.t(titleKey)),
        actions: const [LanguageAction()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.color.withValues(alpha: 0.9), widget.color.withValues(alpha: 0.6)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(widget.icon, color: Colors.white, size: 40),
                const SizedBox(height: 12),
                Text(l.t(titleKey),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(l.t('words_comfort_strength'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(children: [
            const Icon(Icons.menu_book_outlined, size: 18, color: AppColors.brand),
            const SizedBox(width: 8),
            Text(l.t('emotion_verses'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ]),
          const SizedBox(height: 12),
          FutureBuilder<List<({String text, String reference})>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final verses = snap.data ?? [];
              if (verses.isEmpty) {
                return AppCard(child: Text(l.t('auth_error_network')));
              }
              return Column(
                children: [
                  for (final v in verses)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v.text,
                                style: const TextStyle(fontSize: 16, height: 1.7)),
                            const SizedBox(height: 8),
                            Text(v.reference,
                                style: const TextStyle(
                                    color: AppColors.brand,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
