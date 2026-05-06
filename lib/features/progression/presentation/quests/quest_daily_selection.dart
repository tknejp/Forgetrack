import '../../domain/progression_models.dart';

const dailyGoalQuestChainId = 'daily_goals';

const dailyComboPoolId = 'daily_combo_pool';

bool isDailyGoalQuest(ProgressionQuest quest) {
  return quest.chainId == dailyGoalQuestChainId &&
      quest.criterionType ==
          ProgressionQuestCriterionType.currentPeriodRuleCompletion;
}

bool isComboPoolQuest(ProgressionQuest quest) {
  return quest.comboPoolId != null && isCurrentPeriodQuest(quest);
}

bool isCurrentPeriodQuest(ProgressionQuest quest) {
  return quest.criterionType ==
          ProgressionQuestCriterionType.currentPeriodRuleCompletion ||
      quest.criterionType ==
          ProgressionQuestCriterionType.currentPeriodRuleSetAtLeast;
}

ProgressionQuestDisplayBucket displayBucketForQuest(ProgressionQuest quest) {
  final explicit = quest.displayBucket;
  if (explicit != null) return explicit;

  switch (quest.category) {
    case ProgressionQuestCategory.daily:
      return ProgressionQuestDisplayBucket.daily;
    case ProgressionQuestCategory.weekly:
      return ProgressionQuestDisplayBucket.weekly;
    case ProgressionQuestCategory.chapter:
      return ProgressionQuestDisplayBucket.chapter;
    case ProgressionQuestCategory.journey:
    case ProgressionQuestCategory.chain:
      return ProgressionQuestDisplayBucket.longTerm;
  }
}

String displayGroupIdForQuest(ProgressionQuest quest) {
  return quest.displayGroupId ?? quest.chainId ?? quest.id;
}

List<ProgressionQuest> selectDailyGoalQuestsForDate(
  Iterable<ProgressionQuest> quests,
  DateTime date, {
  int count = 2,
}) {
  final dayKey = progressionDateKey(date);
  final candidates = quests.where((quest) {
    if (!isDailyGoalQuest(quest)) return false;
    return quest.isActive || quest.isCompleted;
  }).toList(growable: false)
    ..sort((left, right) {
      final byScore = _dailyScore(dayKey, left.id).compareTo(
        _dailyScore(dayKey, right.id),
      );
      if (byScore != 0) return byScore;
      return left.id.compareTo(right.id);
    });

  final selected = candidates.take(count).toList(growable: false);
  selected.sort((left, right) {
    final byCompleted = left.isCompleted == right.isCompleted
        ? 0
        : left.isCompleted
            ? 1
            : -1;
    if (byCompleted != 0) return byCompleted;
    final byProgress = right.progress.compareTo(left.progress);
    if (byProgress != 0) return byProgress;
    return left.sortOrder.compareTo(right.sortOrder);
  });
  return selected;
}

List<ProgressionQuest> selectDailyComboQuestsForDate(
  Iterable<ProgressionQuest> quests,
  DateTime date,
) {
  final byGroup = <String, List<ProgressionQuest>>{};
  for (final quest in quests) {
    if (!isComboPoolQuest(quest)) continue;
    if (!quest.isActive && !quest.isCompleted) continue;
    byGroup.putIfAbsent(displayGroupIdForQuest(quest), () => []).add(quest);
  }

  if (byGroup.isEmpty) return const [];

  final dayKey = progressionDateKey(date);
  final selectedGroup = byGroup.keys.toList(growable: false)
    ..sort((left, right) {
      final byScore = _dailyScore(dayKey, left).compareTo(
        _dailyScore(dayKey, right),
      );
      if (byScore != 0) return byScore;
      return left.compareTo(right);
    });

  final selected = byGroup[selectedGroup.first]!..sort(_sortVisibleQuests);
  return selected.take(1).toList(growable: false);
}

List<ProgressionQuest> compactQuestChainRepresentatives(
  Iterable<ProgressionQuest> quests, {
  required ProgressionQuestDisplayBucket bucket,
}) {
  final byGroup = <String, List<ProgressionQuest>>{};
  for (final quest in quests) {
    if (displayBucketForQuest(quest) != bucket) continue;
    if (isDailyGoalQuest(quest) || isComboPoolQuest(quest)) continue;
    if (!quest.isActive && !quest.isCompleted) continue;
    if (quest.isCompleted && !quest.isRewardClaimable) continue;
    byGroup.putIfAbsent(displayGroupIdForQuest(quest), () => []).add(quest);
  }

  final representatives = <ProgressionQuest>[];
  for (final group in byGroup.values) {
    group.sort(_sortVisibleQuests);
    representatives.add(group.first);
  }

  representatives.sort((left, right) {
    final byBucket = displayBucketForQuest(left).index.compareTo(
          displayBucketForQuest(right).index,
        );
    if (byBucket != 0) return byBucket;
    return _sortVisibleQuests(left, right);
  });
  return representatives;
}

int _sortVisibleQuests(ProgressionQuest left, ProgressionQuest right) {
  if (left.isRewardClaimable != right.isRewardClaimable) {
    return left.isRewardClaimable ? -1 : 1;
  }
  if (left.isCompleted != right.isCompleted) {
    return left.isCompleted ? -1 : 1;
  }
  final byProgress = right.progress.compareTo(left.progress);
  if (byProgress != 0) return byProgress;
  final byPriority = right.priority.compareTo(left.priority);
  if (byPriority != 0) return byPriority;
  final bySortOrder = left.sortOrder.compareTo(right.sortOrder);
  if (bySortOrder != 0) return bySortOrder;
  return left.id.compareTo(right.id);
}

int _dailyScore(String dayKey, String questId) {
  var hash = 0x811c9dc5;
  for (final unit in '$dayKey|$questId'.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash;
}
