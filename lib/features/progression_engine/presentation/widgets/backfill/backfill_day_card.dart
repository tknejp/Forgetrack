import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/theme/design_tokens.dart';
import '../../../domain/backfill/daily_backfill_models.dart';
import 'backfill_rows.dart';

class BackfillDayCard extends StatelessWidget {
  const BackfillDayCard({
    super.key,
    required this.entry,
    required this.today,
    required this.dayKey,
    required this.isExpanded,
    required this.onToggle,
    required this.l10n,
    required this.onClaimGoal,
    required this.onClaimQuest,
    required this.onClaimActivity,
    required this.onClaimAllDay,
    required this.isClaimingAll,
    required this.pillKeyFor,
  });

  final DailyBackfillEntry entry;
  final DateTime today;
  final String dayKey;
  final bool isExpanded;
  final VoidCallback onToggle;
  final AppLocalizations l10n;
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

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final pending = entry.pendingCount;
    final claimable = entry.claimableXp;
    final claimed = entry.claimedXp;
    final hasAnyXp = claimed + claimable > 0;
    final dateLabel = _relativeDateLabel(context, entry.date, today, l10n);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggle,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(Tokens.radiusInner),
          border: Border.all(
            color: pending > 0
                ? ft.xp.withValues(alpha: 0.28)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          dateLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        if (hasAnyXp) ...[
                          const SizedBox(height: 2),
                          Text(
                            _summaryLabel(claimed, claimable),
                            style: TextStyle(
                              fontSize: Tokens.fontSizeMicro,
                              fontWeight: FontWeight.w600,
                              color: pending > 0
                                  ? ft.xp
                                  : Tokens.onSurfaceMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (pending > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: ft.xp.withValues(alpha: 0.16),
                        borderRadius:
                            BorderRadius.circular(Tokens.radiusProgress),
                        border: Border.all(
                          color: ft.xp.withValues(alpha: 0.32),
                        ),
                      ),
                      child: Text(
                        l10n.progBackfillPendingChip(pending),
                        style: TextStyle(
                          fontSize: Tokens.fontSizeMicro,
                          fontWeight: FontWeight.w700,
                          color: ft.xp,
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  Icon(
                    isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: Tokens.onSurfaceMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
            if (isExpanded) ...[
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0x14FFFFFF),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (entry.dailyGoals.isNotEmpty) ...[
                      _DaySectionSubheader(
                        label: l10n.progBackfillDayGoalsLabel,
                      ),
                      for (final g in entry.dailyGoals)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: BackfillDailyGoalRow(
                            item: g,
                            day: entry.date,
                            pillKey: pillKeyFor(
                              'goal|${g.nodeId}|$dayKey',
                            ),
                            onClaim: onClaimGoal,
                            l10n: l10n,
                          ),
                        ),
                    ],
                    if (entry.dailyQuests.isNotEmpty) ...[
                      _DaySectionSubheader(
                        label: l10n.progBackfillDayQuestsLabel,
                        topGap: entry.dailyGoals.isNotEmpty,
                      ),
                      for (final q in entry.dailyQuests)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: BackfillDailyQuestRow(
                            item: q,
                            day: entry.date,
                            pillKey: pillKeyFor(
                              'quest|${q.nodeId}|$dayKey',
                            ),
                            onClaim: onClaimQuest,
                            l10n: l10n,
                          ),
                        ),
                    ],
                    if (entry.activities.isNotEmpty) ...[
                      _DaySectionSubheader(
                        label: l10n.progBackfillDayActivitiesLabel,
                        topGap: entry.dailyGoals.isNotEmpty ||
                            entry.dailyQuests.isNotEmpty,
                      ),
                      for (final a in entry.activities)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: BackfillActivityClaimRow(
                            state: a,
                            pillKey: pillKeyFor(
                              'act|${a.record.startTime.millisecondsSinceEpoch}',
                            ),
                            onClaim: onClaimActivity,
                          ),
                        ),
                    ],
                    if (claimable > 0) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _ClaimAllPill(
                          label: l10n.progBackfillClaimAllDay(claimable),
                          isLoading: isClaimingAll,
                          onTap: isClaimingAll
                              ? null
                              : () => onClaimAllDay(entry),
                          accent: ft.xp,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _summaryLabel(int claimed, int claimable) {
    if (claimable == 0) return '+$claimed XP';
    if (claimed == 0) return '+$claimable XP k vyzvednutí';
    return '+$claimed XP · +$claimable XP k vyzvednutí';
  }

  String _relativeDateLabel(
    BuildContext context,
    DateTime day,
    DateTime today,
    AppLocalizations l10n,
  ) {
    final diff = today.difference(day).inDays;
    if (diff == 0) return l10n.progBackfillDayHeaderToday;
    if (diff == 1) return l10n.progBackfillDayHeaderYesterday;
    final locale = Localizations.localeOf(context).toString();
    if (diff < 7) {
      final label = DateFormat.EEEE(locale).format(day);
      return label.isEmpty
          ? label
          : '${label[0].toUpperCase()}${label.substring(1)}';
    }
    return DateFormat('d. MMMM', locale).format(day);
  }
}

/// Tiny uppercased label that introduces a subgroup inside an
/// expanded day card. Mirrors the section-header styling used
/// elsewhere on the quests screen at a smaller scale.
class _DaySectionSubheader extends StatelessWidget {
  const _DaySectionSubheader({required this.label, this.topGap = false});

  final String label;
  final bool topGap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(2, topGap ? 8 : 0, 2, 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: Tokens.fontSizeMicro,
          fontWeight: FontWeight.w700,
          color: Tokens.onSurfaceFaint,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ClaimAllPill extends StatelessWidget {
  const _ClaimAllPill({
    required this.label,
    required this.isLoading,
    required this.onTap,
    required this.accent,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !isLoading;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(Tokens.radiusProgress),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.55,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation(accent),
                  ),
                )
              else
                Icon(Icons.bolt_rounded, size: 11, color: accent),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: Tokens.fontSizeMicro,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
