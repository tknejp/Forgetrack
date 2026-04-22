import 'progression_models.dart';
import 'progression_streak_policy.dart';

class ProgressionQuestEvaluationResult {
  const ProgressionQuestEvaluationResult({
    required this.quests,
    required this.activeQuestIds,
  });

  final List<ProgressionQuest> quests;
  final Set<String> activeQuestIds;
}

class ProgressionQuestEvaluator {
  const ProgressionQuestEvaluator();

  ProgressionQuestEvaluationResult evaluate({
    required List<ProgressionQuestDefinition> definitions,
    required Set<String> previousActiveQuestIds,
    required DateTime evaluationDate,
    required ProgressionProfile profile,
    required List<ProgressionEvaluation> evaluations,
    required List<ProgressionRewardGrant> rewardGrants,
    required List<ProgressionAchievement> achievements,
    required Map<String, ProgressionStreakSummary> streaksByRuleId,
    required Map<ProgressionDomain, ProgressionStreakSummary> streaksByDomain,
  }) {
    final orderedDefinitions = [...definitions]..sort(_sortDefinitions);
    final availableById = <String, ProgressionQuest>{};

    for (final definition in orderedDefinitions) {
      final quest = _evaluateDefinition(
        definition: definition,
        questsById: availableById,
        evaluationDate: evaluationDate,
        profile: profile,
        evaluations: evaluations,
        rewardGrants: rewardGrants,
        achievements: achievements,
        streaksByRuleId: streaksByRuleId,
        streaksByDomain: streaksByDomain,
      );
      availableById[quest.id] = quest;
    }

    final activeQuestIds = _resolveActiveQuestIds(
      quests: availableById.values,
      previousActiveQuestIds: previousActiveQuestIds,
    );

    final quests = [
      for (final definition in orderedDefinitions)
        _withAssignedStatus(
          availableById[definition.id]!,
          isActive: activeQuestIds.contains(definition.id),
        ),
    ];

    return ProgressionQuestEvaluationResult(
      quests: quests,
      activeQuestIds: activeQuestIds,
    );
  }

  ProgressionQuest _evaluateDefinition({
    required ProgressionQuestDefinition definition,
    required Map<String, ProgressionQuest> questsById,
    required DateTime evaluationDate,
    required ProgressionProfile profile,
    required List<ProgressionEvaluation> evaluations,
    required List<ProgressionRewardGrant> rewardGrants,
    required List<ProgressionAchievement> achievements,
    required Map<String, ProgressionStreakSummary> streaksByRuleId,
    required Map<ProgressionDomain, ProgressionStreakSummary> streaksByDomain,
  }) {
    final currentValue = _currentValue(
      definition: definition,
      profile: profile,
      evaluations: evaluations,
      rewardGrants: rewardGrants,
      achievements: achievements,
      streaksByRuleId: streaksByRuleId,
      streaksByDomain: streaksByDomain,
    );

    final prerequisitesMet = _prerequisitesMet(
      definition: definition,
      questsById: questsById,
    );
    final unlockConditionsMet = _unlockConditionsMet(
      definition: definition,
      evaluationDate: evaluationDate,
      profile: profile,
      evaluations: evaluations,
      rewardGrants: rewardGrants,
    );
    final completedByCriterion = currentValue >= definition.targetValue;
    final completedAt =
        prerequisitesMet && unlockConditionsMet && completedByCriterion
            ? _resolveEffectiveCompletedAt(
                definition: definition,
                prerequisiteCompletedAt: _latestPrerequisiteCompletedAt(
                  definition: definition,
                  questsById: questsById,
                ),
                profile: profile,
                evaluations: evaluations,
                rewardGrants: rewardGrants,
                achievements: achievements,
              )
            : null;

    return ProgressionQuest(
      id: definition.id,
      title: definition.title,
      description: definition.description,
      type: definition.type,
      category: definition.category,
      criterionType: definition.criterionType,
      status: !prerequisitesMet || !unlockConditionsMet
          ? ProgressionQuestStatus.locked
          : completedByCriterion
              ? ProgressionQuestStatus.completed
              : ProgressionQuestStatus.available,
      targetValue: definition.targetValue,
      currentValue: currentValue,
      progress: (currentValue / definition.targetValue).clamp(0, 1).toDouble(),
      prerequisiteQuestIds: definition.prerequisiteQuestIds,
      sortOrder: definition.sortOrder,
      priority: definition.priority,
      isHighlighted: false,
      completedAt: completedAt,
      ruleId: definition.ruleId,
      domain: definition.domain,
      periodKind: definition.periodKind,
      achievementId: definition.achievementId,
      relatedRuleIds: definition.relatedRuleIds,
      minimumLevel: definition.minimumLevel,
      minimumTrackedDays: definition.minimumTrackedDays,
    );
  }

