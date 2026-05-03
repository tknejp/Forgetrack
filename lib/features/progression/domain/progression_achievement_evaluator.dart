import 'perfect_period_evaluator.dart';
import 'progression_models.dart';
import 'progression_streak_policy.dart';

class ProgressionAchievementEvaluator {
  const ProgressionAchievementEvaluator({
    PerfectPeriodEvaluator perfectPeriodEvaluator =
        const RealPerfectPeriodEvaluator(),
  }) : _perfectPeriodEvaluator = perfectPeriodEvaluator;

  final PerfectPeriodEvaluator _perfectPeriodEvaluator;

  /// Combo quests of any kind — used by `comboQuestsCompletedAtLeast`.
  /// Mirrors the `daily_*_today` mastery quests in
  /// `progression_quest_catalog.dart`.
  static const Set<String> _kComboQuestIds = <String>{
    'daily_two_goals_today',
    'daily_triple_win_today',
    'daily_four_pillars_today',
    'daily_nutrition_combo_today',
    'daily_recovery_focus_today',
  };

  /// Subset of [_kComboQuestIds] that requires three or more daily goals
  /// in one day. Used by `tripleComboQuestsCompletedAtLeast`.
  static const Set<String> _kTripleComboQuestIds = <String>{
    'daily_triple_win_today',
    'daily_four_pillars_today',
  };

  List<ProgressionAchievement> evaluate({
    required List<ProgressionAchievementDefinition> definitions,
    required ProgressionProfile profile,
    required List<ProgressionEvaluation> evaluations,
    required List<ProgressionRewardGrant> rewardGrants,
    required List<ProgressionQuestRewardGrant> questRewardGrants,
    required Map<String, ProgressionStreakSummary> streaksByRuleId,
    required Map<ProgressionDomain, ProgressionStreakSummary> streaksByDomain,
    Map<String, DateTime> existingUnlocks = const {},
    Map<String, ProgressionQuestCategory> questCategoryById = const {},
  }) {
    final orderedDefinitions = [...definitions]
      ..sort((a, b) => a.id.compareTo(b.id));
    return [
      for (final definition in orderedDefinitions)
        _evaluateDefinition(
          definition: definition,
          profile: profile,
          evaluations: evaluations,
          rewardGrants: rewardGrants,
          questRewardGrants: questRewardGrants,
          streaksByRuleId: streaksByRuleId,
          streaksByDomain: streaksByDomain,
          existingUnlocks: existingUnlocks,
          questCategoryById: questCategoryById,
        ),
    ];
  }

  double _safeProgress(int currentValue, int targetValue) {
    if (targetValue <= 0) return currentValue > 0 ? 1 : 0;
    final ratio = currentValue / targetValue;
    if (ratio.isNaN || ratio.isInfinite) return currentValue > 0 ? 1 : 0;
    return ratio.clamp(0, 1).toDouble();
  }

