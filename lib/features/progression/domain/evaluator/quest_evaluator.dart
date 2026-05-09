import '../../../../core/logging/app_log.dart';
import '../progression_models.dart';
import '../policy/streak_policy.dart';

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

  static const _questLog = AppLogger('PROG', scope: 'QUEST');

  ProgressionQuestEvaluationResult evaluate({
    required List<ProgressionQuestDefinition> definitions,
    required Set<String> previousActiveQuestIds,
    required DateTime evaluationDate,
    required ProgressionProfile profile,
    required List<ProgressionEvaluation> evaluations,
    required List<ProgressionRewardGrant> rewardGrants,
    required List<ProgressionQuestRewardGrant> questRewardGrants,
    required List<ProgressionChapterStartRecord> chapterStarts,
    required List<ProgressionAchievement> achievements,
    required Map<String, ProgressionStreakSummary> streaksByRuleId,
    required Map<ProgressionDomain, ProgressionStreakSummary> streaksByDomain,
  }) {
    final orderedDefinitions = [...definitions]..sort(_sortDefinitions);
    final chapterStartsById = {
      for (final start in chapterStarts) start.chapterId: start,
    };
    final availableById = <String, ProgressionQuest>{};
    final dailySequenceStepById = _activeDailySequenceSteps(
      definitions: orderedDefinitions,
      evaluationDate: evaluationDate,
      evaluations: evaluations,
      questRewardGrants: questRewardGrants,
    );
    final comboPoolSelection = _activeComboGroupByPool(
      definitions: orderedDefinitions,
      previousActiveQuestIds: previousActiveQuestIds,
      evaluationDate: evaluationDate,
      profile: profile,
      evaluations: evaluations,
      rewardGrants: rewardGrants,
      questRewardGrants: questRewardGrants,
    );

    for (final definition in orderedDefinitions) {
      final quest = _evaluateDefinition(
        definition: definition,
        activeDailySequenceStep: dailySequenceStepById[definition.id],
        activeComboGroupId: definition.comboPoolId == null
            ? null
            : comboPoolSelection.activeGroupByPool[definition.comboPoolId],
        comboPoolRotatedToday: definition.comboPoolId != null &&
            comboPoolSelection.rotatedPoolIds.contains(definition.comboPoolId),
        questsById: availableById,
        evaluationDate: evaluationDate,
        profile: profile,
        evaluations: evaluations,
        rewardGrants: rewardGrants,
        questRewardGrants: questRewardGrants,
        chapterStartsById: chapterStartsById,
        achievements: achievements,
        streaksByRuleId: streaksByRuleId,
        streaksByDomain: streaksByDomain,
      );
      availableById[quest.id] = quest;
    }

    final activeChapterId = _resolveActiveChapterId(
      definitions: orderedDefinitions,
      questsById: availableById,
      questRewardGrants: questRewardGrants,
    );
    _gateWaitingChapterChains(
      definitions: orderedDefinitions,
      questsById: availableById,
      activeChapterId: activeChapterId,
      questRewardGrants: questRewardGrants,
    );

    final activeQuestIds = _resolveActiveQuestIds(
      quests: availableById.values,
      activeChapterId: activeChapterId,
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

  _ComboPoolSelection _activeComboGroupByPool({
    required List<ProgressionQuestDefinition> definitions,
    required Set<String> previousActiveQuestIds,
    required DateTime evaluationDate,
    required ProgressionProfile profile,
    required List<ProgressionEvaluation> evaluations,
    required List<ProgressionRewardGrant> rewardGrants,
    required List<ProgressionQuestRewardGrant> questRewardGrants,
  }) {
    final groupsByPool =
        <String, Map<String, List<ProgressionQuestDefinition>>>{};
    final definitionById = {
      for (final definition in definitions) definition.id: definition,
    };

    for (final definition in definitions) {
      final poolId = definition.comboPoolId;
      if (poolId == null || poolId.isEmpty) continue;
      final groupId = _displayGroupId(definition);
      groupsByPool
          .putIfAbsent(poolId, () => {})
          .putIfAbsent(groupId, () => [])
          .add(definition);
    }

    if (groupsByPool.isEmpty) return const _ComboPoolSelection.empty();

    final today = progressionDate(evaluationDate);
    final result = <String, String>{};
    final rotatedPoolIds = <String>{};

    for (final poolEntry in groupsByPool.entries) {
      final poolId = poolEntry.key;
      final groups = poolEntry.value;
      for (final group in groups.values) {
        group.sort(_sortDefinitions);
      }

      String? previousGroupId;
      for (final questId in previousActiveQuestIds) {
        final definition = definitionById[questId];
        if (definition?.comboPoolId != poolId) continue;
        previousGroupId = _displayGroupId(definition!);
        break;
      }

      final previousCompletedToday = previousGroupId != null &&
          _groupCompletedOnDay(
            groups[previousGroupId] ?? const [],
            questRewardGrants,
            today,
          );
      if (previousGroupId != null && !previousCompletedToday) {
        result[poolId] = previousGroupId;
        continue;
      }
      if (previousCompletedToday) {
        rotatedPoolIds.add(poolId);
      }

      final unlockedGroupIds = groups.keys
          .where((groupId) => _groupStartsUnlocked(
                group: groups[groupId] ?? const [],
                evaluationDate: evaluationDate,
                profile: profile,
                evaluations: evaluations,
                rewardGrants: rewardGrants,
              ))
          .toList(growable: false);
      final candidateGroupIds = unlockedGroupIds.isEmpty
          ? groups.keys.toList(growable: false)
          : unlockedGroupIds;
      final availableGroupIds = candidateGroupIds
          .where((groupId) => !_groupCompletedOnDay(
                groups[groupId] ?? const [],
                questRewardGrants,
                today,
              ))
          .toList(growable: false);
      final candidates = availableGroupIds.isEmpty
          ? candidateGroupIds.toList()
          : availableGroupIds.toList();
      if (previousGroupId != null && candidates.length > 1) {
        candidates.remove(previousGroupId);
      }
      final completedRuns = _completedRunsForPool(
        groups.values.expand((group) => group),
        questRewardGrants,
      );
      candidates.sort((left, right) {
        final leftScore = _stableComboScore(
          poolId: poolId,
          groupId: left,
          completedRuns: completedRuns,
        );
        final rightScore = _stableComboScore(
          poolId: poolId,
          groupId: right,
          completedRuns: completedRuns,
        );
        final byScore = leftScore.compareTo(rightScore);
        if (byScore != 0) return byScore;
        return left.compareTo(right);
      });
      result[poolId] = candidates.first;
    }

    return _ComboPoolSelection(
      activeGroupByPool: result,
      rotatedPoolIds: rotatedPoolIds,
    );
  }

  double _safeProgress(int currentValue, int targetValue) {
    if (targetValue <= 0) return currentValue > 0 ? 1 : 0;
    final ratio = currentValue / targetValue;
    if (ratio.isNaN || ratio.isInfinite) return currentValue > 0 ? 1 : 0;
    return ratio.clamp(0, 1).toDouble();
  }

  bool _groupCompletedOnDay(
    List<ProgressionQuestDefinition> group,
    List<ProgressionQuestRewardGrant> questRewardGrants,
    DateTime day,
  ) {
    if (group.isEmpty) return false;
    final finalDefinition = _finalComboDefinition(group);
    return questRewardGrants.any((grant) {
      return grant.questId == finalDefinition.id &&
          progressionDate(grant.completedAt) == day;
    });
  }

  bool _groupStartsUnlocked({
    required List<ProgressionQuestDefinition> group,
    required DateTime evaluationDate,
    required ProgressionProfile profile,
    required List<ProgressionEvaluation> evaluations,
    required List<ProgressionRewardGrant> rewardGrants,
  }) {
    if (group.isEmpty) return false;
    return _unlockConditionsMet(
      definition: _firstComboDefinition(group),
      evaluationDate: evaluationDate,
      profile: profile,
      evaluations: evaluations,
      rewardGrants: rewardGrants,
    );
  }

  ProgressionQuestDefinition _firstComboDefinition(
    List<ProgressionQuestDefinition> group,
  ) {
    final sorted = [...group]..sort((left, right) {
        final leftStep = left.dailySequenceStep ?? 1 << 20;
        final rightStep = right.dailySequenceStep ?? 1 << 20;
        final byStep = leftStep.compareTo(rightStep);
        if (byStep != 0) return byStep;
        return left.sortOrder.compareTo(right.sortOrder);
      });
    return sorted.first;
  }

  int _completedRunsForPool(
    Iterable<ProgressionQuestDefinition> definitions,
    List<ProgressionQuestRewardGrant> questRewardGrants,
  ) {
    final finalQuestIdsByGroup = <String>{};
    final grouped = <String, List<ProgressionQuestDefinition>>{};
    for (final definition in definitions) {
      grouped
          .putIfAbsent(_displayGroupId(definition), () => [])
          .add(definition);
    }
    for (final group in grouped.values) {
      finalQuestIdsByGroup.add(_finalComboDefinition(group).id);
    }
    return questRewardGrants
        .where((grant) => finalQuestIdsByGroup.contains(grant.questId))
        .length;
  }

  ProgressionQuestDefinition _finalComboDefinition(
    List<ProgressionQuestDefinition> group,
  ) {
    final sorted = [...group]..sort((left, right) {
        final leftStep = left.dailySequenceStep ?? -1;
        final rightStep = right.dailySequenceStep ?? -1;
        final byStep = rightStep.compareTo(leftStep);
        if (byStep != 0) return byStep;
        return right.sortOrder.compareTo(left.sortOrder);
      });
    return sorted.first;
  }

  int _stableComboScore({
    required String poolId,
    required String groupId,
    required int completedRuns,
  }) {
    var hash = 0x811c9dc5;
    for (final unit in '$poolId|$completedRuns|$groupId'.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  String _displayGroupId(ProgressionQuestDefinition definition) {
    return definition.displayGroupId ?? definition.chainId ?? definition.id;
  }

  Map<String, int> _activeDailySequenceSteps({
    required List<ProgressionQuestDefinition> definitions,
    required DateTime evaluationDate,
    required List<ProgressionEvaluation> evaluations,
    required List<ProgressionQuestRewardGrant> questRewardGrants,
  }) {
    final bySequence = <String, List<ProgressionQuestDefinition>>{};
    for (final definition in definitions) {
      final sequenceId = definition.dailySequenceId;
      final step = definition.dailySequenceStep;
      if (sequenceId == null || sequenceId.isEmpty || step == null) {
        continue;
      }
      bySequence.putIfAbsent(sequenceId, () => []).add(definition);
    }

    if (bySequence.isEmpty) return const {};

    final today = progressionDate(evaluationDate);
    final yesterday = today.subtract(const Duration(days: 1));
    final result = <String, int>{};

    for (final entry in bySequence.entries) {
      final sequence = entry.value
        ..sort((a, b) => a.dailySequenceStep!.compareTo(b.dailySequenceStep!));
      final stepByQuestId = {
        for (final definition in sequence)
          definition.id: definition.dailySequenceStep!,
      };
      final maxStep = sequence.last.dailySequenceStep!;
      var activeStep = 1;
      DateTime? previousDay;

      final replayDays = <DateTime>{};
      for (final evaluation in evaluations) {
        if (evaluation.period.kind != ProgressionPeriodKind.day) continue;
        if (!_sequenceReferencesRule(sequence, evaluation.ruleId)) continue;
        final day = progressionDate(evaluation.period.start);
        if (day.isBefore(today)) replayDays.add(day);
      }
      for (final grant in questRewardGrants) {
        final step = stepByQuestId[grant.questId];
        if (step == null) continue;
        final day = progressionDate(grant.completedAt);
        if (day.isBefore(today)) replayDays.add(day);
      }

      final orderedReplayDays = replayDays.toList()..sort();
      for (final day in orderedReplayDays) {
        if (previousDay != null && day.difference(previousDay).inDays > 1) {
          activeStep = 1;
        }
        final activeDefinition = sequence.firstWhere(
          (definition) => definition.dailySequenceStep == activeStep,
        );
        final completedByGrant = questRewardGrants.any((grant) {
          return grant.questId == activeDefinition.id &&
              progressionDate(grant.completedAt) == day;
        });
        final completedByEvaluation =
            _currentPeriodValueForDay(activeDefinition, evaluations, day) >=
                activeDefinition.targetValue;
        if (completedByGrant || completedByEvaluation) {
          activeStep = activeStep < maxStep ? activeStep + 1 : 1;
        } else {
          activeStep = 1;
        }
        previousDay = day;
      }

      if (previousDay == null || previousDay != yesterday) {
        activeStep = 1;
      }
      for (final definition in sequence) {
        result[definition.id] = activeStep;
      }
    }

    return result;
  }

  bool _sequenceReferencesRule(
    List<ProgressionQuestDefinition> sequence,
    String ruleId,
  ) {
    for (final definition in sequence) {
      if (definition.ruleId == ruleId ||
          definition.relatedRuleIds.contains(ruleId)) {
        return true;
      }
    }
    return false;
  }

  int _currentPeriodValueForDay(
    ProgressionQuestDefinition definition,
    List<ProgressionEvaluation> evaluations,
    DateTime day,
  ) {
    final matching = evaluations.where((evaluation) {
      if (evaluation.period.kind != ProgressionPeriodKind.day) return false;
      if (progressionDate(evaluation.period.start) != day) return false;
      if (definition.ruleId != null && evaluation.ruleId != definition.ruleId) {
        return false;
      }
      if (definition.relatedRuleIds.isNotEmpty &&
          !definition.relatedRuleIds.contains(evaluation.ruleId)) {
        return false;
      }
      return true;
    });

    switch (definition.criterionType) {
      case ProgressionQuestCriterionType.currentPeriodRuleCompletion:
        return matching.any((evaluation) => evaluation.achieved) ? 1 : 0;
      case ProgressionQuestCriterionType.currentPeriodRuleSetAtLeast:
        return matching
            .where((evaluation) => evaluation.achieved)
            .map((evaluation) => evaluation.ruleId)
            .toSet()
            .length;
      case ProgressionQuestCriterionType.chapterStarted:
      case ProgressionQuestCriterionType.totalXpAtLeast:
      case ProgressionQuestCriterionType.rewardCountAtLeast:
      case ProgressionQuestCriterionType.bestStreakAtLeast:
      case ProgressionQuestCriterionType.totalRuleValueAtLeast:
      case ProgressionQuestCriterionType.ruleSetCompletionsAtLeast:
      case ProgressionQuestCriterionType.achievementUnlocked:
      case ProgressionQuestCriterionType.ruleCompletionsAtLeast:
      case ProgressionQuestCriterionType.domainRewardCountAtLeast:
        return 0;
    }
  }

  ProgressionQuest _evaluateDefinition({
    required ProgressionQuestDefinition definition,
    required int? activeDailySequenceStep,
    required String? activeComboGroupId,
    required bool comboPoolRotatedToday,
    required Map<String, ProgressionQuest> questsById,
    required DateTime evaluationDate,
    required ProgressionProfile profile,
    required List<ProgressionEvaluation> evaluations,
    required List<ProgressionRewardGrant> rewardGrants,
    required List<ProgressionQuestRewardGrant> questRewardGrants,
    required Map<String, ProgressionChapterStartRecord> chapterStartsById,
    required List<ProgressionAchievement> achievements,
    required Map<String, ProgressionStreakSummary> streaksByRuleId,
    required Map<ProgressionDomain, ProgressionStreakSummary> streaksByDomain,
  }) {
    final chapterStartedAt = _chapterStartedAt(definition, chapterStartsById);
    final currentValue = _currentValue(
      definition: definition,
      profile: profile,
      evaluations: evaluations,
      rewardGrants: rewardGrants,
      questRewardGrants: questRewardGrants,
      chapterStartedAt: chapterStartedAt,
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
    final sequenceConditionsMet = activeDailySequenceStep == null ||
        definition.dailySequenceStep == activeDailySequenceStep;
    final comboPoolConditionsMet = definition.comboPoolId == null ||
        _displayGroupId(definition) == activeComboGroupId;
    final completionDeferredForRotation = comboPoolConditionsMet &&
        comboPoolRotatedToday &&
        definition.comboPoolId != null &&
        definition.isRepeatableReward;
    final completedByCriterion = !completionDeferredForRotation &&
        currentValue >= definition.targetValue;
    final completedAt = prerequisitesMet &&
            unlockConditionsMet &&
            sequenceConditionsMet &&
            comboPoolConditionsMet &&
            completedByCriterion
        ? _resolveEffectiveCompletedAt(
            definition: definition,
            prerequisiteCompletedAt: _latestPrerequisiteCompletedAt(
              definition: definition,
              questsById: questsById,
            ),
            profile: profile,
            evaluations: evaluations,
            rewardGrants: rewardGrants,
            questRewardGrants: questRewardGrants,
            chapterStartedAt: chapterStartedAt,
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
          : !sequenceConditionsMet || !comboPoolConditionsMet
              ? ProgressionQuestStatus.locked
              : completedByCriterion
                  ? ProgressionQuestStatus.completed
                  : ProgressionQuestStatus.available,
      targetValue: definition.targetValue,
      currentValue: currentValue,
      progress: _safeProgress(currentValue, definition.targetValue),
      prerequisiteQuestIds: definition.prerequisiteQuestIds,
      sortOrder: definition.sortOrder,
      priority: definition.priority,
      isHighlighted: false,
      rewardXp: definition.rewardXp,
      completedAt: completedAt,
      ruleId: definition.ruleId,
      domain: definition.domain,
      periodKind: definition.periodKind,
      achievementId: definition.achievementId,
      relatedRuleIds: definition.relatedRuleIds,
      requiredRuleCount: definition.requiredRuleCount,
      minimumLevel: definition.minimumLevel,
      minimumTrackedDays: definition.minimumTrackedDays,
      assetKey: definition.assetKey,
      visualDomain: definition.visualDomain,
      sourceLabel: definition.sourceLabel,
      chainId: definition.chainId,
      chainStepLabel: definition.chainStepLabel,
      nextQuestIds: definition.nextQuestIds,
      displayBucket: definition.displayBucket,
      displayGroupId: definition.displayGroupId,
      comboPoolId: definition.comboPoolId,
      chapterId: definition.chapterId,
      chapterStartedAt: chapterStartedAt,
      progressStartPolicy: definition.progressStartPolicy,
      dailySequenceId: definition.dailySequenceId,
      dailySequenceStep: definition.dailySequenceStep,
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
      rewardXp: quest.rewardXp,
      rewardKey: quest.rewardKey,
      rewardStatus: quest.rewardStatus,
      rewardUnlockedAt: quest.rewardUnlockedAt,
      rewardClaimedAt: quest.rewardClaimedAt,
      completedAt: quest.completedAt,
      ruleId: quest.ruleId,
      domain: quest.domain,
      periodKind: quest.periodKind,
      achievementId: quest.achievementId,
      relatedRuleIds: quest.relatedRuleIds,
      requiredRuleCount: quest.requiredRuleCount,
      minimumLevel: quest.minimumLevel,
      minimumTrackedDays: quest.minimumTrackedDays,
      assetKey: quest.assetKey,
      visualDomain: quest.visualDomain,
      sourceLabel: quest.sourceLabel,
      chainId: quest.chainId,
      chainStepLabel: quest.chainStepLabel,
      nextQuestIds: quest.nextQuestIds,
      displayBucket: quest.displayBucket,
      displayGroupId: quest.displayGroupId,
      comboPoolId: quest.comboPoolId,
      chapterId: quest.chapterId,
      chapterStartedAt: quest.chapterStartedAt,
      progressStartPolicy: quest.progressStartPolicy,
      dailySequenceId: quest.dailySequenceId,
      dailySequenceStep: quest.dailySequenceStep,
    );
  }

  Set<String> _resolveActiveQuestIds({
    required Iterable<ProgressionQuest> quests,
    required String? activeChapterId,
  }) {
    final availableQuests = quests
        .where((quest) => quest.status == ProgressionQuestStatus.available)
        .where((quest) =>
            quest.category != ProgressionQuestCategory.chapter ||
            quest.chapterId == activeChapterId)
        .toList()
      ..sort(_sortQuestSelection);
    return {for (final quest in availableQuests) quest.id};
  }

  String? _resolveActiveChapterId({
    required List<ProgressionQuestDefinition> definitions,
    required Map<String, ProgressionQuest> questsById,
    required List<ProgressionQuestRewardGrant> questRewardGrants,
  }) {
    final grantedQuestIds = {
      for (final grant in questRewardGrants) grant.questId,
    };
    final chapterOpenDefs = <String, ProgressionQuestDefinition>{};
    final chapterFinaleDefs = <String, ProgressionQuestDefinition>{};
    for (final def in definitions) {
      if (def.category != ProgressionQuestCategory.chapter) continue;
      final chapterId = def.chapterId;
      if (chapterId == null) continue;
      final isOpen =
          def.criterionType == ProgressionQuestCriterionType.chapterStarted &&
              def.prerequisiteQuestIds.isEmpty;
      final isFinale =
          def.criterionType == ProgressionQuestCriterionType.chapterStarted &&
              def.prerequisiteQuestIds.isNotEmpty;
      if (isOpen) chapterOpenDefs[chapterId] = def;
      if (isFinale) chapterFinaleDefs[chapterId] = def;
    }

    final orderedChapterIds = chapterOpenDefs.keys.toList()
      ..sort((left, right) {
        final leftDef = chapterOpenDefs[left]!;
        final rightDef = chapterOpenDefs[right]!;
        final bySortOrder = leftDef.sortOrder.compareTo(rightDef.sortOrder);
        if (bySortOrder != 0) return bySortOrder;
        return left.compareTo(right);
      });

    for (final chapterId in orderedChapterIds) {
      final openQuest = questsById[chapterOpenDefs[chapterId]!.id];
      if (openQuest == null) continue;
      // Level requirement not met — chapter and all later chapters are locked.
      if (openQuest.status == ProgressionQuestStatus.locked) {
        return null;
      }
      final finaleDef = chapterFinaleDefs[chapterId];
      // A chapter is "completed" only once its finale has a reward grant.
      // Criterion-only completion still keeps the chapter active so the
      // engine can issue the finale grant on this evaluation; the next
      // chapter only starts on the following evaluation cycle.
      final isCompleted =
          finaleDef != null && grantedQuestIds.contains(finaleDef.id);
      if (!isCompleted) return chapterId;
    }
    return null;
  }

  void _gateWaitingChapterChains({
    required List<ProgressionQuestDefinition> definitions,
    required Map<String, ProgressionQuest> questsById,
    required String? activeChapterId,
    required List<ProgressionQuestRewardGrant> questRewardGrants,
  }) {
    final grantedQuestIds = {
      for (final grant in questRewardGrants) grant.questId,
    };
    // A chapter is preserved as completed only once its finale has been
    // rewarded. Criterion-only completion keeps the chapter active so the
    // engine can issue the finale grant this cycle.
    final completedChapterIds = <String>{};
    for (final def in definitions) {
      if (def.category != ProgressionQuestCategory.chapter) continue;
      if (def.criterionType != ProgressionQuestCriterionType.chapterStarted) {
        continue;
      }
      if (def.prerequisiteQuestIds.isEmpty) continue;
      final chapterId = def.chapterId;
      if (chapterId == null) continue;
      if (grantedQuestIds.contains(def.id)) {
        completedChapterIds.add(chapterId);
      }
    }
    for (final def in definitions) {
      if (def.category != ProgressionQuestCategory.chapter) continue;
      final chapterId = def.chapterId;
      if (chapterId == null) continue;
      if (chapterId == activeChapterId) continue;
      if (completedChapterIds.contains(chapterId)) continue;
      final quest = questsById[def.id];
      if (quest == null) continue;
      // Preserve locked status (level requirement not met) and any quest
      // already historically rewarded — those stay completed/claimed.
      if (quest.status == ProgressionQuestStatus.locked) continue;
      if (grantedQuestIds.contains(def.id)) continue;
      questsById[def.id] = ProgressionQuest(
        id: quest.id,
        title: quest.title,
        description: quest.description,
        type: quest.type,
        category: quest.category,
        criterionType: quest.criterionType,
        status: ProgressionQuestStatus.available,
        targetValue: quest.targetValue,
        currentValue: 0,
        progress: 0,
        prerequisiteQuestIds: quest.prerequisiteQuestIds,
        sortOrder: quest.sortOrder,
        priority: quest.priority,
        isHighlighted: false,
        rewardXp: quest.rewardXp,
        completedAt: null,
        ruleId: quest.ruleId,
        domain: quest.domain,
        periodKind: quest.periodKind,
        achievementId: quest.achievementId,
        relatedRuleIds: quest.relatedRuleIds,
        requiredRuleCount: quest.requiredRuleCount,
        minimumLevel: quest.minimumLevel,
        minimumTrackedDays: quest.minimumTrackedDays,
        assetKey: quest.assetKey,
        visualDomain: quest.visualDomain,
        sourceLabel: quest.sourceLabel,
        chainId: quest.chainId,
        chainStepLabel: quest.chainStepLabel,
        nextQuestIds: quest.nextQuestIds,
        displayBucket: quest.displayBucket,
        displayGroupId: quest.displayGroupId,
        comboPoolId: quest.comboPoolId,
        chapterId: quest.chapterId,
        chapterStartedAt: quest.chapterStartedAt,
        progressStartPolicy: quest.progressStartPolicy,
        dailySequenceId: quest.dailySequenceId,
        dailySequenceStep: quest.dailySequenceStep,
      );
    }
  }

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
      case ProgressionQuestCategory.chapter:
        return 3;
      case ProgressionQuestCategory.journey:
        return 4;
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
    required List<ProgressionQuestRewardGrant> questRewardGrants,
    required DateTime? chapterStartedAt,
    required List<ProgressionAchievement> achievements,
    required Map<String, ProgressionStreakSummary> streaksByRuleId,
    required Map<ProgressionDomain, ProgressionStreakSummary> streaksByDomain,
  }) {
    final scopedEvaluations = _evaluationsAfterStart(
      definition: definition,
      evaluations: evaluations,
      chapterStartedAt: chapterStartedAt,
    );
    final scopedRewardGrants = _rewardGrantsAfterStart(
      definition: definition,
      rewardGrants: rewardGrants,
      chapterStartedAt: chapterStartedAt,
    );
    final scopedQuestRewardGrants = _questRewardGrantsAfterStart(
      definition: definition,
      questRewardGrants: questRewardGrants,
      chapterStartedAt: chapterStartedAt,
    );

    switch (definition.criterionType) {
      case ProgressionQuestCriterionType.chapterStarted:
        return chapterStartedAt == null ? 0 : 1;
      case ProgressionQuestCriterionType.totalXpAtLeast:
        if (definition.progressStartPolicy ==
            ProgressionProgressStartPolicy.chapterStartedAt) {
          return scopedRewardGrants.fold<int>(
                0,
                (sum, grant) => sum + grant.effectiveXpGranted,
              ) +
              scopedQuestRewardGrants.fold<int>(
                0,
                (sum, grant) => sum + grant.effectiveXpGranted,
              );
        }
        return profile.totalXp;
      case ProgressionQuestCriterionType.rewardCountAtLeast:
        return _matchingRewardGrants(
          definition: definition,
          rewardGrants: scopedRewardGrants,
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
          evaluations: scopedEvaluations,
        )
            .fold<double>(
              0,
              (sum, evaluation) => sum + evaluation.actualValue,
            )
            .round();
      case ProgressionQuestCriterionType.currentPeriodRuleCompletion:
        final latestEvaluation = _latestMatchingEvaluation(
          definition: definition,
          evaluations: scopedEvaluations,
        );
        return latestEvaluation?.achieved == true ? 1 : 0;
      case ProgressionQuestCriterionType.currentPeriodRuleSetAtLeast:
        return _currentPeriodRuleSetCompletionCount(
          definition: definition,
          evaluations: scopedEvaluations,
        );
      case ProgressionQuestCriterionType.ruleSetCompletionsAtLeast:
        return _ruleSetPeriodCompletionCount(
          definition: definition,
          evaluations: scopedEvaluations,
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
          evaluations: scopedEvaluations,
        ).length;
      case ProgressionQuestCriterionType.domainRewardCountAtLeast:
        return scopedRewardGrants
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
    required List<ProgressionQuestRewardGrant> questRewardGrants,
    required DateTime? chapterStartedAt,
    required List<ProgressionAchievement> achievements,
  }) {
    final criterionCompletedAt = _resolveCompletedAt(
      definition: definition,
      profile: profile,
      evaluations: evaluations,
      rewardGrants: rewardGrants,
      questRewardGrants: questRewardGrants,
      chapterStartedAt: chapterStartedAt,
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
    required List<ProgressionQuestRewardGrant> questRewardGrants,
    required DateTime? chapterStartedAt,
    required List<ProgressionAchievement> achievements,
  }) {
    final scopedEvaluations = _evaluationsAfterStart(
      definition: definition,
      evaluations: evaluations,
      chapterStartedAt: chapterStartedAt,
    );
    final scopedRewardGrants = _rewardGrantsAfterStart(
      definition: definition,
      rewardGrants: rewardGrants,
      chapterStartedAt: chapterStartedAt,
    );
    final scopedQuestRewardGrants = _questRewardGrantsAfterStart(
      definition: definition,
      questRewardGrants: questRewardGrants,
      chapterStartedAt: chapterStartedAt,
    );

    switch (definition.criterionType) {
      case ProgressionQuestCriterionType.chapterStarted:
        return chapterStartedAt;
      case ProgressionQuestCriterionType.totalXpAtLeast:
        return _resolveTotalXpCompletedAt(
          targetValue: definition.targetValue,
          rewardGrants: scopedRewardGrants,
          questRewardGrants: scopedQuestRewardGrants,
          profile: profile,
        );
      case ProgressionQuestCriterionType.rewardCountAtLeast:
        return _resolveRewardThresholdCompletedAt(
          targetValue: definition.targetValue,
          rewardGrants: _matchingRewardGrants(
            definition: definition,
            rewardGrants: scopedRewardGrants,
          ),
        );
      case ProgressionQuestCriterionType.bestStreakAtLeast:
        return _resolveStreakCompletedAt(
          targetValue: definition.targetValue,
          evaluations: _matchingEvaluations(
            definition: definition,
            evaluations: scopedEvaluations,
          ),
          aggregateByPeriod: definition.domain != null,
        );
      case ProgressionQuestCriterionType.totalRuleValueAtLeast:
        final ordered = _matchingEvaluations(
          definition: definition,
          evaluations: scopedEvaluations,
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
          evaluations: scopedEvaluations,
        );
        return latestEvaluation?.achieved == true
            ? latestEvaluation!.period.start
            : null;
      case ProgressionQuestCriterionType.currentPeriodRuleSetAtLeast:
        final latestPeriodStart = _latestRelevantPeriodStart(
          definition: definition,
          evaluations: scopedEvaluations,
        );
        if (latestPeriodStart == null) return null;
        final completedCount = _currentPeriodRuleSetCompletionCount(
          definition: definition,
          evaluations: scopedEvaluations,
        );
        return completedCount >= definition.targetValue
            ? latestPeriodStart
            : null;
      case ProgressionQuestCriterionType.ruleSetCompletionsAtLeast:
        final ordered = _ruleSetCompletedPeriodStarts(
          definition: definition,
          evaluations: scopedEvaluations,
        );
        if (ordered.length < definition.targetValue) return null;
        return ordered[definition.targetValue - 1];
      case ProgressionQuestCriterionType.achievementUnlocked:
        return _achievementForId(
          achievements: achievements,
          achievementId: definition.achievementId,
        )?.unlockedAt;
      case ProgressionQuestCriterionType.ruleCompletionsAtLeast:
        final ordered = _matchingAchievedEvaluations(
          definition: definition,
          evaluations: scopedEvaluations,
        )..sort((a, b) => a.period.start.compareTo(b.period.start));

        if (ordered.length < definition.targetValue) return null;
        return ordered[definition.targetValue - 1].period.start;
      case ProgressionQuestCriterionType.domainRewardCountAtLeast:
        final ordered = scopedRewardGrants
            .where((grant) => grant.domain == definition.domain)
            .toList()
          ..sort(_sortRewardGrants);

        if (ordered.length < definition.targetValue) return null;
        return ordered[definition.targetValue - 1].progressionAt;
    }
  }

  DateTime? _resolveTotalXpCompletedAt({
    required int targetValue,
    required List<ProgressionRewardGrant> rewardGrants,
    required List<ProgressionQuestRewardGrant> questRewardGrants,
    required ProgressionProfile profile,
  }) {
    final ordered = _xpEvents(
      rewardGrants: rewardGrants,
      questRewardGrants: questRewardGrants,
    )..sort((a, b) => a.at.compareTo(b.at));
    var runningXp = 0;
    for (final event in ordered) {
      runningXp += event.xp;
      if (runningXp >= targetValue) {
        return event.at;
      }
    }

    return profile.totalXp >= targetValue && ordered.isNotEmpty
        ? ordered.last.at
        : null;
  }

  DateTime? _resolveRewardThresholdCompletedAt({
    required int targetValue,
    required List<ProgressionRewardGrant> rewardGrants,
  }) {
    final ordered = [...rewardGrants]..sort(_sortRewardGrants);
    if (ordered.length < targetValue) return null;
    return ordered[targetValue - 1].progressionAt;
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

  DateTime? _chapterStartedAt(
    ProgressionQuestDefinition definition,
    Map<String, ProgressionChapterStartRecord> chapterStartsById,
  ) {
    final chapterId = definition.chapterId;
    if (chapterId == null) return null;
    return chapterStartsById[chapterId]?.startedAt;
  }

  List<ProgressionEvaluation> _evaluationsAfterStart({
    required ProgressionQuestDefinition definition,
    required List<ProgressionEvaluation> evaluations,
    required DateTime? chapterStartedAt,
  }) {
    if (definition.progressStartPolicy !=
            ProgressionProgressStartPolicy.chapterStartedAt ||
        chapterStartedAt == null) {
      return evaluations;
    }
    final startDay = progressionDate(chapterStartedAt);
    return evaluations
        .where((evaluation) => !evaluation.period.start.isBefore(startDay))
        .toList();
  }

  List<ProgressionRewardGrant> _rewardGrantsAfterStart({
    required ProgressionQuestDefinition definition,
    required List<ProgressionRewardGrant> rewardGrants,
    required DateTime? chapterStartedAt,
  }) {
    if (definition.progressStartPolicy !=
            ProgressionProgressStartPolicy.chapterStartedAt ||
        chapterStartedAt == null) {
      return rewardGrants;
    }
    return rewardGrants
        .where((grant) => !grant.progressionAt.isBefore(chapterStartedAt))
        .toList();
  }

  List<ProgressionQuestRewardGrant> _questRewardGrantsAfterStart({
    required ProgressionQuestDefinition definition,
    required List<ProgressionQuestRewardGrant> questRewardGrants,
    required DateTime? chapterStartedAt,
  }) {
    if (definition.progressStartPolicy !=
            ProgressionProgressStartPolicy.chapterStartedAt ||
        chapterStartedAt == null) {
      return questRewardGrants;
    }
    return questRewardGrants
        .where((grant) => !grant.progressionAt.isBefore(chapterStartedAt))
        .toList();
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

  int _ruleSetPeriodCompletionCount({
    required ProgressionQuestDefinition definition,
    required List<ProgressionEvaluation> evaluations,
  }) {
    return _ruleSetCompletedPeriodStarts(
      definition: definition,
      evaluations: evaluations,
    ).length;
  }

  List<DateTime> _ruleSetCompletedPeriodStarts({
    required ProgressionQuestDefinition definition,
    required List<ProgressionEvaluation> evaluations,
  }) {
    final requiredRuleCount = definition.requiredRuleCount;
    if (requiredRuleCount == null || requiredRuleCount <= 0) {
      return const [];
    }

    final completedRuleIdsByPeriod = <String, Set<String>>{};
    final periodStartByKey = <String, DateTime>{};
    for (final evaluation in _matchingEvaluations(
      definition: definition,
      evaluations: evaluations,
    )) {
      if (!evaluation.achieved) continue;
      final key =
          '${evaluation.period.kind.name}|${progressionDateKey(evaluation.period.start)}';
      completedRuleIdsByPeriod
          .putIfAbsent(key, () => <String>{})
          .add(evaluation.ruleId);
      periodStartByKey[key] = progressionDate(evaluation.period.start);
    }

    final completedStarts = <DateTime>[];
    for (final entry in completedRuleIdsByPeriod.entries) {
      if (entry.value.length >= requiredRuleCount) {
        completedStarts.add(periodStartByKey[entry.key]!);
      }
    }
    completedStarts.sort();
    return completedStarts;
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

    final matchingEvaluations = _matchingEvaluations(
      definition: definition,
      evaluations: evaluations,
    );
    final latestPeriodDay = progressionDate(latestPeriodStart);
    final relevantPeriodEvaluations = matchingEvaluations.where((evaluation) {
      return progressionDate(evaluation.period.start) == latestPeriodDay;
    }).toList()
      ..sort((left, right) => left.ruleId.compareTo(right.ruleId));
    final completedRuleIds = relevantPeriodEvaluations
        .where((evaluation) => evaluation.achieved)
        .map((evaluation) => evaluation.ruleId)
        .toSet();

    if (definition.id == 'daily_nutrition_combo_today') {
      _questLog.debug(
        'Evaluated rule-set quest ${definition.id}',
        payload: {
          'periodStart': latestPeriodStart.toIso8601String(),
          'targetValue': definition.targetValue,
          'relatedRuleIds': definition.relatedRuleIds,
          'completedRuleIds': completedRuleIds.toList()..sort(),
          'completedCount': completedRuleIds.length,
          'evaluations': [
            for (final evaluation in relevantPeriodEvaluations)
              {
                'ruleId': evaluation.ruleId,
                'achieved': evaluation.achieved,
                'actualValue': evaluation.actualValue,
                'targetValue': evaluation.targetValue,
                'upperTargetValue': evaluation.upperTargetValue,
                'toleranceRatio': evaluation.toleranceRatio,
                'progress': evaluation.progress,
                'status': evaluation.status.name,
                'missReason': evaluation.missReason?.name,
                'explanation': evaluation.explanation,
              },
          ],
        },
      );
    }

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
    final byGrantedAt = left.progressionAt.compareTo(right.progressionAt);
    if (byGrantedAt != 0) return byGrantedAt;

    final byPeriod = left.period.start.compareTo(right.period.start);
    if (byPeriod != 0) return byPeriod;

    return left.rewardKey.compareTo(right.rewardKey);
  }

  List<_QuestXpEvent> _xpEvents({
    required List<ProgressionRewardGrant> rewardGrants,
    required List<ProgressionQuestRewardGrant> questRewardGrants,
  }) {
    return [
      for (final grant in rewardGrants)
        if (grant.effectiveXpGranted > 0)
          _QuestXpEvent(
            at: grant.progressionAt,
            xp: grant.effectiveXpGranted,
          ),
      for (final grant in questRewardGrants)
        if (grant.effectiveXpGranted > 0)
          _QuestXpEvent(
            at: grant.progressionAt,
            xp: grant.effectiveXpGranted,
          ),
    ];
  }
}

class _ComboPoolSelection {
  const _ComboPoolSelection({
    required this.activeGroupByPool,
    required this.rotatedPoolIds,
  });

  const _ComboPoolSelection.empty()
      : activeGroupByPool = const {},
        rotatedPoolIds = const {};

  final Map<String, String> activeGroupByPool;
  final Set<String> rotatedPoolIds;
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

class _QuestXpEvent {
  const _QuestXpEvent({
    required this.at,
    required this.xp,
  });

  final DateTime at;
  final int xp;
}