  ProgressionQuest _withAssignedStatus(
    ProgressionQuest quest, {
    required bool isActive,
  }) {
    final nextStatus = switch (quest.status) {
      ProgressionQuestStatus.locked => ProgressionQuestStatus.locked,
      ProgressionQuestStatus.completed => ProgressionQuestStatus.completed,
      ProgressionQuestStatus.available => isActive
          ? ProgressionQuestStatus.active
          : ProgressionQuestStatus.available,
      ProgressionQuestStatus.active => isActive
          ? ProgressionQuestStatus.active
          : ProgressionQuestStatus.available,
    };

    return ProgressionQuest(
      id: quest.id,
      title: quest.title,
      description: quest.description,
      type: quest.type,
      category: quest.category,
      criterionType: quest.criterionType,
      status: nextStatus,
      targetValue: quest.targetValue,
      currentValue: quest.currentValue,
      progress: quest.progress,
      prerequisiteQuestIds: quest.prerequisiteQuestIds,
      sortOrder: quest.sortOrder,
      priority: quest.priority,
      isHighlighted: isActive,
      completedAt: quest.completedAt,
      ruleId: quest.ruleId,
      domain: quest.domain,
      periodKind: quest.periodKind,
      achievementId: quest.achievementId,
      relatedRuleIds: quest.relatedRuleIds,
      minimumLevel: quest.minimumLevel,
      minimumTrackedDays: quest.minimumTrackedDays,
    );
  }

  Set<String> _resolveActiveQuestIds({
    required Iterable<ProgressionQuest> quests,
    required Set<String> previousActiveQuestIds,
  }) {
    final availableQuests = quests
        .where((quest) => quest.status == ProgressionQuestStatus.available)
        .toList();

    final activeIds = <String>{};
    final categoryCounts = <ProgressionQuestCategory, int>{};

    final persistedCandidates = availableQuests
        .where((quest) => previousActiveQuestIds.contains(quest.id))
        .toList()
      ..sort(_sortQuestSelection);

    for (final quest in persistedCandidates) {
      if (_tryAssignQuest(
        quest: quest,
        activeIds: activeIds,
        categoryCounts: categoryCounts,
      )) {
        continue;
      }
    }

    final newCandidates = availableQuests
        .where((quest) => !previousActiveQuestIds.contains(quest.id))
        .toList()
      ..sort(_sortQuestSelection);

    for (final quest in newCandidates) {
      if (_tryAssignQuest(
        quest: quest,
        activeIds: activeIds,
        categoryCounts: categoryCounts,
      )) {
        continue;
      }
      if (activeIds.length >= _maxActiveQuestCount) {
        break;
      }
    }

    return activeIds;
  }

  bool _tryAssignQuest({
    required ProgressionQuest quest,
    required Set<String> activeIds,
    required Map<ProgressionQuestCategory, int> categoryCounts,
  }) {
    if (activeIds.length >= _maxActiveQuestCount) return false;

    final cap = _categoryCap(quest.category);
    final current = categoryCounts[quest.category] ?? 0;
    if (current >= cap) return false;

    activeIds.add(quest.id);
    categoryCounts[quest.category] = current + 1;
    return true;
  }

  int _categoryCap(ProgressionQuestCategory category) {
    switch (category) {
      case ProgressionQuestCategory.chain:
        return 1;
      case ProgressionQuestCategory.weekly:
        return 1;
      case ProgressionQuestCategory.daily:
        return 2;
      case ProgressionQuestCategory.journey:
        return 2;
    }
  }

  static const int _maxActiveQuestCount = 6;