  ProgressionAchievement _evaluateDefinition({
    required ProgressionAchievementDefinition definition,
    required ProgressionProfile profile,
    required List<ProgressionEvaluation> evaluations,
    required List<ProgressionRewardGrant> rewardGrants,
    required List<ProgressionQuestRewardGrant> questRewardGrants,
    required Map<String, ProgressionStreakSummary> streaksByRuleId,
    required Map<ProgressionDomain, ProgressionStreakSummary> streaksByDomain,
    required Map<String, DateTime> existingUnlocks,
    required Map<String, ProgressionQuestCategory> questCategoryById,
  }) {
    // If a persisted unlock record exists, use it as the authoritative state.
    final persistedUnlockedAt = existingUnlocks[definition.id];
    if (persistedUnlockedAt != null) {
      final currentValue = _currentValue(
        definition: definition,
        profile: profile,
        evaluations: evaluations,
        rewardGrants: rewardGrants,
        questRewardGrants: questRewardGrants,
        streaksByRuleId: streaksByRuleId,
        streaksByDomain: streaksByDomain,
        questCategoryById: questCategoryById,
      );
      return ProgressionAchievement(
        id: definition.id,
        type: definition.type,
        difficulty: definition.difficulty,
        criterionType: definition.criterionType,
        title: definition.title,
        description: definition.description,
        targetValue: definition.targetValue,
        currentValue: currentValue,
        progress: _safeProgress(currentValue, definition.targetValue),
        unlocked: true,
        unlockedAt: persistedUnlockedAt,
        ruleId: definition.ruleId,
        domain: definition.domain,
        relatedRuleIds: definition.relatedRuleIds,
      );
    }

    final currentValue = _currentValue(
      definition: definition,
      profile: profile,
      evaluations: evaluations,
      rewardGrants: rewardGrants,
      questRewardGrants: questRewardGrants,
      streaksByRuleId: streaksByRuleId,
      streaksByDomain: streaksByDomain,
      questCategoryById: questCategoryById,
    );
    final unlocked = currentValue >= definition.targetValue;
    final unlockedAt = unlocked
        ? _resolveUnlockedAt(
            definition: definition,
            evaluations: evaluations,
            rewardGrants: rewardGrants,
            questRewardGrants: questRewardGrants,
            profile: profile,
          )
        : null;

    return ProgressionAchievement(
      id: definition.id,
      type: definition.type,
      difficulty: definition.difficulty,
      criterionType: definition.criterionType,
      title: definition.title,
      description: definition.description,
      targetValue: definition.targetValue,
      currentValue: currentValue,
      progress: _safeProgress(currentValue, definition.targetValue),
      unlocked: unlocked,
      unlockedAt: unlockedAt,
      ruleId: definition.ruleId,
      domain: definition.domain,
      relatedRuleIds: definition.relatedRuleIds,
    );
  }

  int _currentValue({
    required ProgressionAchievementDefinition definition,
    required ProgressionProfile profile,
    required List<ProgressionEvaluation> evaluations,
    required List<ProgressionRewardGrant> rewardGrants,
    required List<ProgressionQuestRewardGrant> questRewardGrants,
    required Map<String, ProgressionStreakSummary> streaksByRuleId,
    required Map<ProgressionDomain, ProgressionStreakSummary> streaksByDomain,
    required Map<String, ProgressionQuestCategory> questCategoryById,
  }) {
    switch (definition.criterionType) {
      case ProgressionAchievementCriterionType.totalXpAtLeast:
        return profile.totalXp;
      case ProgressionAchievementCriterionType.rewardCountAtLeast:
        return rewardGrants.where((grant) {
          if (definition.ruleId != null && grant.ruleId != definition.ruleId) {
            return false;
          }
          if (definition.domain != null && grant.domain != definition.domain) {
            return false;
          }
          return true;
        }).length;
      case ProgressionAchievementCriterionType.bestStreakAtLeast:
        if (definition.ruleId != null) {
          return streaksByRuleId[definition.ruleId]?.bestStreak ?? 0;
        }
        if (definition.domain != null) {
          return streaksByDomain[definition.domain]?.bestStreak ?? 0;
        }
        return 0;
      case ProgressionAchievementCriterionType.totalRuleValueAtLeast:
        return _matchingEvaluations(
          definition: definition,
          evaluations: evaluations,
        )
            .fold<double>(
              0,
              (sum, evaluation) => sum + evaluation.actualValue,
            )
            .round();
      case ProgressionAchievementCriterionType
            .bestRollingWindowRuleValueAtLeast:
        return _bestRollingWindowValue(
          definition: definition,
          evaluations: evaluations,
        ).round();
      case ProgressionAchievementCriterionType.dailyQuestsCompletedAtLeast:
        return _countQuestsByCategory(
          questRewardGrants: questRewardGrants,
          questCategoryById: questCategoryById,
          category: ProgressionQuestCategory.daily,
        );
      case ProgressionAchievementCriterionType.weeklyQuestsCompletedAtLeast:
        return _countQuestsByCategory(
          questRewardGrants: questRewardGrants,
          questCategoryById: questCategoryById,
          category: ProgressionQuestCategory.weekly,
        );
      case ProgressionAchievementCriterionType.totalQuestsCompletedAtLeast:
        return questRewardGrants.length;
      case ProgressionAchievementCriterionType.activeDaysAtLeast:
        return _countActiveDays(evaluations);
      case ProgressionAchievementCriterionType.perfectDaysAtLeast:
        return _perfectPeriodEvaluator.countPerfectDays(evaluations);
      case ProgressionAchievementCriterionType.perfectWeeksAtLeast:
        return _perfectPeriodEvaluator.countPerfectWeeks(evaluations);
      case ProgressionAchievementCriterionType.comboQuestsCompletedAtLeast:
        return _countQuestsInIdSet(
          questRewardGrants: questRewardGrants,
          idSet: _kComboQuestIds,
        );
      case ProgressionAchievementCriterionType
            .tripleComboQuestsCompletedAtLeast:
        return _countQuestsInIdSet(
          questRewardGrants: questRewardGrants,
          idSet: _kTripleComboQuestIds,
        );
    }
  }

