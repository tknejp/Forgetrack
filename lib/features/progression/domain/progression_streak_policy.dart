import 'progression_models.dart';

class ProgressionStreakSummary {
  const ProgressionStreakSummary({
    required this.currentStreak,
    required this.bestStreak,
    this.latestPeriodStart,
    this.lastAchievedPeriodStart,
  });

  const ProgressionStreakSummary.empty()
      : currentStreak = 0,
        bestStreak = 0,
        latestPeriodStart = null,
        lastAchievedPeriodStart = null;

  final int currentStreak;
  final int bestStreak;
  final DateTime? latestPeriodStart;
  final DateTime? lastAchievedPeriodStart;
}

class ProgressionStreakPolicy {
  const ProgressionStreakPolicy();

  Map<String, ProgressionStreakSummary> summarizeByRule(
    Iterable<ProgressionEvaluation> evaluations,
  ) {
    final grouped = <String, List<ProgressionEvaluation>>{};
    for (final evaluation in evaluations) {
      grouped.putIfAbsent(evaluation.ruleId, () => []).add(evaluation);
    }

    return {
      for (final entry in grouped.entries) entry.key: summarize(entry.value),
    };
  }

  Map<ProgressionDomain, ProgressionStreakSummary> summarizeByDomain(
    Iterable<ProgressionEvaluation> evaluations,
  ) {
    final grouped = <ProgressionDomain, List<ProgressionEvaluation>>{};
    for (final evaluation in evaluations) {
      grouped.putIfAbsent(evaluation.domain, () => []).add(evaluation);
    }

    return {
      for (final entry in grouped.entries)
        entry.key: _summarizeEntries(_aggregateByPeriod(entry.value)),
    };
  }

  ProgressionStreakSummary summarize(
    Iterable<ProgressionEvaluation> evaluations,
  ) {
    final ordered = evaluations
        .map(
          (evaluation) => _StreakEntry(
            periodKind: evaluation.period.kind,
            periodStart: evaluation.period.start,
            achieved: evaluation.achieved,
          ),
        )
        .toList();

    return _summarizeEntries(ordered);
  }

  ProgressionStreakSummary _summarizeEntries(
    List<_StreakEntry> entries,
  ) {
    final ordered = [...entries]
      ..sort((a, b) => a.periodStart.compareTo(b.periodStart));

    if (ordered.isEmpty) {
      return const ProgressionStreakSummary.empty();
    }

    var bestStreak = 0;
    var runningStreak = 0;

    for (var index = 0; index < ordered.length; index++) {
      final current = ordered[index];
      final previous = index > 0 ? ordered[index - 1] : null;
      final consecutive = previous != null && _isConsecutive(previous, current);

      if (!current.achieved) {
        runningStreak = 0;
        continue;
      }

      runningStreak = consecutive ? runningStreak + 1 : 1;
      if (runningStreak > bestStreak) {
        bestStreak = runningStreak;
      }
    }

    final latest = ordered.last;
    final currentStreak = _currentStreak(ordered);
    final lastAchieved = ordered.lastWhere(
      (entry) => entry.achieved,
      orElse: () => latest,
    );

    return ProgressionStreakSummary(
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      latestPeriodStart: latest.periodStart,
      lastAchievedPeriodStart:
          lastAchieved.achieved ? lastAchieved.periodStart : null,
    );
  }

  List<_StreakEntry> _aggregateByPeriod(
    List<ProgressionEvaluation> evaluations,
  ) {
    final aggregated = <String, _StreakEntry>{};

    for (final evaluation in evaluations) {
      final key =
          '${evaluation.period.kind.name}|${progressionDateKey(evaluation.period.start)}';
      final existing = aggregated[key];
      if (existing == null) {
        aggregated[key] = _StreakEntry(
          periodKind: evaluation.period.kind,
          periodStart: evaluation.period.start,
          achieved: evaluation.achieved,
        );
        continue;
      }

      aggregated[key] = _StreakEntry(
        periodKind: existing.periodKind,
        periodStart: existing.periodStart,
        // Domain streak default: a period counts when at least one domain rule succeeded.
        achieved: existing.achieved || evaluation.achieved,
      );
    }

    return aggregated.values.toList();
  }

  int _currentStreak(List<_StreakEntry> ordered) {
    var streak = 0;

    for (var index = ordered.length - 1; index >= 0; index--) {
      final current = ordered[index];
      if (!current.achieved) {
        break;
      }

      if (streak > 0) {
        final nextMoreRecent = ordered[index + 1];
        if (!_isConsecutive(current, nextMoreRecent)) {
          break;
        }
      }

      streak++;
    }

    return streak;
  }

  bool _isConsecutive(
    _StreakEntry previous,
    _StreakEntry current,
  ) {
    if (previous.periodKind != current.periodKind) {
      return false;
    }

    final expectedNextStart = switch (previous.periodKind) {
      ProgressionPeriodKind.day =>
        previous.periodStart.add(const Duration(days: 1)),
      ProgressionPeriodKind.week =>
        previous.periodStart.add(const Duration(days: 7)),
    };

    return progressionDate(expectedNextStart) ==
        progressionDate(current.periodStart);
  }
}

class _StreakEntry {
  const _StreakEntry({
    required this.periodKind,
    required this.periodStart,
    required this.achieved,
  });

  final ProgressionPeriodKind periodKind;
  final DateTime periodStart;
  final bool achieved;
}
