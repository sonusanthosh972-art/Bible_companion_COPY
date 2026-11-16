import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/bible_models.dart';
import '../../services/bible_service.dart';
import '../../services/tts_service.dart';
import '../../state/settings_state.dart';
import '../../widgets/language_sheet.dart';

/// Bible browser — Books / Chapters / Verses tabs with search and an
/// Old/New Testament toggle, matching the original app's structure.
class BibleScreen extends StatefulWidget {
  const BibleScreen({super.key});

  @override
  State<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen> with SingleTickerProviderStateMixin {
  final _bible = BibleService();
  late final TabController _tabs = TabController(length: 3, vsync: this);

  Future<List<BibleBook>>? _booksFuture;
  String? _loadedLang;
  String _query = '';
  bool _newTestament = false;
  BibleBook? _book;
  int? _chapter;

  // Generic icon + color per book (original styling, not copied artwork).
  static const _styles = <(IconData, Color)>[
    (Icons.public, AppColors.green),
    (Icons.local_fire_department, AppColors.rose),
    (Icons.description_outlined, AppColors.accent),
    (Icons.explore_outlined, AppColors.brand),
    (Icons.menu_book_outlined, AppColors.purple),
    (Icons.auto_stories_outlined, AppColors.teal),
    (Icons.favorite_outline, AppColors.rose),
    (Icons.star_outline, AppColors.accent),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = Provider.of<SettingsState>(context).languageCode;
    if (lang != _loadedLang) {
      _loadedLang = lang;
      _booksFuture = _bible.books(lang);
      _book = null;
      _chapter = null;
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _openBook(BibleBook b) {
    setState(() {
      _book = b;
      _chapter = null;
    });
    _tabs.animateTo(1);
  }

  void _openChapter(int c) {
    setState(() => _chapter = c);
    _tabs.animateTo(2);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('holy_bible')),
        actions: const [LanguageAction()],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.brand,
          indicatorColor: AppColors.brand,
          tabs: [
            Tab(text: l.t('books')),
            Tab(text: l.t('chapters')),
            Tab(text: l.t('verses')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _booksTab(l),
          _chaptersTab(l),
          _versesTab(l),
        ],
      ),
    );
  }

  // ---- Books ----
  Widget _booksTab(AppLocalizations l) {
    return FutureBuilder<List<BibleBook>>(
      future: _booksFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return _error(l, () => setState(() => _booksFuture = _bible.books(_loadedLang ?? 'en')));
        }
        final all = snap.data ?? [];
        final byTestament =
            all.where((b) => _newTestament ? b.order >= 40 : b.order <= 39);
        final filtered = _query.isEmpty
            ? byTestament
            : all.where((b) => b.name.toLowerCase().contains(_query.toLowerCase()));
        final books = filtered.toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'John 3:16, ${l.t('books').toLowerCase()}…',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            if (_query.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    _testamentTab(l.t('old_testament'), !_newTestament,
                        () => setState(() => _newTestament = false)),
                    const SizedBox(width: 24),
                    _testamentTab(l.t('new_testament'), _newTestament,
                        () => setState(() => _newTestament = true)),
                  ],
                ),
              ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: books.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final b = books[i];
                  final (icon, color) = _styles[b.order % _styles.length];
                  return Material(
                    color: AppTheme.card(context),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _openBook(b),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(icon, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(b.name,
                                  style: const TextStyle(
                                      fontSize: 17, fontWeight: FontWeight.w700)),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _testamentTab(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? AppColors.brand
                      : Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          if (selected)
            Container(width: 30, height: 3, color: AppColors.brand)
          else
            const SizedBox(height: 3),
        ],
      ),
    );
  }

  // ---- Chapters ----
  Widget _chaptersTab(AppLocalizations l) {
    if (_book == null) {
      return _hint(l.t('books'));
    }
    return Column(
      children: [
        _crumb(_book!.name),
        Expanded(
          child: GridView.count(
            crossAxisCount: 5,
            padding: const EdgeInsets.all(16),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              for (var c = 1; c <= _book!.chapterCount; c++)
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openChapter(c),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.card(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text('$c',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ---- Verses ----
  Widget _versesTab(AppLocalizations l) {
    if (_book == null || _chapter == null) {
      return _hint(l.t('chapters'));
    }
    return Column(
      children: [
        _crumb('${_book!.name} ${l.t('chapters')} $_chapter'),
        Expanded(
          child: FutureBuilder<List<BibleVerse>>(
            future: _bible.chapterVerses(_loadedLang ?? 'en', _book!.id, _chapter!),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return _error(l, () => setState(() {}));
              }
              final verses = snap.data ?? [];
              return Column(
                children: [
                  _readAloudBar(verses),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: verses.length,
                      itemBuilder: (context, i) {
                        final v = verses[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: RichText(
                            text: TextSpan(
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(height: 1.75),
                              children: [
                                TextSpan(
                                  text: '${v.number}  ',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, color: AppColors.brand),
                                ),
                                TextSpan(text: v.text),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _readAloudBar(List<BibleVerse> verses) {
    final l = AppLocalizations.of(context);
    final id = 'bible-${_book!.id}-$_chapter';
    final text = verses.map((v) => v.text).join('  ');
    return Consumer<TtsService>(
      builder: (context, tts, _) {
        final active = tts.isActive(id);
        final loading = active && tts.busy;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () async {
                try {
                  await tts.toggle(id, text, lang: l.locale.languageCode);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.t('tts_unavailable'))),
                    );
                  }
                }
              },
              icon: loading
                  ? const SizedBox(
                      width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(active ? Icons.stop_circle_outlined : Icons.volume_up_outlined),
              label: Text(active ? l.t('praise_pause') : l.t('praise_play')),
            ),
          ),
        );
      },
    );
  }

  Widget _crumb(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: AppColors.brand.withValues(alpha: 0.08),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.brand)),
      );

  Widget _hint(String whatToPick) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app_outlined,
                  size: 44, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 12),
              Text('→ $whatToPick', textAlign: TextAlign.center),
            ],
          ),
        ),
      );

  Widget _error(AppLocalizations l, VoidCallback onRetry) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 44),
              const SizedBox(height: 12),
              Text(l.t('auth_error_network'), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(l.t('game_retry')),
              ),
            ],
          ),
        ),
      );
}
