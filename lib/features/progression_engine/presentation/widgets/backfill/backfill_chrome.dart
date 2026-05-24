import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/theme/design_tokens.dart';
import '../../../domain/backfill/daily_backfill_models.dart';
import 'backfill_day_card.dart';
import 'backfill_rows.dart';

/// Section list builder: turns the chronological [entries] into
/// week-group headers + [BackfillDayCard] tiles separated by 6 px gaps.
class BackfillList extends StatelessWidget {
  const BackfillList({
    super.key,
    required this.entries,
    required this.today,
    required this.l10n,
    required this.expandedDayKey,
    required this.onToggle,
    required this.onClaimGoal,
    required this.onClaimQuest,
    required this.onClaimActivity,
    required this.onClaimAllDay,
    required this.isClaimingAll,
    required this.pillKeyFor,
    required this.dayKeyOf,
  });

  final List<DailyBackfillEntry> entries;
  final DateTime today;
  final AppLocalizations l10n;
  final String? expandedDayKey;
  final void Function(String dayKey) onToggle;
  final Future<void> Function(
    DailyGoalClaimItem item,
    DateTime day,
    Offset? sparkleFrom,
  ) onClaimGoal;
  final Future<void> Function(
    DailyQuestClaimItem item,
    DateTime day,
    Offset? sparkleFrom,
  ) onClaimQuest;
  final Future<void> Function(ActivityClaimRef ref, Offset? sparkleFrom)
      onClaimActivity;
  final Future<void> Function(DailyBackfillEntry entry) onClaimAllDay;
  final bool isClaimingAll;
  final GlobalKey Function(String composite) pillKeyFor;
  final String Function(DateTime day) dayKeyOf;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[];
    int? lastWeekIndex;
    for (final e in entries) {
      final weekIdx = _weeksAgo(e.date, today);
      if (weekIdx != lastWeekIndex) {
        tiles.add(BackfillWeekGroupHeader(
          label: _groupLabel(weekIdx, l10n),
        ));
        lastWeekIndex = weekIdx;
      }
      final dKey = dayKeyOf(e.date);
      tiles.add(
        BackfillDayCard(
          entry: e,
          today: today,
          dayKey: dKey,
          isExpanded: expandedDayKey == dKey,
          onToggle: () => onToggle(dKey),
          l10n: l10n,
          onClaimGoal: onClaimGoal,
          onClaimQuest: onClaimQuest,
          onClaimActivity: onClaimActivity,
          onClaimAllDay: onClaimAllDay,
          isClaimingAll: isClaimingAll,
          pillKeyFor: pillKeyFor,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          tiles[i],
        ],
      ],
    );
  }

  String _groupLabel(int weeksAgo, AppLocalizations l10n) {
    if (weeksAgo == 0) return l10n.progBackfillGroupThisWeek;
    if (weeksAgo == 1) return l10n.progBackfillGroupLastWeek;
    if (weeksAgo < 4) return l10n.progBackfillGroupWeeksAgo(weeksAgo);
    final monthsAgo = (weeksAgo / 4).floor();
    if (monthsAgo == 1) return l10n.progBackfillGroupMonthAgo;
    return l10n.progBackfillGroupMonthsAgo(monthsAgo);
  }

  /// Number of full calendar weeks between [day] and [today] when
  /// weeks anchor on Monday (Czech convention).
  int _weeksAgo(DateTime day, DateTime today) {
    final mondayOfToday =
        today.subtract(Duration(days: today.weekday - DateTime.monday));
    final mondayOfDay =
        day.subtract(Duration(days: day.weekday - DateTime.monday));
    return mondayOfToday.difference(mondayOfDay).inDays ~/ 7;
  }
}

class BackfillWeekGroupHeader extends StatelessWidget {
  const BackfillWeekGroupHeader({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, Tokens.spaceMd, 4, Tokens.spaceXs),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: Tokens.fontSizeMicro,
          fontWeight: FontWeight.w700,
          color: Tokens.onSurfaceMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class BackfillShowMoreButton extends StatelessWidget {
  const BackfillShowMoreButton({
    super.key,
    required this.label,
    required this.onTap,
  });
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          '$label →',
          style: const TextStyle(
            fontSize: Tokens.fontSizeCaption,
            fontWeight: FontWeight.w700,
            color: Tokens.accent,
          ),
        ),
      ),
    );
  }
}
