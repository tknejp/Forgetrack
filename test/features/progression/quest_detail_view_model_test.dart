import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/features/progression/domain/progression_models.dart';
import 'package:forgetrack/features/progression/presentation/quest_detail_view_model.dart';

void main() {
  group('QuestDetailViewModel', () {
    test('reports unmet prerequisite quests', () {
      final prerequisite = _quest(
        id: 'first',
        status: ProgressionQuestStatus.active,
      );
      final locked = _quest(
        id: 'second',
        status: ProgressionQuestStatus.locked,
        prerequisiteQuestIds: ['first'],
      );

      final detail = QuestDetailViewModel.build(
        quest: locked,
        allQuests: [prerequisite, locked],
        profile: _profile(level: 1),
      );

      expect(detail.unlockReasons, hasLength(1));
      expect(detail.unlockReasons.single.type,
          QuestUnlockReasonType.prerequisiteQuest);
      expect(detail.unlockReasons.single.questId, 'first');
    });

    test('reports unmet level gates', () {
      final locked = _quest(
        id: 'level_gate',
        status: ProgressionQuestStatus.locked,
        minimumLevel: 8,
      );

      final detail = QuestDetailViewModel.build(
        quest: locked,
        allQuests: [locked],
        profile: _profile(level: 4),
      );

      expect(detail.unlockReasons, hasLength(1));
      expect(detail.unlockReasons.single.type, QuestUnlockReasonType.level);
      expect(detail.unlockReasons.single.value, 8);
    });

    test('reports tracked-day gates for locked quests', () {
      final locked = _quest(
        id: 'tracked_gate',
        status: ProgressionQuestStatus.locked,
        minimumTrackedDays: 14,
      );

      final detail = QuestDetailViewModel.build(
        quest: locked,
        allQuests: [locked],
        profile: _profile(level: 10),
      );

      expect(detail.unlockReasons, hasLength(1));
      expect(
        detail.unlockReasons.single.type,
        QuestUnlockReasonType.trackedDays,
      );
      expect(detail.unlockReasons.single.value, 14);
    });

    test('does not report tracked-day gates that are already satisfied', () {
      final locked = _quest(
        id: 'tracked_gate',
        status: ProgressionQuestStatus.locked,
        minimumTrackedDays: 14,
      );

      final detail = QuestDetailViewModel.build(
        quest: locked,
        allQuests: [locked],
        profile: _profile(level: 10),
        trackedDaysElapsed: 20,
      );

      expect(detail.unlockReasons, isEmpty);
    });

    test('lists quests unlocked by the selected quest', () {
      final root = _quest(id: 'root');
      final later = _quest(
        id: 'later',
        prerequisiteQuestIds: ['root'],
        sortOrder: 20,
      );
      final next = _quest(
        id: 'next',
        prerequisiteQuestIds: ['root'],
        sortOrder: 10,
      );

      final detail = QuestDetailViewModel.build(
        quest: root,
        allQuests: [root, later, next],
        profile: _profile(level: 1),
      );

      expect(detail.unlocksNext.map((quest) => quest.id), ['next', 'later']);
    });
  });
}

ProgressionProfile _profile({required int level}) {
  return ProgressionProfile(
    totalXp: 0,
    level: level,
    levelFloorXp: 0,
    nextLevelXp: 250,
    xpIntoLevel: 0,
  );
}

ProgressionQuest _quest({
  required String id,
  ProgressionQuestStatus status = ProgressionQuestStatus.available,
  List<String> prerequisiteQuestIds = const [],
  int? minimumLevel,
  int? minimumTrackedDays,
  int sortOrder = 0,
}) {
  return ProgressionQuest(
    id: id,
    title: id,
    description: id,
    type: ProgressionQuestType.milestone,
    category: ProgressionQuestCategory.journey,
    criterionType: ProgressionQuestCriterionType.rewardCountAtLeast,
    status: status,
    targetValue: 1,
    currentValue: 0,
    progress: 0,
    prerequisiteQuestIds: prerequisiteQuestIds,
    sortOrder: sortOrder,
    priority: 0,
    isHighlighted: false,
    minimumLevel: minimumLevel,
    minimumTrackedDays: minimumTrackedDays,
  );
}
