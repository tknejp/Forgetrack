import 'package:forgetrack/domain/journal/journal_event.dart';

import '../domain/repository/ledger_snapshot.dart';

/// Pure helpers that derive "perfect day" aggregates from the ledger.
///
/// **Perfect day = every required daily objective was satisfied that
/// day.** The set is fixed at four canonical pillars:
///
///   - `daily_steps`
///   - `daily_calories`
///   - `daily_sleep`
///   - `daily_activity`
///
/// `daily_weight_log` is intentionally excluded — body tracking is
/// opt-in, so requiring it would price-out players who don't weigh
/// daily. The five nutrition macros collapse to `daily_calories` as
/// the canonical food objective for the same reason (requiring all
/// five macro objectives would be punishing on rest / fasting days).
///
/// All helpers are static + side-effect-free so the cosmetic reveal
/// snapshot builder and the engine provider can share the same
/// derivation without dragging a stateful collaborator around.
class PerfectDayLedgerSource {
  const PerfectDayLedgerSource._();

  /// Canonical "perfect day requires these objectives" set. Public so
  /// tests / docs can reference it without re-listing the ids.
  static const Set<String> requiredObjectiveIds = {
    'daily_steps',
    'daily_calories',
    'daily_sleep',
    'daily_activity',
  };

  /// Returns the sorted list of local-day dates on which every
  /// objective in [requiredObjectiveIds] has at least one
  /// [ObjectiveCompletionEvent] whose `periodKey` matches that day.
  ///
  /// Events without a `periodKey` (lifetime-scoped) are skipped — the
  /// daily-goal objectives this set tracks all carry a yyyy-MM-dd
  /// period anchor.
  static List<DateTime> perfectDates(LedgerSnapshot ledger) {
    final byDay = <String, Set<String>>{};
    for (final e in ledger.objectiveCompletions) {
      if (!requiredObjectiveIds.contains(e.objectiveId)) continue;
      final key = e.periodKey;
      if (key == null) continue;
      byDay.putIfAbsent(key, () => <String>{}).add(e.objectiveId);
    }
    final out = <DateTime>[];
    for (final entry in byDay.entries) {
      if (entry.value.length < requiredObjectiveIds.length) continue;
      final parts = entry.key.split('-');
      if (parts.length != 3) continue;
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y == null || m == null || d == null) continue;
      out.add(DateTime(y, m, d));
    }
    out.sort();
    return out;
  }

  /// Longest run of consecutive perfect days in [sortedDates]. Returns
  /// 0 for an empty list.
  static int bestStreak(List<DateTime> sortedDates) {
    if (sortedDates.isEmpty) return 0;
    var best = 1;
    var run = 1;
    for (var i = 1; i < sortedDates.length; i++) {
      final gap = sortedDates[i].difference(sortedDates[i - 1]).inDays;
      if (gap == 1) {
        run += 1;
        if (run > best) best = run;
      } else {
        run = 1;
      }
    }
    return best;
  }

  /// Count of distinct ISO weeks (Monday-anchored) where **all seven
  /// days** appear in [sortedDates] — i.e. the week was a streak of
  /// 7 consecutive perfect days landing on Mon → Sun.
  static int perfectWeeksLifetime(List<DateTime> sortedDates) {
    if (sortedDates.length < 7) return 0;
    final set = sortedDates.toSet();
    final mondays = <DateTime>{};
    for (final d in sortedDates) {
      // ISO week starts on Monday (weekday 1).
      final monday = d.subtract(Duration(days: d.weekday - 1));
      mondays.add(DateTime(monday.year, monday.month, monday.day));
    }
    var count = 0;
    for (final monday in mondays) {
      var allSeven = true;
      for (var i = 0; i < 7; i++) {
        if (!set.contains(monday.add(Duration(days: i)))) {
          allSeven = false;
          break;
        }
      }
      if (allSeven) count += 1;
    }
    return count;
  }
}
