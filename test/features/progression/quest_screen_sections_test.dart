import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/features/progression/domain/progression_models.dart';
import 'package:forgetrack/features/progression/presentation/quests/quest_screen_sections.dart';
import 'package:forgetrack/features/progression/presentation/widgets/progression_internals.dart';
import 'package:forgetrack/l10n/app_localizations_en.dart';

void main() {
  group('QuestDisplayPolicy', () {
    test('hides daily goal chains but keeps daily combo chains', () {
      final dailyGoal = _quest(
        id: 'daily_goal',
        category: ProgressionQuestCategory.daily,
        criterionType:
            ProgressionQuestCriterionType.currentPeriodRuleCompletion,
        chainId: 'daily_goals',
      );
      final dailyCombo = _quest(
        id: 'daily_combo',
        category: ProgressionQuestCategory.daily,
        criterionType:
            ProgressionQuestCriterionType.currentPeriodRuleSetAtLeast,
        chainId: 'daily_combo',
        comboPoolId: 'daily_combo_pool',
      );

      expect(QuestDisplayPolicy.shouldShowChainPreview(dailyGoal), isFalse);
      expect(QuestDisplayPolicy.shouldShowChainPreview(dailyCombo), isTrue);
    });

    test('detects chapter opener from metadata instead of id suffix', () {
      final opener = _quest(
        id: 'chapter_intro',
        category: ProgressionQuestCategory.chapter,
        criterionType: ProgressionQuestCriterionType.chapterStarted,
        displayBucket: ProgressionQuestDisplayBucket.chapter,
      );
      final finale = _quest(
        id: 'chapter_reward',
        category: ProgressionQuestCategory.chapter,
        criterionType: ProgressionQuestCriterionType.chapterStarted,
        displayBucket: ProgressionQuestDisplayBucket.chapter,
        prerequisiteQuestIds: const ['chapter_step'],
      );

      expect(QuestDisplayPolicy.isChapterOpenQuest(opener), isTrue);
      expect(QuestDisplayPolicy.isChapterOpenQuest(finale), isFalse);
    });
  });

  group('QuestScreenSectionsBuilder', () {
    test('orders chapter, daily, combo, weekly, long-term, locked, completed',
        () {
      final sections = _buildSections(
        chapterQuests: [_chapterQuest('chapter_active')],
        dailyGoalQuests: [_quest(id: 'daily_goal')],
        dailyComboQuests: [_quest(id: 'daily_combo')],
        weeklyQuests: [_quest(id: 'weekly')],
        longTermQuests: [_quest(id: 'long_term')],
        lockedQuests: [
          _quest(id: 'locked', status: ProgressionQuestStatus.locked)
        ],
        completedQuests: [
          _quest(id: 'completed', status: ProgressionQuestStatus.completed),
        ],
      ).sections;

      expect(
        sections.map((section) => section.type),
        [
          QuestSectionType.chapter,
          QuestSectionType.dailyGoals,
          QuestSectionType.dailyCombo,
          QuestSectionType.weekly,
          QuestSectionType.longTerm,
          QuestSectionType.locked,
          QuestSectionType.completed,
        ],
      );
    });

    test('hides future locked chapters while a chapter is active', () {
      final sections = _buildSections(
        chapterQuests: [_chapterQuest('current_chapter')],
        lockedQuests: [
          _quest(
              id: 'non_chapter_locked', status: ProgressionQuestStatus.locked),
          _chapterQuest(
            'next_chapter',
            status: ProgressionQuestStatus.locked,
          ),
          _chapterQuest(
            'later_chapter',
            status: ProgressionQuestStatus.locked,
          ),
        ],
      ).sections;

      final locked = sections.singleWhere(
        (section) => section.type == QuestSectionType.locked,
      );

      expect(
          locked.quests.map((card) => card.quest.id), ['non_chapter_locked']);
    });

    test('shows only next locked chapter preview when no chapter is active',
        () {
      final sections = _buildSections(
        lockedQuests: [
          _chapterQuest(
            'second_chapter',
            status: ProgressionQuestStatus.locked,
            sortOrder: 20,
          ),
          _chapterQuest(
            'first_chapter',
            status: ProgressionQuestStatus.locked,
            sortOrder: 10,
          ),
        ],
      ).sections;

      final locked = sections.singleWhere(
        (section) => section.type == QuestSectionType.locked,
      );

      expect(locked.quests.map((card) => card.quest.id), ['first_chapter']);
    });

    test(
        'completed compaction keeps claim-all target from all completed quests',
        () {
      final sections = _buildSections(
        completedQuests: [
          _quest(id: 'one', status: ProgressionQuestStatus.completed),
          _quest(id: 'two', status: ProgressionQuestStatus.completed),
          _quest(id: 'three', status: ProgressionQuestStatus.completed),
          _quest(
            id: 'four',
            status: ProgressionQuestStatus.completed,
            rewardStatus: ProgressionRewardStatus.unlocked,
          ),
        ],
        completedCompactLimit: 3,
      ).sections;

      final completed = sections.singleWhere(
        (section) => section.type == QuestSectionType.completed,
      );

      expect(completed.quests.map((card) => card.quest.id), [
        'one',
        'two',
        'three',
      ]);
      expect(completed.claimableCompleted.map((quest) => quest.id), ['four']);
      expect(completed.totalQuestCount, 4);
    });
  });
}

