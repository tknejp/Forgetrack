import '../domain/progression_models.dart';

enum QuestUnlockReasonType {
  prerequisiteQuest,
  level,
  trackedDays,
}

class QuestUnlockReason {
  const QuestUnlockReason.prerequisite(this.questId)
      : type = QuestUnlockReasonType.prerequisiteQuest,
        value = null;

  const QuestUnlockReason.level(this.value)
      : type = QuestUnlockReasonType.level,
        questId = null;

  const QuestUnlockReason.trackedDays(this.value)
      : type = QuestUnlockReasonType.trackedDays,
        questId = null;

  final QuestUnlockReasonType type;
  final String? questId;
  final int? value;
}

class QuestDetailViewModel {
  const QuestDetailViewModel({
    required this.quest,
    required this.unlockReasons,
    required this.unlocksNext,
    required this.relatedRuleIds,
  });

  factory QuestDetailViewModel.build({
    required ProgressionQuest quest,
    required Iterable<ProgressionQuest> allQuests,
    required ProgressionProfile profile,
    int? trackedDaysElapsed,
  }) {
    final questsById = {
      for (final candidate in allQuests) candidate.id: candidate,
    };
    final unlockReasons = <QuestUnlockReason>[];

    if (quest.isLocked) {
      for (final prerequisiteId in quest.prerequisiteQuestIds) {
        final prerequisite = questsById[prerequisiteId];
        if (prerequisite == null || !prerequisite.isCompleted) {
          unlockReasons.add(QuestUnlockReason.prerequisite(prerequisiteId));
        }
      }

      final minimumLevel = quest.minimumLevel;
      if (minimumLevel != null && profile.level < minimumLevel) {
        unlockReasons.add(QuestUnlockReason.level(minimumLevel));
      }

      final minimumTrackedDays = quest.minimumTrackedDays;
      if (minimumTrackedDays != null &&
          (trackedDaysElapsed == null ||
              trackedDaysElapsed < minimumTrackedDays)) {
        unlockReasons.add(QuestUnlockReason.trackedDays(minimumTrackedDays));
      }
    }

    final unlocksNext = allQuests
        .where((candidate) => candidate.prerequisiteQuestIds.contains(quest.id))
        .toList(growable: false)
      ..sort((left, right) {
        final bySortOrder = left.sortOrder.compareTo(right.sortOrder);
        if (bySortOrder != 0) return bySortOrder;
        return left.id.compareTo(right.id);
      });

    final relatedRuleIds = <String>[];
    void addRule(String? ruleId) {
      if (ruleId == null || relatedRuleIds.contains(ruleId)) return;
      relatedRuleIds.add(ruleId);
    }

    addRule(quest.ruleId);
    for (final ruleId in quest.relatedRuleIds) {
      addRule(ruleId);
    }

    return QuestDetailViewModel(
      quest: quest,
      unlockReasons: unlockReasons,
      unlocksNext: unlocksNext,
      relatedRuleIds: relatedRuleIds,
    );
  }

  final ProgressionQuest quest;
  final List<QuestUnlockReason> unlockReasons;
  final List<ProgressionQuest> unlocksNext;
  final List<String> relatedRuleIds;
}