  int _countQuestsInIdSet({
    required List<ProgressionQuestRewardGrant> questRewardGrants,
    required Set<String> idSet,
  }) {
    var count = 0;
    for (final grant in questRewardGrants) {
      if (idSet.contains(grant.questId)) count++;
    }
    return count;
  }

  int _countQuestsByCategory({
    required List<ProgressionQuestRewardGrant> questRewardGrants,
    required Map<String, ProgressionQuestCategory> questCategoryById,
    required ProgressionQuestCategory category,
  }) {
    var count = 0;
    for (final grant in questRewardGrants) {
      if (questCategoryById[grant.questId] == category) count++;
    }
    return count;
  }

  int _countActiveDays(List<ProgressionEvaluation> evaluations) {
    return <DateTime>{
      for (final evaluation in evaluations)
        progressionDate(evaluation.period.start),
    }.length;
  }

  DateTime? _resolveUnlockedAt({
    required ProgressionAchievementDefinition definition,
    required List<ProgressionEvaluation> evaluations,
    required List<ProgressionRewardGrant> rewardGrants,
    required List<ProgressionQuestRewardGrant> questRewardGrants,
    required ProgressionProfile profile,
  }) {
    switch (definition.criterionType) {
      case ProgressionAchievementCriterionType.rewardCountAtLeast:
        final matching = rewardGrants.where((grant) {
          if (definition.ruleId != null && grant.ruleId != definition.ruleId) {
            return false;
          }
          if (definition.domain != null && grant.domain != definition.domain) {
            return false;
          }
          return true;
        }).toList()
          ..sort((a, b) => a.progressionAt.compareTo(b.progressionAt));

        if (matching.length < definition.targetValue) return null;
        return matching[definition.targetValue - 1].progressionAt;
      case ProgressionAchievementCriterionType.totalXpAtLeast:
        final ordered = _xpEvents(
          rewardGrants: rewardGrants,
          questRewardGrants: questRewardGrants,
        )..sort((a, b) => a.at.compareTo(b.at));
        var runningXp = 0;
        for (final event in ordered) {
          runningXp += event.xp;
          if (runningXp >= definition.targetValue) {
            return event.at;
          }
        }
        return profile.totalXp >= definition.targetValue && ordered.isNotEmpty
            ? ordered.last.at
            : null;
      case ProgressionAchievementCriterionType.bestStreakAtLeast:
        final relevant = evaluations.where((evaluation) {
          if (definition.ruleId != null &&
              evaluation.ruleId != definition.ruleId) {
            return false;
          }
          if (definition.domain != null &&
              evaluation.domain != definition.domain) {
            return false;
          }
          return true;
        }).toList()
          ..sort((a, b) => a.period.start.compareTo(b.period.start));

        if (relevant.isEmpty) return null;
        return _resolveStreakUnlockedAt(
          evaluations: relevant,
          streakTarget: definition.targetValue,
          aggregateByPeriod: definition.domain != null,
        );
      case ProgressionAchievementCriterionType.totalRuleValueAtLeast:
        final ordered = _matchingEvaluations(
          definition: definition,
          evaluations: evaluations,
        )..sort((a, b) {
            final byPeriod = a.period.start.compareTo(b.period.start);
            if (byPeriod != 0) return byPeriod;
            return a.evaluationKey.compareTo(b.evaluationKey);
          });

        var running = 0.0;
        for (final evaluation in ordered) {
          running += evaluation.actualValue;
          if (running >= definition.targetValue) {
            return evaluation.period.start;
          }
        }
        return null;
      case ProgressionAchievementCriterionType
            .bestRollingWindowRuleValueAtLeast:
        return _resolveRollingWindowUnlockedAt(
          definition: definition,
          evaluations: evaluations,
        );
      // Phase 3a additions: precise unlock-time resolution for these
      // criterion types is not implemented yet. Returning null is safe — the
      // achievement still unlocks, but the unlockedAt timestamp stays null
      // (UI shows "recently unlocked"). Could be backfilled from the quest
      // grant ledger / evaluation list in a follow-up.
      case ProgressionAchievementCriterionType.dailyQuestsCompletedAtLeast:
      case ProgressionAchievementCriterionType.weeklyQuestsCompletedAtLeast:
      case ProgressionAchievementCriterionType.totalQuestsCompletedAtLeast:
      case ProgressionAchievementCriterionType.activeDaysAtLeast:
      case ProgressionAchievementCriterionType.perfectDaysAtLeast:
      case ProgressionAchievementCriterionType.perfectWeeksAtLeast:
      case ProgressionAchievementCriterionType.comboQuestsCompletedAtLeast:
      case ProgressionAchievementCriterionType
            .tripleComboQuestsCompletedAtLeast:
        return null;
    }
  }

