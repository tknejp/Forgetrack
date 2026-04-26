import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../features/health_connect/application/goals_provider.dart';
import '../../../shared/theme/ft_design_tokens.dart';
import '../../../shared/widgets/ft/ft_date_nav.dart';
import '../../../shared/widgets/ft/ft_drag_reveal_pager.dart';
import '../../../shared/widgets/ft/ft_screen_header.dart';
import '../../../shared/widgets/ft/ft_stat_card.dart';
import '../application/fitness_provider.dart';

class FtSleepScreen extends StatefulWidget {
  const FtSleepScreen({super.key});

  @override
  State<FtSleepScreen> createState() => _FtSleepScreenState();
}

class _FtSleepScreenState extends State<FtSleepScreen> {
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
        FtStatCard(
          icon: '\uD83C\uDF19',
          label: l10n.sleepTitle,
          domain: FtTokens.sleep,
          initiallyExpanded: true,
          collapsible: false,
          stats: [
            FtStatStat(
              value: _formatDuration(duration),
              label: l10n.sleepDuration,
            ),
            FtStatStat(value: bedtime, label: l10n.sleepFellAsleep),
            FtStatStat(value: wakeTime, label: l10n.sleepWokeUp),
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
              color: FtTokens.onSurfaceMuted,
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
      backgroundColor: FtTokens.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => fitness.refresh(),
          color: FtTokens.accent,
          backgroundColor: FtTokens.surface,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Column(
                    children: [
                      FtScreenHeader(
                        greeting: '',
                        title: context.l10n.sleepTitle,
                        leading: Navigator.of(context).canPop()
                            ? _BackButton(
                                onTap: () => Navigator.of(context).maybePop(),
                              )
                            : null,
                      ),
                      const SizedBox(height: 10),
                      FtDateNav(
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
                  child: FtDragRevealPager<DateTime>(
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

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0x0FFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FtTokens.cardBorder),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }
}