  int _sortQuestSelection(ProgressionQuest left, ProgressionQuest right) {
    final byCategory = _categorySelectionOrder(left.category)
        .compareTo(_categorySelectionOrder(right.category));
    if (byCategory != 0) return byCategory;

    final byPriority = right.priority.compareTo(left.priority);
    if (byPriority != 0) return byPriority;

    final byProgress = right.progress.compareTo(left.progress);
    if (byProgress != 0) return byProgress;

    final bySortOrder = left.sortOrder.compareTo(right.sortOrder);
    if (bySortOrder != 0) return bySortOrder;

    return left.id.compareTo(right.id);
  }

  int _categorySelectionOrder(ProgressionQuestCategory category) {
    switch (category) {
      case ProgressionQuestCategory.chain:
        return 0;
      case ProgressionQuestCategory.weekly:
        return 1;
      case ProgressionQuestCategory.daily:
        return 2;
      case ProgressionQuestCategory.journey:
        return 3;
    }
  }

  bool _prerequisitesMet({
    required ProgressionQuestDefinition definition,
    required Map<String, ProgressionQuest> questsById,
  }) {
    if (definition.prerequisiteQuestIds.isEmpty) return true;

    for (final prerequisiteId in definition.prerequisiteQuestIds) {
      final prerequisite = questsById[prerequisiteId];
      if (prerequisite == null || !prerequisite.isCompleted) {
        return false;
      }
    }

    return true;
  }

  bool _unlockConditionsMet({
    required ProgressionQuestDefinition definition,
    required DateTime evaluationDate,
    required ProgressionProfile profile,
    required List<ProgressionEvaluation> evaluations,
    required List<ProgressionRewardGrant> rewardGrants,
  }) {
    if (definition.minimumLevel != null &&
        profile.level < definition.minimumLevel!) {
      return false;
    }

    if (definition.minimumTrackedDays != null) {
      final trackedDaysElapsed = _trackedDaysElapsed(
        evaluationDate: evaluationDate,
        evaluations: evaluations,
        rewardGrants: rewardGrants,
      );
      if (trackedDaysElapsed < definition.minimumTrackedDays!) {
        return false;
      }
    }

    return true;
  }

  DateTime? _latestPrerequisiteCompletedAt({
    required ProgressionQuestDefinition definition,
    required Map<String, ProgressionQuest> questsById,
  }) {
    DateTime? latest;

    for (final prerequisiteId in definition.prerequisiteQuestIds) {
      final completedAt = questsById[prerequisiteId]?.completedAt;
      if (completedAt == null) continue;
      if (latest == null || completedAt.isAfter(latest)) {
        latest = completedAt;
      }
    }

    return latest;
  }

  int _trackedDaysElapsed({
    required DateTime evaluationDate,
    required List<ProgressionEvaluation> evaluations,
    required List<ProgressionRewardGrant> rewardGrants,
  }) {
    DateTime? earliest;

    for (final evaluation in evaluations) {
      final start = progressionDate(evaluation.period.start);
      if (earliest == null || start.isBefore(earliest)) {
        earliest = start;
      }
    }

    for (final grant in rewardGrants) {
      final start = progressionDate(grant.period.start);
      if (earliest == null || start.isBefore(earliest)) {
        earliest = start;
      }
    }

    if (earliest == null) return 0;
    final currentDay = progressionDate(evaluationDate);
    return currentDay.difference(earliest).inDays + 1;
  }

