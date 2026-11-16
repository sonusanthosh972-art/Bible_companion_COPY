import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/praise_data.dart';
import '../../services/tts_service.dart';
import '../../widgets/language_sheet.dart';

/// Daily Praise — pick how many praises, press Play, and the app recites an
/// opening line and then praises (from the bundled "1000 Praises of God"
/// dataset) back-to-back until it reaches the chosen count. The praise text is
/// local (instant, no network); only the spoken audio is fetched online, and
/// the next clip is prefetched while the current one plays so there is no gap.
class PraiseScreen extends StatefulWidget {
  const PraiseScreen({super.key});

  @override
  State<PraiseScreen> createState() => _PraiseScreenState();
}

class _PraiseScreenState extends State<PraiseScreen> {
  static const _counts = [100, 200, 500, 750, 1000];
  int _count = 100;
  int _index = 0; // praise shown while idle / last line spoken

  List<PraiseItem> _praises = const [];
  String? _loadedLang;
  TtsService? _tts;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tts = context.read<TtsService>();
    final lang = AppLocalizations.of(context).locale.languageCode;
    if (lang != _loadedLang) {
      _loadedLang = lang;
      PraiseData.load(lang).then((items) {
        if (mounted) setState(() => _praises = items);
      });
    }
  }

  @override
  void deactivate() {
    _tts?.stop(); // stop audio if the user navigates away mid-recitation
    super.deactivate();
  }

  int get _maxIndex =>
      _praises.isEmpty ? 0 : (_count.clamp(1, _praises.length)) - 1;

  Future<void> _onPlayPressed(TtsService tts, AppLocalizations l) async {
    if (tts.isActive('praise')) {
      await tts.stop();
      return;
    }
    if (_praises.isEmpty) return;
    // Playlist: opening line, then praises id 1..N (N = chosen count).
    final n = _count.clamp(1, _praises.length);
    final texts = <String>[
      l.t('praise_intro'),
      for (var i = 0; i < n; i++) _praises[i].text,
    ];
    try {
      await tts.playSequence(
        'praise',
        texts,
        lang: l.locale.languageCode,
        onIndex: (seqPos) {
          if (!mounted) return;
          if (seqPos > 0) setState(() => _index = seqPos - 1);
        },
        onError: () => _notifyUnavailable(l),
      );
    } catch (_) {
      _notifyUnavailable(l);
    }
  }

  void _notifyUnavailable(AppLocalizations l) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.t('tts_unavailable'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tts = context.watch<TtsService>();
    final running = tts.isActive('praise');

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('praise')),
        actions: const [LanguageAction()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _banner(l),
          const SizedBox(height: 20),
          Text(l.t('praise_count_heading'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final c in _counts)
                ChoiceChip(
                  label: Text('$c'),
                  selected: _count == c,
                  onSelected: running
                      ? null
                      : (_) => setState(() {
                            _count = c;
                            _index = 0;
                          }),
                  showCheckmark: false,
                  selectedColor: AppColors.brand,
                  labelStyle: TextStyle(
                    color: _count == c ? Colors.white : null,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _player(l, tts),
        ],
      ),
    );
  }

  Widget _banner(AppLocalizations l) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE6A94D), Color(0xFFB9772E)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l.t('praise').toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(
            '“${l.t('praise_line_12')}”',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontStyle: FontStyle.italic,
                height: 1.4),
          ),
          const SizedBox(height: 6),
          Text('PSALM 150:6',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                  letterSpacing: 2)),
        ],
      ),
    );
  }

  Widget _player(AppLocalizations l, TtsService tts) {
    final running = tts.isActive('praise');
    final loading = running && tts.busy;
    final seqPos = tts.seqPos; // 0 = opening line, 1.._count = praise number
    final introNow = running && seqPos == 0;
    final ready = _praises.isNotEmpty;

    // Text currently on the card.
    String shownText;
    if (!ready) {
      shownText = '…';
    } else if (introNow) {
      shownText = l.t('praise_intro');
    } else {
      final idx = (running ? (seqPos - 1) : _index).clamp(0, _praises.length - 1);
      shownText = _praises[idx].text;
    }

    final pos = running ? seqPos : (ready ? _index + 1 : 0);
    final sliderMax = _count.toDouble();
    final sliderVal = pos.toDouble().clamp(0, sliderMax).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          if (introNow)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                l.t('praise_intro'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13,
                    letterSpacing: 1,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
            alignment: Alignment.center,
            constraints: const BoxConstraints(minHeight: 150),
            child: Text(
              shownText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 21, height: 1.6, fontWeight: FontWeight.w500),
            ),
          ),
          Slider(
            value: sliderVal,
            min: 0,
            max: sliderMax,
            onChanged: (running || !ready)
                ? null
                : (v) =>
                    setState(() => _index = (v.round().clamp(1, _count)) - 1),
          ),
          Text(
            '${pos.clamp(0, _count)} / $_count',
            style:
                TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                onPressed: (running || _index <= 0)
                    ? null
                    : () => setState(() => _index--),
                icon: const Icon(Icons.skip_previous),
                iconSize: 32,
                tooltip: l.t('praise_previous'),
              ),
              const SizedBox(width: 20),
              FloatingActionButton(
                heroTag: 'praise_play',
                elevation: 2,
                onPressed:
                    (loading || !ready) ? null : () => _onPlayPressed(tts, l),
                backgroundColor: AppColors.brand,
                child: loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(running ? Icons.stop : Icons.play_arrow,
                        color: Colors.white, size: 32),
              ),
              const SizedBox(width: 20),
              IconButton(
                onPressed: (running || _index >= _maxIndex)
                    ? null
                    : () => setState(() => _index++),
                icon: const Icon(Icons.skip_next),
                iconSize: 32,
                tooltip: l.t('praise_next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
