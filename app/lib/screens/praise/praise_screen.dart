import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/tts_service.dart';
import '../../widgets/language_sheet.dart';

/// Daily Praise — pick how many praises, then recite them one by one at your own
/// pace. Original praise lines; the banner verse (Psalm 150:6) is public-domain
/// scripture. No third-party audio or artwork is used.
class PraiseScreen extends StatefulWidget {
  const PraiseScreen({super.key});

  @override
  State<PraiseScreen> createState() => _PraiseScreenState();
}

class _PraiseScreenState extends State<PraiseScreen> {
  static const _counts = [100, 200, 500, 750, 1000];
  int _count = 100;
  int _index = 0;
  bool _music = true;

  // Localized praise lines (keys resolve to the current app language).
  static const _praiseKeys = <String>[
    'praise_line_1', 'praise_line_2', 'praise_line_3', 'praise_line_4',
    'praise_line_5', 'praise_line_6', 'praise_line_7', 'praise_line_8',
    'praise_line_9', 'praise_line_10', 'praise_line_11', 'praise_line_12',
  ];

  String _currentText(AppLocalizations l) =>
      l.t(_praiseKeys[_index % _praiseKeys.length]);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
                  onSelected: (_) => setState(() {
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
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton(
              onPressed: () => setState(() => _index = 0),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              ),
              child: Text(l.t('praise_self_title')),
            ),
          ),
          const SizedBox(height: 20),
          _player(l),
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

  Widget _player(AppLocalizations l) {
    final position = (_index % _count) + 1;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            alignment: Alignment.center,
            child: Text(
              _currentText(l),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, height: 1.6, fontWeight: FontWeight.w500),
            ),
          ),
          Slider(
            value: position.toDouble().clamp(1, _count.toDouble()),
            min: 1,
            max: _count.toDouble(),
            onChanged: (v) => setState(() => _index = v.round() - 1),
          ),
          Text('$position / $_count',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _index > 0 ? () => setState(() => _index--) : null,
                icon: const Icon(Icons.skip_previous),
                iconSize: 32,
              ),
              const SizedBox(width: 12),
              Consumer<TtsService>(
                builder: (context, tts, _) {
                  final active = tts.isActive('praise');
                  final loading = active && tts.busy;
                  return FloatingActionButton(
                    heroTag: 'praise_play',
                    onPressed: () async {
                      try {
                        await tts.toggle('praise', _currentText(l));
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l.t('auth_error_network'))),
                          );
                        }
                      }
                    },
                    backgroundColor: AppColors.brand,
                    child: loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(active ? Icons.stop : Icons.play_arrow,
                            color: Colors.white, size: 32),
                  );
                },
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => setState(() => _index++),
                icon: const Icon(Icons.skip_next),
                iconSize: 32,
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => setState(() => _music = !_music),
                icon: Icon(_music ? Icons.music_note : Icons.music_off,
                    color: AppColors.brand),
                tooltip: _music ? l.t('praise_music_on') : l.t('praise_music_off'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
