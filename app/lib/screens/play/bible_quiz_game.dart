import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/bible_models.dart';
import '../../services/bible_service.dart';
import '../../state/app_state.dart';
import '../../state/settings_state.dart';
import '../../widgets/language_sheet.dart';

/// "Guess the Book" — a verse is shown; pick which book it comes from.
/// Fully auto-generated from the Bible API, so it works in every language and
/// needs no question bank. Each correct answer is worth 10 XP.
class BibleQuizGame extends StatefulWidget {
  const BibleQuizGame({super.key});

  static const int questionCount = 10;
  static const int xpPerCorrect = 10;

  @override
  State<BibleQuizGame> createState() => _BibleQuizGameState();
}

class _QuizQuestion {
  final String verseText;
  final BibleBook correct;
  final List<BibleBook> options;
  _QuizQuestion(this.verseText, this.correct, this.options);
}

class _BibleQuizGameState extends State<BibleQuizGame> {
  final _bible = BibleService();
  final _rnd = Random();

  Future<List<_QuizQuestion>>? _future;
  int _index = 0;
  int _score = 0;
  int? _picked; // index into current question's options
  bool _awarded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _buildQuiz(context.read<SettingsState>().languageCode);
  }

  Future<List<_QuizQuestion>> _buildQuiz(String lang) async {
    final books = await _bible.books(lang);
    // Pick more candidate chapters than needed, fetch in parallel, keep the good ones.
    final candidates = List.generate(BibleQuizGame.questionCount + 6, (_) {
      final b = books[_rnd.nextInt(books.length)];
      return (b, 1 + _rnd.nextInt(b.chapterCount));
    });
    final fetched = await Future.wait(candidates.map(
      (c) => _bible
          .chapterVerses(lang, c.$1.id, c.$2)
          .catchError((_) => <BibleVerse>[]),
    ));

    final questions = <_QuizQuestion>[];
    for (var i = 0; i < candidates.length && questions.length < BibleQuizGame.questionCount; i++) {
      final book = candidates[i].$1;
      final usable = fetched[i].where((v) => v.text.trim().length > 25).toList();
      if (usable.isEmpty) continue;
      final verse = usable[_rnd.nextInt(usable.length)];
      final options = <BibleBook>{book};
      while (options.length < 4) {
        options.add(books[_rnd.nextInt(books.length)]);
      }
      final shuffled = options.toList()..shuffle(_rnd);
      questions.add(_QuizQuestion(verse.text, book, shuffled));
    }
    return questions;
  }

  void _answer(_QuizQuestion q, int optionIndex) {
    if (_picked != null) return; // already answered this question
    setState(() {
      _picked = optionIndex;
      if (q.options[optionIndex].id == q.correct.id) _score++;
    });
  }

  void _next(List<_QuizQuestion> qs) {
    if (_index < qs.length - 1) {
      setState(() {
        _index++;
        _picked = null;
      });
    } else {
      setState(() => _index = qs.length); // move to results
      _awardOnce();
    }
  }

  Future<void> _awardOnce() async {
    if (_awarded) return;
    _awarded = true;
    final app = context.read<AppState>();
    await app.recordQuizScore(_score);
    await app.addXp(_score * BibleQuizGame.xpPerCorrect);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('game_bible_quiz')),
        actions: const [LanguageAction()],
      ),
      body: FutureBuilder<List<_QuizQuestion>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final qs = snap.data ?? [];
          if (qs.isEmpty) {
            return _error(l);
          }
          if (_index >= qs.length) {
            return _results(l, qs.length);
          }
          return _question(l, qs);
        },
      ),
    );
  }

  Widget _error(AppLocalizations l) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_outlined, size: 44),
            const SizedBox(height: 12),
            Text(l.t('auth_error_network'), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.t('game_retry')),
            ),
          ]),
        ),
      );

  Widget _question(AppLocalizations l, List<_QuizQuestion> qs) {
    final q = qs[_index];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // progress
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_index + 1} / ${qs.length}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('${l.t('quiz_score_label')}: $_score',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.brand)),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: (_index + 1) / qs.length,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            gradient: AppTheme.brandGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.format_quote, color: Colors.white70),
              const SizedBox(height: 8),
              Text(q.verseText,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 18, height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(l.t('quiz_which_book'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        for (var i = 0; i < q.options.length; i++) _optionTile(l, q, i),
        const SizedBox(height: 12),
        if (_picked != null)
          FilledButton(
            onPressed: () => _next(qs),
            child: Text(_index < qs.length - 1
                ? l.t('game_next_question')
                : l.t('game_see_results')),
          ),
      ],
    );
  }

  Widget _optionTile(AppLocalizations l, _QuizQuestion q, int i) {
    final answered = _picked != null;
    final isCorrect = q.options[i].id == q.correct.id;
    final isPicked = _picked == i;

    Color? bg;
    Color border = Theme.of(context).dividerColor;
    IconData? icon;
    if (answered && isCorrect) {
      bg = AppColors.green.withValues(alpha: 0.15);
      border = AppColors.green;
      icon = Icons.check_circle;
    } else if (answered && isPicked && !isCorrect) {
      bg = AppColors.rose.withValues(alpha: 0.15);
      border = AppColors.rose;
      icon = Icons.cancel;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: bg ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: answered ? null : () => _answer(q, i),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: border, width: 1.4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(q.options[i].name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                if (icon != null) Icon(icon, color: border),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _results(AppLocalizations l, int total) {
    final pct = total == 0 ? 0 : (_score / total);
    final String msgKey;
    if (pct == 1) {
      msgKey = 'game_result_perfect';
    } else if (pct >= 0.7) {
      msgKey = 'game_result_great';
    } else if (pct >= 0.4) {
      msgKey = 'game_result_good';
    } else {
      msgKey = 'game_result_try_again';
    }
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 72, color: AppColors.accent),
            const SizedBox(height: 16),
            Text(l.t('game_quiz_result'),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('${l.t('game_your_score')}: $_score / $total',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text('+${_score * BibleQuizGame.xpPerCorrect} ${l.t('xp_earned')}',
                style: const TextStyle(
                    fontSize: 16, color: AppColors.brand, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Text(l.t(msgKey), textAlign: TextAlign.center),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const BibleQuizGame()),
              ),
              icon: const Icon(Icons.refresh),
              label: Text(l.t('game_retry')),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.t('word_builder_back_to_home')),
            ),
          ],
        ),
      ),
    );
  }
}