  int _currentValue({
    required ProgressionQuestDefinition definition,
    required ProgressionProfile profile,
    required List<ProgressionEvaluation> evaluations,
    required List<ProgressionRewardGrant> rewardGrants,
    required List<ProgressionAchievement> achievements,
    required Map<String, ProgressionStreakSummary> streaksByRuleId,
    required Map<ProgressionDomain, ProgressionStreakSummary> streaksByDomain,
  }) {
    switch (definition.criterionType) {
      case ProgressionQuestCriterionType.totalXpAtLeast:
        return profile.totalXp;
      case ProgressionQuestCriterionType.rewardCountAtLeast:
        return _matchingRewardGrants(
          definition: definition,
          rewardGrants: rewardGrants,
        ).length;
      case ProgressionQuestCriterionType.bestStreakAtLeast:
        if (definition.ruleId != null) {
          return streaksByRuleId[definition.ruleId]?.bestStreak ?? 0;
        }
        if (definition.domain != null) {
          return streaksByDomain[definition.domain]?.bestStreak ?? 0;
        }
        return 0;
      case ProgressionQuestCriterionType.totalRuleValueAtLeast:
        return _matchingEvaluations(
          definition: definition,
          evaluations: evaluations,
        )
            .fold<double>(
              0,
              (sum, evaluation) => sum + evaluation.actualValue,
            )
            .round();
      case ProgressionQuestCriterionType.currentPeriodRuleCompletion:
        final latestEvaluation = _latestMatchingEvaluation(
          definition: definition,
          evaluations: evaluations,
        );
        return latestEvaluation?.achieved == true ? 1 : 0;
      case ProgressionQuestCriterionType.currentPeriodRuleSetAtLeast:
        return _currentPeriodRuleSetCompletionCount(
          definition: definition,
          evaluations: evaluations,
        );
      case ProgressionQuestCriterionType.achievementUnlocked:
        final achievement = _achievementForId(
          achievements: achievements,
          achievementId: definition.achievementId,
        );
        return achievement?.unlocked == true ? 1 : 0;
      case ProgressionQuestCriterionType.ruleCompletionsAtLeast:
        return _matchingAchievedEvaluations(
          definition: definition,
          evaluations: evaluations,
        ).length;
      case ProgressionQuestCriterionType.domainRewardCountAtLeast:
        return rewardGrants
            .where((grant) => grant.domain == definition.domain)
            .length;
    }
  }

  DateTime? _resolveEffectiveCompletedAt({
    required ProgressionQuestDefinition definition,
    required DateTime? prerequisiteCompletedAt,
    required ProgressionProfile profile,
    required List<ProgressionEvaluation> evaluations,
    required List<ProgressionRewardGrant> rewardGrants,
    required List<ProgressionAchievement> achievements,
  }) {
    final criterionCompletedAt = _resolveCompletedAt(
      definition: definition,
      profile: profile,
      evaluations: evaluations,
      rewardGrants: rewardGrants,
      achievements: achievements,
    );

    if (criterionCompletedAt == null) return prerequisiteCompletedAt;
    if (prerequisiteCompletedAt == null) return criterionCompletedAt;

    return criterionCompletedAt.isAfter(prerequisiteCompletedAt)
        ? criterionCompletedAt
        : prerequisiteCompletedAt;
  }

  DateTime? _resolveCompletedAt({
    required ProgressionQuestDefinition definition,
    required ProgressionProfile profile,
    required List<ProgressionEvaluation> evaluations,
    required List<ProgressionRewardGrant> rewardGrants,
    required List<ProgressionAchievement> achievements,
  }) {
    switch (definition.criterionType) {
      case ProgressionQuestCriterionType.totalXpAtLeast:
        return _resolveTotalXpCompletedAt(
          targetValue: definition.targetValue,
          rewardGrants: rewardGrants,
          profile: profile,
        );
      case ProgressionQuestCriterionType.rewardCountAtLeast:
        return _resolveRewardThresholdCompletedAt(
          targetValue: definition.targetValue,
          rewardGrants: _matchingRewardGrants(
            definition: definition,
            rewardGrants: rewardGrants,
          ),
        );
      case ProgressionQuestCriterionType.bestStreakAtLeast:
        return _resolveStreakCompletedAt(
          targetValue: definition.targetValue,
          evaluations: _matchingEvaluations(
            definition: definition,
            evaluations: evaluations,
          ),
          aggregateByPeriod: definition.domain != null,
        );
      case ProgressionQuestCriterionType.totalRuleValueAtLeast:
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
      case ProgressionQuestCriterionType.currentPeriodRuleCompletion:
        final latestEvaluation = _latestMatchingEvaluation(
          definition: definition,
          evaluations: evaluations,
        );
        return latestEvaluation?.achieved == true
            ? latestEvaluation!.period.start
            : null;
      case ProgressionQuestCriterionType.currentPeriodRuleSetAtLeast:
        final latestPeriodStart = _latestRelevantPeriodStart(
          definition: definition,
          evaluations: evaluations,
        );
        if (latestPeriodStart == null) return null;
        final completedCount = _currentPeriodRuleSetCompletionCount(
          definition: definition,
          evaluations: evaluations,
        );
        return completedCount >= definition.targetValue
            ? latestPeriodStart
            : null;
      case ProgressionQuestCriterionType.achievementUnlocked:
        return _achievementForId(
          achievements: achievements,
          achievementId: definition.achievementId,
        )?.unlockedAt;
      case ProgressionQuestCriterionType.ruleCompletionsAtLeast:
        final ordered = _matchingAchievedEvaluations(
          definition: definition,
          evaluations: evaluations,
        )..sort((a, b) => a.period.start.compareTo(b.period.start));

        if (ordered.length < definition.targetValue) return null;
        return ordered[definition.targetValue - 1].period.start;
      case ProgressionQuestCriterionType.domainRewardCountAtLeast:
        final ordered = rewardGrants
            .where((grant) => grant.domain == definition.domain)
            .toList()
          ..sort(_sortRewardGrants);

        if (ordered.length < definition.targetValue) return null;
        return ordered[definition.targetValue - 1].grantedAt;
    }
  }

