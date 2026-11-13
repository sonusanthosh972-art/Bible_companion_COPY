import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/bible_models.dart';
import '../../services/bible_service.dart';
import '../../state/settings_state.dart';
import '../../widgets/language_sheet.dart';

/// Reusable chapter reader — renders one chapter's verses for a language.
/// Used by the Bible browser and by the reading-plan screen.
class ChapterReaderScreen extends StatefulWidget {
  const ChapterReaderScreen({
    super.key,
    required this.lang,
    required this.bookId,
    required this.chapter,
    required this.title,
    this.bible,
  });

  final String lang;
  final String bookId;
  final int chapter;
  final String title;
  final BibleService? bible;

  @override
  State<ChapterReaderScreen> createState() => _ChapterReaderScreenState();
}

class _ChapterReaderScreenState extends State<ChapterReaderScreen> {
  late final BibleService _bible = widget.bible ?? BibleService();
  Future<List<BibleVerse>>? _future;
  String? _lang;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Use the live app language so switching language re-fetches the chapter.
    final lang = Provider.of<SettingsState>(context).languageCode;
    if (lang != _lang) {
      _lang = lang;
      _load();
    }
  }

  void _load() {
    _future = _bible.chapterVerses(_lang ?? widget.lang, widget.bookId, widget.chapter);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: const [LanguageAction()],
      ),
      body: FutureBuilder<List<BibleVerse>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
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
                      onPressed: () => setState(_load),
                      icon: const Icon(Icons.refresh),
                      label: Text(l.t('game_retry')),
                    ),
                  ],
                ),
              ),
            );
          }
          final verses = snap.data ?? [];
          return ListView.builder(
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      TextSpan(text: v.text),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