QuestScreenSections _buildSections({
  List<ProgressionQuest> chapterQuests = const [],
  List<ProgressionQuest> dailyGoalQuests = const [],
  List<ProgressionQuest> dailyComboQuests = const [],
  List<ProgressionQuest> weeklyQuests = const [],
  List<ProgressionQuest> longTermQuests = const [],
  List<ProgressionQuest> lockedQuests = const [],
  List<ProgressionQuest> completedQuests = const [],
  int completedCompactLimit = 3,
}) {
  final allQuests = [
    ...chapterQuests,
    ...dailyGoalQuests,
    ...dailyComboQuests,
    ...weeklyQuests,
    ...longTermQuests,
    ...lockedQuests,
    ...completedQuests,
  ];

  return QuestScreenSectionsBuilder(
    viewData: ProgressionViewData(
      profile: _profile(),
      xpSpan: 100,
      unlocked: const [],
      inProgress: const [],
      allQuests: allQuests,
      trackedDaysElapsed: 0,
      dailyGoalQuests: dailyGoalQuests,
      dailyComboQuests: dailyComboQuests,
      weeklyQuests: weeklyQuests,
      chapterQuests: chapterQuests,
      longTermQuests: longTermQuests,
      lockedQuests: lockedQuests,
      completedQuests: completedQuests,
      pendingRewards: const [],
      rewardHistory: const [],
      current: null,
      best: null,
    ),
    l10n: AppLocalizationsEn(),
    completedCompactLimit: completedCompactLimit,
    showAllCompleted: false,
  ).build();
}

ProgressionQuest _chapterQuest(
  String id, {
  ProgressionQuestStatus status = ProgressionQuestStatus.active,
  int sortOrder = 0,
}) {
  return _quest(
    id: id,
    category: ProgressionQuestCategory.chapter,
    criterionType: ProgressionQuestCriterionType.chapterStarted,
    status: status,
    displayBucket: ProgressionQuestDisplayBucket.chapter,
    chainId: id,
    sortOrder: sortOrder,
  );
}

ProgressionQuest _quest({
  required String id,
  ProgressionQuestCategory category = ProgressionQuestCategory.journey,
  ProgressionQuestCriterionType criterionType =
      ProgressionQuestCriterionType.rewardCountAtLeast,
  ProgressionQuestStatus status = ProgressionQuestStatus.active,
  ProgressionQuestDisplayBucket? displayBucket,
  List<String> prerequisiteQuestIds = const [],
  String? chainId,
  String? comboPoolId,
  int sortOrder = 0,
  ProgressionRewardStatus? rewardStatus,
}) {
  return ProgressionQuest(
    id: id,
    title: (l10n) => id,
    description: (l10n) => id,
    type: ProgressionQuestType.milestone,
    category: category,
    criterionType: criterionType,
    status: status,
    targetValue: 1,
    currentValue: status == ProgressionQuestStatus.completed ? 1 : 0,
    progress: status == ProgressionQuestStatus.completed ? 1 : 0,
    prerequisiteQuestIds: prerequisiteQuestIds,
    sortOrder: sortOrder,
    priority: 0,
    isHighlighted: false,
    chainId: chainId,
    comboPoolId: comboPoolId,
    displayBucket: displayBucket,
    rewardXp: 10,
    rewardKey: rewardStatus == null ? null : 'quest|$id|reward',
    rewardStatus: rewardStatus,
  );
}

ProgressionProfile _profile() {
  return const ProgressionProfile(
    totalXp: 0,
    level: 1,
    levelFloorXp: 0,
    nextLevelXp: 100,
    xpIntoLevel: 0,
  );
}
