import 'package:flutter/foundation.dart';

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
/// have periodKey `yyyy-MM-dd` for daily-scoped objectives â€” those
/// are the only events that contribute. Other scopes (week, lifetime,
/// rolling, chapter) are ignored.
///
/// Domain streaks combine every objective tagged with the same
/// [ProgressionDomain] â€” a day "counts" if at least one objective in
/// that domain completed.
class EngineStreakSource {
  const EngineStreakSource({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  /// `objectiveId â†’ streak summary`. Only daily-scoped objectives
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

  /// `domain â†’ streak summary`. A day counts if any objective tagged
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

    // Best streak: scan in order, count longest run.
    var best = 1;
    var run = 1;
    for (var i = 1; i < sorted.length; i++) {
      final prev = sorted[i - 1];
      final curr = sorted[i];
      if (curr.difference(prev).inDays == 1) {
        run += 1;
        if (run > best) best = run;
      } else {
        run = 1;
      }
    }

    // Current streak: count consecutive days ending today (or
    // yesterday â€” a day counts as "still alive" if the player has
    // not yet had a chance to log today).
    var current = 0;
    for (final cursor in [today, today.subtract(const Duration(days: 1))]) {
      var probe = cursor;
      while (dates.contains(probe)) {
        current += 1;
        probe = probe.subtract(const Duration(days: 1));
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