  DateTime? _resolveTotalXpCompletedAt({
    required int targetValue,
    required List<ProgressionRewardGrant> rewardGrants,
    required ProgressionProfile profile,
  }) {
    final ordered = [...rewardGrants]..sort(_sortRewardGrants);
    var runningXp = 0;
    for (final grant in ordered) {
      runningXp += grant.xpGranted;
      if (runningXp >= targetValue) {
        return grant.grantedAt;
      }
    }

    return profile.totalXp >= targetValue && ordered.isNotEmpty
        ? ordered.last.grantedAt
        : null;
  }

  DateTime? _resolveRewardThresholdCompletedAt({
    required int targetValue,
    required List<ProgressionRewardGrant> rewardGrants,
  }) {
    final ordered = [...rewardGrants]..sort(_sortRewardGrants);
    if (ordered.length < targetValue) return null;
    return ordered[targetValue - 1].grantedAt;
  }

  DateTime? _resolveStreakCompletedAt({
    required int targetValue,
    required List<ProgressionEvaluation> evaluations,
    required bool aggregateByPeriod,
  }) {
    final ordered = aggregateByPeriod
        ? _aggregateByPeriod(evaluations)
        : [
            for (final evaluation in evaluations)
              _QuestStreakEntry(
                kind: evaluation.period.kind,
                start: evaluation.period.start,
                achieved: evaluation.achieved,
              ),
          ];

    ordered.sort((a, b) => a.start.compareTo(b.start));

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
      if (running >= targetValue) {
        return current.start;
      }
    }