  List<ProgressionEvaluation> _matchingEvaluations({
    required ProgressionAchievementDefinition definition,
    required List<ProgressionEvaluation> evaluations,
  }) {
    return evaluations.where((evaluation) {
      if (definition.ruleId != null && evaluation.ruleId != definition.ruleId) {
        return false;
      }
      if (definition.domain != null && evaluation.domain != definition.domain) {
        return false;
      }
      if (definition.relatedRuleIds.isNotEmpty &&
          !definition.relatedRuleIds.contains(evaluation.ruleId)) {
        return false;
      }
      return true;
    }).toList();
  }

  DateTime? _resolveStreakUnlockedAt({
    required List<ProgressionEvaluation> evaluations,
    required int streakTarget,
    required bool aggregateByPeriod,
  }) {
    final ordered = aggregateByPeriod
        ? _aggregateByPeriod(evaluations)
        : [
            for (final evaluation in evaluations)
              _AchievementStreakEntry(
                kind: evaluation.period.kind,
                start: evaluation.period.start,
                achieved: evaluation.achieved,
              ),
          ];

    var running = 0;
    for (var index = 0; index < ordered.length; index++) {
      final current = ordered[index];
      final previous = index > 0 ? ordered[index - 1] : null;
      final consecutive = previous != null &&
          _isConsecutive(previous: previous, current: current);

      if (!current.achieved) {
        running = 0;
        continue;
      }

      running = consecutive ? running + 1 : 1;
      if (running >= streakTarget) {
        return current.start;
      }
    }

    return null;
  }

  double _bestRollingWindowValue({
    required ProgressionAchievementDefinition definition,
    required List<ProgressionEvaluation> evaluations,
  }) {
    final entries = _rollingWindowEntries(
      definition: definition,
      evaluations: evaluations,
    );
    if (entries.isEmpty) return 0;

    final windowDays = definition.windowSizeDays;
    if (windowDays == null || windowDays <= 0) return 0;

    var best = 0.0;
    var running = 0.0;
    var start = 0;
    for (var end = 0; end < entries.length; end++) {
      running += entries[end].value;
      while (entries[end].start.difference(entries[start].start).inDays >=
          windowDays) {
        running -= entries[start].value;
        start++;
      }
      if (running > best) {
        best = running;
      }
    }
    return best;
  }

