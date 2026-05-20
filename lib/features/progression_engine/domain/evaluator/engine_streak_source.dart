import 'package:meta/meta.dart';

import 'package:forgetrack/domain/progression/catalog/objective.dart';
import 'package:forgetrack/domain/progression/catalog/objective_scope.dart';
import '../repository/ledger_snapshot.dart';

/// Streak summary for one objective or one domain. Same shape as
/// V1's `ProgressionStreakSummary` so UI consumers can swap providers
/// with minimal reshaping.
@immutable
class EngineStreakSummary {
  const EngineStreakSummary({
    required this.currentStreak,
    required this.bestStreak,
    this.latestDate,
    this.lastAchievedDate,
  });

  const EngineStreakSummary.empty()
      : currentStreak = 0,
        bestStreak = 0,
        latestDate = null,
        lastAchievedDate = null;

  /// Consecutive days ending at (or just before) today on which the
  /// objective / domain was achieved.
  final int currentStreak;

  /// Best consecutive run ever recorded.
  final int bestStreak;

  /// The most recent date considered while computing this summary
  /// (used for "stale streak" UI hints).
  final DateTime? latestDate;

  /// The most recent date on which the objective / domain was
  /// achieved.
  final DateTime? lastAchievedDate;
}

/// Computes streak summaries from the ledger.
///
/// Streaks count consecutive days where an objective with
/// [TodayScope] completed for that day. ObjectiveCompletionEvents
/// have periodKey `yyyy-MM-dd` for daily-scoped objectives — those
/// are the only events that contribute. Other scopes (week, lifetime,
/// rolling, chapter) are ignored.
///
/// Domain streaks combine every objective tagged with the same
/// [ProgressionDomain] — a day "counts" if at least one objective in
/// that domain completed.
class EngineStreakSource {
  const EngineStreakSource({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  /// `objectiveId → streak summary`. Only daily-scoped objectives
  /// appear; objectives with non-daily scopes get an empty summary
  /// (caller can ignore them).
  Map<String, EngineStreakSummary> summarizeByObjective({
    required LedgerSnapshot ledger,
    required List<Objective> objectives,
  }) {
    final today = _today();
    final dailyObjectiveIds = {
      for (final o in objectives)
        if (o.scope is TodayScope) o.id,
    };

    final datesByObjective = <String, Set<DateTime>>{};
    for (final e in ledger.objectiveCompletions) {
      if (!dailyObjectiveIds.contains(e.objectiveId)) continue;
      final date = _parsePeriodKey(e.periodKey);
      if (date == null) continue;
      datesByObjective.putIfAbsent(e.objectiveId, () => {}).add(date);
    }

    return {
      for (final id in dailyObjectiveIds)
        id: _summary(datesByObjective[id] ?? const {}, today: today),
    };
  }

  /// `domain → streak summary`. A day counts if any objective tagged
  /// with that domain (and with [TodayScope]) completed that day.
  Map<ProgressionDomain, EngineStreakSummary> summarizeByDomain({
    required LedgerSnapshot ledger,
    required List<Objective> objectives,
  }) {
    final today = _today();
    final domainByObjective = <String, ProgressionDomain>{};
    for (final o in objectives) {
      if (o.scope is! TodayScope) continue;
      final domain = o.domain;
      if (domain == null) continue;
      domainByObjective[o.id] = domain;
    }

    final datesByDomain = <ProgressionDomain, Set<DateTime>>{};
    for (final e in ledger.objectiveCompletions) {
      final domain = domainByObjective[e.objectiveId];
      if (domain == null) continue;
      final date = _parsePeriodKey(e.periodKey);
      if (date == null) continue;
      datesByDomain.putIfAbsent(domain, () => {}).add(date);
    }

    return {
      for (final domain in ProgressionDomain.values)
        domain: _summary(datesByDomain[domain] ?? const {}, today: today),
    };
  }

  EngineStreakSummary _summary(
    Set<DateTime> dates, {
    required DateTime today,
  }) {
    if (dates.isEmpty) {
      return EngineStreakSummary(
        currentStreak: 0,
        bestStreak: 0,
        latestDate: today,
      );
    }
    final sorted = dates.toList()..sort();
    final lastAchieved = sorted.last;

    // Best streak: scan in order, count longest run. Adjacency is
    // checked via the calendar-day successor (`DateTime(y, m, d + 1)`)
    // rather than `curr.difference(prev).inDays == 1` so the run
    // survives DST transitions — a spring-forward gives prev → curr
    // an absolute distance of 23 h, which `inDays` truncates to 0,
    // silently breaking a streak that the calendar sees as
    // contiguous.
    var best = 1;
    var run = 1;
    for (var i = 1; i < sorted.length; i++) {
      final prev = sorted[i - 1];
      final curr = sorted[i];
      if (curr == _dayAfter(prev)) {
        run += 1;
        if (run > best) best = run;
      } else {
        run = 1;
      }
    }

    // Current streak: count consecutive days ending today (or
    // yesterday — a day counts as "still alive" if the player has
    // not yet had a chance to log today).
    //
    // Walks by **calendar day** via `DateTime(y, m, d - 1)`, not by
    // `Duration(days: 1)`. The Duration form subtracts 86 400
    // absolute seconds, which on the day after a DST spring-forward
    // shifts the probe to 23:00 of the previous local day — the
    // dates set is keyed at local midnight, so the lookup misses and
    // the streak silently collapses to 1 around every DST boundary.
    // Calendar-day arithmetic is the only correct shape here.
    var current = 0;
    for (final cursor in [today, _dayBefore(today)]) {
      var probe = cursor;
      while (dates.contains(probe)) {
        current += 1;
        probe = _dayBefore(probe);
      }
      if (current > 0) break;
    }

    return EngineStreakSummary(
      currentStreak: current,
      bestStreak: best,
      latestDate: today,
      lastAchievedDate: lastAchieved,
    );
  }

  DateTime _today() {
    final now = _clock();
    return DateTime(now.year, now.month, now.day);
  }

  /// Calendar-day arithmetic that survives DST transitions. The
  /// `DateTime` constructor normalises out-of-range fields, so
  /// `DateTime(y, m, d - 1)` on the 1st of a month yields the last
  /// day of the previous month — no hand-rolled month length tables
  /// needed.
  DateTime _dayBefore(DateTime d) => DateTime(d.year, d.month, d.day - 1);

  DateTime _dayAfter(DateTime d) => DateTime(d.year, d.month, d.day + 1);

  DateTime? _parsePeriodKey(String? key) {
    if (key == null) return null;
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(key);
    if (match == null) return null;
    return DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }
}
