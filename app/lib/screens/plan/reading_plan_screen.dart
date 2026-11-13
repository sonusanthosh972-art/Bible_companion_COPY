import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/reading_plan_service.dart';
import '../../state/app_state.dart';
import '../../state/settings_state.dart';
import '../../widgets/common.dart';
import '../../widgets/language_sheet.dart';
import '../bible/chapter_reader.dart';

/// Reading plans (1 year / 6 months / 3 months) with progress + streaks.
class ReadingPlanScreen extends StatefulWidget {
  const ReadingPlanScreen({super.key});

  @override
  State<ReadingPlanScreen> createState() => _ReadingPlanScreenState();
}

class _ReadingPlanScreenState extends State<ReadingPlanScreen> {
  final _service = ReadingPlanService();
  String _planId = '1y';
  int? _selectedDay;

  static const _planNameKey = {
    '1y': 'plan_one_year',
    '6m': 'plan_six_months',
    '3m': 'plan_three_months',
  };

  int get _total => ReadingPlanService.plans[_planId]!;

  int _currentDay(AppState app) {
    final done = app.completedDays(_planId);
    // First day not yet completed (sequential), capped at the last day.
    for (var d = 1; d <= _total; d++) {
      if (!done.contains(d)) return d;
    }
    return _total;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = context.watch<AppState>();
    final lang = context.watch<SettingsState>().languageCode;
    final day = _selectedDay ?? _currentDay(app);
    final doneCount = app.completedDays(_planId).length;
    final isDone = app.isDayDone(_planId, day);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('bible_reading_plan')),
        actions: const [LanguageAction()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Plan picker
          SegmentedButton<String>(
            segments: [
              for (final id in ReadingPlanService.plans.keys)
                ButtonSegment(value: id, label: Text(l.t(_planNameKey[id]!))),
            ],
            selected: {_planId},
            onSelectionChanged: (s) => setState(() {
              _planId = s.first;
              _selectedDay = null;
            }),
          ),
          const SizedBox(height: 16),

          // Progress + streak header
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.circular(22),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.t('plan_progress').replaceAll('{done}', '$doneCount').replaceAll('{total}', '$_total'),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _total == 0 ? 0 : doneCount / _total,
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.white, size: 20),
                    const SizedBox(width: 6),
                    Text('${app.streak} · ${l.t('current_streak')}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('${l.t('longest_streak')}: ${app.longestStreak}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Today's reading
          Row(
            children: [
              Text(l.t('plan_todays_reading'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(l.t('plan_day_of').replaceAll('{day}', '$day').replaceAll('{total}', '$_total'),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Reading>>(
            future: _service.readingsForDay(lang, _planId, day),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final readings = snap.data ?? [];
              if (readings.isEmpty) {
                return AppCard(child: Text(l.t('auth_error_network')));
              }
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final r in readings)
                          ActionChip(
                            avatar: const Icon(Icons.menu_book_outlined, size: 16),
                            label: Text('${r.bookName} ${r.chapter}'),
                            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => ChapterReaderScreen(
                                lang: lang,
                                bookId: r.bookId,
                                chapter: r.chapter,
                                title: '${r.bookName} ${r.chapter}',
                              ),
                            )),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: isDone
                          ? OutlinedButton.icon(
                              onPressed: null,
                              icon: const Icon(Icons.check_circle, color: AppColors.green),
                              label: Text(l.t('reading_complete')),
                            )
                          : FilledButton.icon(
                              onPressed: () async {
                                await context.read<AppState>().markReadingDay(_planId, day);
                                if (context.mounted) setState(() => _selectedDay = null);
                              },
                              icon: const Icon(Icons.check),
                              label: Text(l.t('plan_mark_read')),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Day grid
          Text(l.t('plan'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var d = 1; d <= _total; d++)
                _dayDot(context, d, app.isDayDone(_planId, d), d == day),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _dayDot(BuildContext context, int d, bool done, bool selected) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _selectedDay = d),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: done
              ? AppColors.green
              : (selected ? AppColors.brand.withValues(alpha: 0.18) : Theme.of(context).colorScheme.surface),
          border: Border.all(
            color: selected ? AppColors.brand : Theme.of(context).dividerColor,
            width: selected ? 1.6 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: done
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : Text('$d', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
