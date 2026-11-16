import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/emotions_data.dart';
import '../../l10n/app_localizations.dart';
import '../../services/bible_service.dart';
import '../../services/image_service.dart';
import '../../services/music_service.dart';
import '../../services/tts_service.dart';
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
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
                    builder: (_) =>
                        EmotionDetailScreen(id: id, icon: icon, color: color),
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

/// Immersive, full-screen verse viewer for one emotion — swipe vertically
/// through the verses over a colour-themed background, read them aloud, or
/// share one. Mirrors the reference app's "feeling" detail page.
class EmotionDetailScreen extends StatefulWidget {
  const EmotionDetailScreen(
      {super.key, required this.id, required this.icon, required this.color});
  final String id;
  final IconData icon;
  final Color color;

  @override
  State<EmotionDetailScreen> createState() => _EmotionDetailState();
}

typedef _Verse = ({String text, String reference});

class _EmotionDetailState extends State<EmotionDetailScreen> {
  final _bible = BibleService();
  final _images = ImageService();
  final _pageCtrl = PageController();
  List<_Verse> _verses = const [];
  bool _loading = true;
  bool _failed = false;
  String? _loadedLang;
  int _page = 0;
  TtsService? _tts;
  MusicService? _music;
  bool _musicStarted = false;
  // One background image per verse — swaps as the user scrolls.
  List<SectionImage> _bgs = const [];
  SectionImage? get _bg => _bgs.isEmpty ? null : _bgs[_page % _bgs.length];

  @override
  void initState() {
    super.initState();
    _loadBackground(); // emotion is fixed — load once, independent of language
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tts = context.read<TtsService>();
    _music = context.read<MusicService>();
    // Start the mood music on first open (plays by default; user can mute).
    if (!_musicStarted) {
      _musicStarted = true;
      _music!.playMood(kEmotionMood[widget.id] ?? 'calm');
    }
    final lang = Provider.of<SettingsState>(context).languageCode;
    if (lang != _loadedLang) {
      _loadedLang = lang;
      _load(lang);
    }
  }

  Future<void> _loadBackground() async {
    final query = kEmotionImageQuery[widget.id] ?? 'peaceful landscape nature';
    final imgs =
        await _images.forQueryList(query, count: 6, orientation: 'portrait');
    if (mounted && imgs.isNotEmpty) setState(() => _bgs = imgs);
  }

  @override
  void dispose() {
    _tts?.stop();
    _music?.stop();
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _load(String lang) async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final refs = kEmotionVerses[widget.id] ?? const [];
    final results = await Future.wait(
      refs.map((r) => _bible.verseAt(lang, r.$1, r.$2, r.$3)),
    );
    final verses = results.whereType<_Verse>().toList();
    if (!mounted) return;
    setState(() {
      _verses = verses;
      _loading = false;
      _failed = verses.isEmpty;
      _page = 0;
    });
  }