    for (var index = ordered.length - 1; index >= 0; index--) {
      if (ordered[index].achieved) {
        return ordered[index].start;
      }
    }
    return null;
  }

  List<ProgressionRewardGrant> _matchingRewardGrants({
    required ProgressionQuestDefinition definition,
    required List<ProgressionRewardGrant> rewardGrants,
  }) {
    return rewardGrants.where((grant) {
      if (definition.ruleId != null && grant.ruleId != definition.ruleId) {
        return false;
      }
      if (definition.domain != null && grant.domain != definition.domain) {
        return false;
      }
      if (definition.periodKind != null &&
          grant.period.kind != definition.periodKind) {
        return false;
      }
      return true;
    }).toList();
  }

  List<ProgressionEvaluation> _matchingEvaluations({
    required ProgressionQuestDefinition definition,
    required List<ProgressionEvaluation> evaluations,
  }) {
    return evaluations.where((evaluation) {
      if (definition.ruleId != null && evaluation.ruleId != definition.ruleId) {
        return false;
      }
      if (definition.domain != null && evaluation.domain != definition.domain) {
        return false;
      }
      if (definition.periodKind != null &&
          evaluation.period.kind != definition.periodKind) {
        return false;
      }
      if (definition.relatedRuleIds.isNotEmpty &&
          !definition.relatedRuleIds.contains(evaluation.ruleId)) {
        return false;
      }
      return true;
    }).toList();
  }

  List<ProgressionEvaluation> _matchingAchievedEvaluations({
    required ProgressionQuestDefinition definition,
    required List<ProgressionEvaluation> evaluations,
  }) {
    return _matchingEvaluations(
      definition: definition,
      evaluations: evaluations,
    ).where((evaluation) => evaluation.achieved).toList();
  }

  ProgressionEvaluation? _latestMatchingEvaluation({
    required ProgressionQuestDefinition definition,
    required List<ProgressionEvaluation> evaluations,
  }) {
    final matching = _matchingEvaluations(
      definition: definition,
      evaluations: evaluations,
    );
    if (matching.isEmpty) return null;

    matching.sort((left, right) {
      final byPeriod = right.period.start.compareTo(left.period.start);
      if (byPeriod != 0) return byPeriod;
      return right.evaluationKey.compareTo(left.evaluationKey);
    });

    return matching.first;
  }

  int _currentPeriodRuleSetCompletionCount({
    required ProgressionQuestDefinition definition,
    required List<ProgressionEvaluation> evaluations,
  }) {
    final latestPeriodStart = _latestRelevantPeriodStart(
      definition: definition,
      evaluations: evaluations,
    );
    if (latestPeriodStart == null) return 0;

    final completedRuleIds = _matchingEvaluations(
      definition: definition,
      evaluations: evaluations,
    )
        .where((evaluation) {
          return progressionDate(evaluation.period.start) ==
                  progressionDate(latestPeriodStart) &&
              evaluation.achieved;
        })
        .map((evaluation) => evaluation.ruleId)
        .toSet();

    return completedRuleIds.length;
  }

  DateTime? _latestRelevantPeriodStart({
    required ProgressionQuestDefinition definition,
    required List<ProgressionEvaluation> evaluations,
  }) {
    final matching = _matchingEvaluations(
      definition: definition,
      evaluations: evaluations,
    );
    if (matching.isEmpty) return null;

    matching.sort((left, right) {
      final byPeriod = right.period.start.compareTo(left.period.start);
      if (byPeriod != 0) return byPeriod;
      return right.evaluationKey.compareTo(left.evaluationKey);
    });
    return matching.first.period.start;
  }

  ProgressionAchievement? _achievementForId({
    required List<ProgressionAchievement> achievements,
    required String? achievementId,
  }) {
    if (achievementId == null) return null;

    for (final achievement in achievements) {
      if (achievement.id == achievementId) {
        return achievement;
      }
    }
    return null;
  }

  List<_QuestStreakEntry> _aggregateByPeriod(
    List<ProgressionEvaluation> evaluations,
  ) {
    final aggregated = <String, _QuestStreakEntry>{};
    for (final evaluation in evaluations) {
      final key =
          '${evaluation.period.kind.name}|${progressionDateKey(evaluation.period.start)}';
      final existing = aggregated[key];
      if (existing == null) {
        aggregated[key] = _QuestStreakEntry(
          kind: evaluation.period.kind,
          start: evaluation.period.start,
          achieved: evaluation.achieved,
        );
        continue;
      }

      aggregated[key] = _QuestStreakEntry(
        kind: existing.kind,
        start: existing.start,
        achieved: existing.achieved || evaluation.achieved,
      );
    }

    return aggregated.values.toList();
  }

  bool _isConsecutive({
    required _QuestStreakEntry previous,
    required _QuestStreakEntry current,
  }) {
    if (previous.kind != current.kind) return false;

    final expected = switch (previous.kind) {
      ProgressionPeriodKind.day => previous.start.add(const Duration(days: 1)),
      ProgressionPeriodKind.week => previous.start.add(const Duration(days: 7)),
    };

    return progressionDate(expected) == progressionDate(current.start);
  }

  int _sortDefinitions(
    ProgressionQuestDefinition left,
    ProgressionQuestDefinition right,
  ) {
    final bySortOrder = left.sortOrder.compareTo(right.sortOrder);
    if (bySortOrder != 0) return bySortOrder;

    final byCategory = left.category.index.compareTo(right.category.index);
    if (byCategory != 0) return byCategory;

    return left.id.compareTo(right.id);
  }

  int _sortRewardGrants(
    ProgressionRewardGrant left,
    ProgressionRewardGrant right,
  ) {
    final byGrantedAt = left.grantedAt.compareTo(right.grantedAt);
    if (byGrantedAt != 0) return byGrantedAt;

    final byPeriod = left.period.start.compareTo(right.period.start);
    if (byPeriod != 0) return byPeriod;

    return left.rewardKey.compareTo(right.rewardKey);
  }
}

class _QuestStreakEntry {
  const _QuestStreakEntry({
    required this.kind,
    required this.start,
    required this.achieved,
  });

  final ProgressionPeriodKind kind;
  final DateTime start;
  final bool achieved;
}
