import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../features/health_connect/application/goals_provider.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/date_nav.dart';
import '../../../shared/widgets/drag_reveal_pager.dart';
import '../../../shared/widgets/ft_back_button.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../../shared/widgets/stat_card.dart';
import '../application/fitness_provider.dart';

class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = _today();
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _previousDate(DateTime date) =>
      date.subtract(const Duration(days: 1));

  DateTime _nextDate(DateTime date) => date.add(const Duration(days: 1));

  bool _hasNextDate(DateTime date) => date.isBefore(_today());

  String _formatDuration(Duration? duration) {
    if (duration == null) return '--';
    final hours = duration.inHours;
    final minutes = duration.inMinutes - hours * 60;
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  Widget _buildDateContent(
    BuildContext context,
    DateTime date,
    FitnessProvider fitness,
    GoalsProvider goals,
  ) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final sleep = fitness.sleepForDate(date);
    final duration = sleep?.totalDuration;
    final bedtime = sleep?.sleepStart != null
        ? DateFormat('HH:mm', locale).format(sleep!.sleepStart)
        : '--:--';
    final wakeTime = sleep?.wakeTime != null
        ? DateFormat('HH:mm', locale).format(sleep!.wakeTime)
        : '--:--';
    final goalMinutes = goals.sleepHours * 60;
    final progress = duration != null
        ? (duration.inMinutes / goalMinutes).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatCard(
          icon: '\uD83C\uDF19',
          label: l10n.sleepTitle,
          domain: Tokens.sleep,
          initiallyExpanded: true,
          collapsible: false,
          stats: [
            StatStat(
              value: _formatDuration(duration),
              label: l10n.sleepDuration,
            ),
            StatStat(value: bedtime, label: l10n.sleepFellAsleep),
            StatStat(value: wakeTime, label: l10n.sleepWokeUp),
          ],
          progress: progress,
          badge: duration != null ? '${(progress * 100).round()}%' : null,
        ),
        if (duration == null) ...[
          const SizedBox(height: 10),
          Text(
            l10n.bodyNoData,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Tokens.onSurfaceMuted,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final fitness = context.watch<FitnessProvider>();
    final goals = context.watch<GoalsProvider>();

    return Scaffold(
      backgroundColor: Tokens.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => fitness.refresh(),
          color: Tokens.accent,
          backgroundColor: Tokens.surface,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Column(
                    children: [
                      ScreenHeader(
                        greeting: '',
                        title: context.l10n.sleepTitle,
                        leading: Navigator.of(context).canPop()
                            ? const FtBackButton()
                            : null,
                      ),
                      const SizedBox(height: 10),
                      DateNav(
                        date: _selectedDate,
                        onPrev: () => setState(
                            () => _selectedDate = _previousDate(_selectedDate)),
                        onNext: _hasNextDate(_selectedDate)
                            ? () => setState(
                                () => _selectedDate = _nextDate(_selectedDate))
                            : null,
                        showTodayButton: _selectedDate != _today(),
                        onTodayTap: () =>
                            setState(() => _selectedDate = _today()),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                  child: DragRevealPager<DateTime>(
                    item: _selectedDate,
                    hasPrevious: (_) => true,
                    hasNext: _hasNextDate,
                    previousOf: _previousDate,
                    nextOf: _nextDate,
                    onCommit: (date) => setState(() => _selectedDate = date),
                    builder: (context, date) =>
                        _buildDateContent(context, date, fitness, goals),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