  // Dark, saturated gradient tinted with the emotion's colour.
  Color _tint(double lightness) => HSLColor.fromColor(widget.color)
      .withSaturation(0.5)
      .withLightness(lightness)
      .toColor();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isEn = l.locale.languageCode == 'en';
    // Decode the full-screen background at the display's physical width, not the
    // photo's native resolution — a big memory saving on low-end devices.
    final decodeWidth = (MediaQuery.sizeOf(context).width *
            MediaQuery.devicePixelRatioOf(context))
        .round();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(l.t('emotion_${widget.id}_title'),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
        actions: [
          // Background music toggle — plays by default, tap to mute/unmute.
          Consumer<MusicService>(
            builder: (context, music, _) => IconButton(
              tooltip: music.muted
                  ? l.t('praise_music_off')
                  : l.t('praise_music_on'),
              icon: Icon(music.muted ? Icons.music_off : Icons.music_note),
              onPressed: () => music.toggleMute(),
            ),
          ),
          // Read the current verse aloud (text-to-speech).
          Consumer<TtsService>(
            builder: (context, tts, _) {
              final active = tts.isActive('emotion');
              return IconButton(
                tooltip: l.t('praise_play'),
                icon: Icon(active ? Icons.volume_up : Icons.volume_up_outlined),
                onPressed: _verses.isEmpty
                    ? null
                    : () async {
                        try {
                          await tts.toggle('emotion', _verses[_page].text,
                              lang: l.locale.languageCode);
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l.t('tts_unavailable'))),
                            );
                          }
                        }
                      },
              );
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Base colour gradient — always present (fallback + while image loads).
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_tint(0.30), _tint(0.14), _tint(0.08)],
              ),
            ),
          ),
          // Themed stock photo for the current verse — crossfades as you scroll.
          // Wrapped in a RepaintBoundary so scrolling verses / page-indicator
          // animations don't repaint this full-screen image layer.
          RepaintBoundary(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              child: _bg == null
                  ? const SizedBox.shrink()
                  : Stack(
                      key: ValueKey(_bg!.url),
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: _bg!.url,
                          fit: BoxFit.cover,
                          memCacheWidth: decodeWidth,
                          fadeInDuration: const Duration(milliseconds: 400),
                          errorWidget: (_, __, ___) => const SizedBox.shrink(),
                        ),
                        // Dark scrim so the white serif text stays readable.
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.55),
                                Colors.black.withValues(alpha: 0.35),
                                Colors.black.withValues(alpha: 0.62),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          SafeArea(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white))
                : _failed
                    ? _errorView(l)
                    : _pager(l, isEn),
          ),
        ],
      ),
    );
  }

  Widget _errorView(AppLocalizations l) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined,
                  size: 44, color: Colors.white70),
              const SizedBox(height: 12),
              Text(l.t('auth_error_network'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.white24,
                    foregroundColor: Colors.white),
                onPressed: () => _load(_loadedLang ?? 'en'),
                icon: const Icon(Icons.refresh),
                label: Text(l.t('game_retry')),
              ),
            ],
          ),
        ),
      );

  Widget _pager(AppLocalizations l, bool isEn) {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageCtrl,
          scrollDirection: Axis.vertical,
          itemCount: _verses.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (context, i) => _verseCard(_verses[i], isEn),
        ),
        // Vertical page indicator on the right.
        if (_verses.length > 1)
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < _verses.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      width: 7,
                      height: i == _page ? 20 : 7,
                      decoration: BoxDecoration(
                        color: Colors.white
                            .withValues(alpha: i == _page ? 0.95 : 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
            ),
          ),
        // Branding + share at the bottom.
        Positioned(
          left: 0,
          right: 0,
          bottom: 16,
          child: Column(
            children: [
              // Photo attribution (required for Unsplash, courteous for Pexels).
              if (_bg != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _bg!.credit,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.menu_book_rounded,
                      size: 18, color: Colors.white70),
                  const SizedBox(width: 8),
                  Text(l.t('app_name'),
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                ),
                onPressed: _verses.isEmpty ? null : _shareCurrent,
                icon: const Icon(Icons.share_outlined, size: 18),
                label: Text(l.t('share')),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _verseCard(_Verse v, bool isEn) {
    final serif = isEn ? 'serif' : null;
    final words = v.text.trim().split(RegExp(r'\s+'));
    final first = words.isNotEmpty ? words.first : '';
    final rest = words.length > 1 ? words.sublist(1).join(' ') : '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 80, 36, 120),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(first,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: serif,
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      height: 1.2)),
              if (rest.isNotEmpty) const SizedBox(height: 6),
              if (rest.isNotEmpty)
                Text(rest,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: serif,
                        color: Colors.white,
                        fontSize: 26,
                        height: 1.5)),
              const SizedBox(height: 22),
              Text(v.reference,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: serif,
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 18,
                      fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      ),
    );
  }

  void _shareCurrent() {
    if (_verses.isEmpty) return;
    final v = _verses[_page];
    final l = AppLocalizations.of(context);
    Share.share('${v.text}\n\n${v.reference}\n\n— ${l.t('app_name')}');
  }
}