  DateTime? _resolveRollingWindowUnlockedAt({
    required ProgressionAchievementDefinition definition,
    required List<ProgressionEvaluation> evaluations,
  }) {
    final entries = _rollingWindowEntries(
      definition: definition,
      evaluations: evaluations,
    );
    if (entries.isEmpty) return null;

    final windowDays = definition.windowSizeDays;
    if (windowDays == null || windowDays <= 0) return null;

    var running = 0.0;
    var start = 0;
    for (var end = 0; end < entries.length; end++) {
      running += entries[end].value;
      while (entries[end].start.difference(entries[start].start).inDays >=
          windowDays) {
        running -= entries[start].value;
        start++;
      }
      if (running >= definition.targetValue) {
        return entries[end].start;
      }
    }
    return null;
  }

  List<_AchievementRollingEntry> _rollingWindowEntries({
    required ProgressionAchievementDefinition definition,
    required List<ProgressionEvaluation> evaluations,
  }) {
    final ordered = _matchingEvaluations(
      definition: definition,
      evaluations: evaluations,
    )..sort((a, b) {
        final byPeriod = a.period.start.compareTo(b.period.start);
        if (byPeriod != 0) return byPeriod;
        return a.evaluationKey.compareTo(b.evaluationKey);
      });

    return [
      for (final evaluation in ordered)
        if (evaluation.period.kind == ProgressionPeriodKind.day)
          _AchievementRollingEntry(
            start: progressionDate(evaluation.period.start),
            value: evaluation.actualValue,
          ),
    ];
  }

  List<_AchievementStreakEntry> _aggregateByPeriod(
    List<ProgressionEvaluation> evaluations,
  ) {
    final aggregated = <String, _AchievementStreakEntry>{};
    for (final evaluation in evaluations) {
      final key =
          '${evaluation.period.kind.name}|${progressionDateKey(evaluation.period.start)}';
      final existing = aggregated[key];
      if (existing == null) {
        aggregated[key] = _AchievementStreakEntry(
          kind: evaluation.period.kind,
          start: evaluation.period.start,
          achieved: evaluation.achieved,
        );
        continue;
      }

      aggregated[key] = _AchievementStreakEntry(
        kind: existing.kind,
        start: existing.start,
        achieved: existing.achieved || evaluation.achieved,
      );
    }

    final entries = aggregated.values.toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    return entries;
  }

  bool _isConsecutive({
    required _AchievementStreakEntry previous,
    required _AchievementStreakEntry current,
  }) {
    if (previous.kind != current.kind) return false;
    final expected = switch (previous.kind) {
      ProgressionPeriodKind.day => previous.start.add(const Duration(days: 1)),
      ProgressionPeriodKind.week => previous.start.add(const Duration(days: 7)),
    };
    return progressionDate(expected) == progressionDate(current.start);
  }

  List<_AchievementXpEvent> _xpEvents({
    required List<ProgressionRewardGrant> rewardGrants,
    required List<ProgressionQuestRewardGrant> questRewardGrants,
  }) {
    return [
      for (final grant in rewardGrants)
        if (grant.effectiveXpGranted > 0)
          _AchievementXpEvent(
            at: grant.progressionAt,
            xp: grant.effectiveXpGranted,
          ),
      for (final grant in questRewardGrants)
        if (grant.effectiveXpGranted > 0)
          _AchievementXpEvent(
            at: grant.progressionAt,
            xp: grant.effectiveXpGranted,
          ),
    ];
  }
}

class _AchievementStreakEntry {
  const _AchievementStreakEntry({
    required this.kind,
    required this.start,
    required this.achieved,
  });

  final ProgressionPeriodKind kind;
  final DateTime start;
  final bool achieved;
}

class _AchievementRollingEntry {
  const _AchievementRollingEntry({
    required this.start,
    required this.value,
  });

  final DateTime start;
  final double value;
}

class _AchievementXpEvent {
  const _AchievementXpEvent({
    required this.at,
    required this.xp,
  });

  final DateTime at;
  final int xp;
}
