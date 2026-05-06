import 'achievement_models.dart';
import 'quest_models.dart';
import 'rule_models.dart';

class ProgressionLedgerSnapshot {
  const ProgressionLedgerSnapshot({
    required this.evaluations,
    required this.rewardGrants,
    this.questRewardGrants = const [],
    this.activeQuestIds = const <String>{},
    this.achievementUnlocks = const [],
    this.chapterStarts = const [],
    this.lastEvaluatedAt,
  });

  final List<ProgressionEvaluation> evaluations;
  final List<ProgressionRewardGrant> rewardGrants;
  final List<ProgressionQuestRewardGrant> questRewardGrants;
  final Set<String> activeQuestIds;
  final List<ProgressionAchievementUnlockEvent> achievementUnlocks;
  final List<ProgressionChapterStartRecord> chapterStarts;
  final DateTime? lastEvaluatedAt;
}
