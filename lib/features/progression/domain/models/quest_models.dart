import '../../../../shared/domain/rarity.dart';
import 'core_models.dart';

export '../../../../shared/domain/rarity.dart' show Rarity;

enum ProgressionQuestType {
  milestone,
  streak,
  mastery,
}

enum ProgressionQuestCategory {
  journey,
  chapter,
  daily,
  weekly,
  chain,
}

enum ProgressionQuestDisplayBucket {
  daily,
  weekly,
  chapter,
  longTerm,
}

enum ProgressionQuestCriterionType {
  chapterStarted,
  totalXpAtLeast,
  rewardCountAtLeast,
  bestStreakAtLeast,
  totalRuleValueAtLeast,
  currentPeriodRuleCompletion,
  currentPeriodRuleSetAtLeast,
  ruleSetCompletionsAtLeast,
  achievementUnlocked,
  ruleCompletionsAtLeast,
  domainRewardCountAtLeast,
}

enum ProgressionProgressStartPolicy {
  lifetime,
  chapterStartedAt,
}

enum ProgressionQuestStatus {
  locked,
  available,
  active,
  completed,
}

class ProgressionQuestRewardGrant {
  const ProgressionQuestRewardGrant({
    required this.rewardKey,
    required this.questId,
    required this.xpGranted,
    required this.rewardStatus,
    required this.unlockedAt,
    required this.completedAt,
    this.claimedAt,
    this.finalXp,
    this.levelAtClaim,
    this.multiplierAtClaim,
    this.baseXp,
  });

  final String rewardKey;
  final String questId;
  final int xpGranted;
  final ProgressionRewardStatus rewardStatus;
  final DateTime unlockedAt;
  final DateTime completedAt;
  final DateTime? claimedAt;
  final int? finalXp;
  final int? levelAtClaim;
  final double? multiplierAtClaim;
  final int? baseXp;

  bool get isClaimed => rewardStatus == ProgressionRewardStatus.claimed;
  bool get isUnlocked => rewardStatus == ProgressionRewardStatus.unlocked;
  int get effectiveXpGranted => isClaimed ? (finalXp ?? xpGranted) : 0;
  DateTime get progressionAt => claimedAt ?? unlockedAt;
}

class ProgressionChapterStartRecord {
  const ProgressionChapterStartRecord({
    required this.uid,
    required this.chapterId,
    required this.startedAtLevel,
    required this.startedAt,
  });

  final String uid;
  final String chapterId;
  final int startedAtLevel;
  final DateTime startedAt;

  String get startKey => 'chapter|$chapterId|start';
}

class ProgressionQuestDefinition {
  const ProgressionQuestDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.criterionType,
    required this.targetValue,
    required this.rewardXp,
    required this.rarity,
    this.cosmeticRewards = const [],
    this.assetKey,
    this.visualDomain,
    this.sourceLabel,
    this.chainId,
    this.chainStepLabel,
    this.nextQuestIds = const [],
    this.displayBucket,
    this.displayGroupId,
    this.comboPoolId,
    this.chapterId,
    this.progressStartPolicy = ProgressionProgressStartPolicy.lifetime,
    this.requiredRuleCount,
    this.dailySequenceId,
    this.dailySequenceStep,
    this.ruleId,
    this.domain,
    this.periodKind,
    this.achievementId,
    this.relatedRuleIds = const [],
    this.minimumLevel,
    this.minimumTrackedDays,
    this.prerequisiteQuestIds = const [],
    this.sortOrder = 0,
    this.priority = 0,
  });

  final String id;
  final ProgressionLocalizedText title;
  final ProgressionLocalizedText description;
  final ProgressionQuestType type;
  final ProgressionQuestCategory category;
  final ProgressionQuestCriterionType criterionType;
  final int targetValue;
  final int rewardXp;

  /// Rarity of the moment when this quest is completed. Drives the
  /// celebration's accent color, glow, particles, and routes to the
  /// fullscreen variant when high enough. Authored on the catalog entry,
  /// not derived downstream.
  final Rarity rarity;

  /// Cosmetic ids unlocked when this quest's reward grant transitions to
  /// `unlocked` (and via the dispatcher's catch-up pass on cold load).
  /// Authored next to the quest itself so adding a new quest with a
  /// cosmetic drop is one catalog edit, not a parallel-table edit.
  final List<String> cosmeticRewards;

  final String? ruleId;
  final ProgressionDomain? domain;
  final ProgressionPeriodKind? periodKind;
  final String? achievementId;
  final List<String> relatedRuleIds;
  final int? minimumLevel;
  final int? minimumTrackedDays;
  final List<String> prerequisiteQuestIds;
  final int sortOrder;
  final int priority;
  final String? assetKey;
  final ProgressionDomain? visualDomain;

  final ProgressionLocalizedText? sourceLabel;
  final String? chainId;
  final ProgressionLocalizedText? chainStepLabel;
  final List<String> nextQuestIds;
  final ProgressionQuestDisplayBucket? displayBucket;
  final String? displayGroupId;
  final String? comboPoolId;
  final String? chapterId;
  final ProgressionProgressStartPolicy progressStartPolicy;
  final int? requiredRuleCount;
  final String? dailySequenceId;
  final int? dailySequenceStep;

  bool get isRepeatableReward =>
      criterionType ==
          ProgressionQuestCriterionType.currentPeriodRuleCompletion ||
      criterionType ==
          ProgressionQuestCriterionType.currentPeriodRuleSetAtLeast;

  String rewardKeyFor(DateTime completedAt) {
    if (!isRepeatableReward) return 'quest|$id|reward';
    final anchor = progressionDateKey(completedAt);
    return 'quest|$id|$anchor|reward';
  }
}

class ProgressionQuest {
  const ProgressionQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.criterionType,
    required this.status,
    required this.targetValue,
    required this.currentValue,
    required this.progress,
    required this.prerequisiteQuestIds,
    required this.sortOrder,
    required this.priority,
    required this.isHighlighted,
    required this.rarity,
    this.cosmeticRewards = const [],
    this.rewardXp = 0,
    this.rewardKey,
    this.rewardStatus,
    this.rewardUnlockedAt,
    this.rewardClaimedAt,
    this.completedAt,
    this.ruleId,
    this.domain,
    this.periodKind,
    this.achievementId,
    this.relatedRuleIds = const [],
    this.minimumLevel,
    this.minimumTrackedDays,
    this.assetKey,
    this.visualDomain,
    this.sourceLabel,
    this.chainId,
    this.chainStepLabel,
    this.nextQuestIds = const [],
    this.displayBucket,
    this.displayGroupId,
    this.comboPoolId,
    this.chapterId,
    this.chapterStartedAt,
    this.progressStartPolicy = ProgressionProgressStartPolicy.lifetime,
    this.requiredRuleCount,
    this.dailySequenceId,
    this.dailySequenceStep,
  });

  final String id;
  final ProgressionLocalizedText title;
  final ProgressionLocalizedText description;
  final ProgressionQuestType type;
  final ProgressionQuestCategory category;
  final ProgressionQuestCriterionType criterionType;
  final ProgressionQuestStatus status;
  final int targetValue;
  final int currentValue;
  final double progress;
  final List<String> prerequisiteQuestIds;
  final int sortOrder;
  final int priority;
  final bool isHighlighted;

  /// Mirrored from [ProgressionQuestDefinition.rarity] when the runtime
  /// instance is constructed by the evaluator. Lets consumers (celebration
  /// adapter, quest cards) read the rarity off the runtime quest without
  /// looking the definition back up.
  final Rarity rarity;

  /// Mirrored from [ProgressionQuestDefinition.cosmeticRewards].
  final List<String> cosmeticRewards;

  final int rewardXp;
  final String? rewardKey;
  final ProgressionRewardStatus? rewardStatus;
  final DateTime? rewardUnlockedAt;
  final DateTime? rewardClaimedAt;
  final DateTime? completedAt;
  final String? ruleId;
  final ProgressionDomain? domain;
  final ProgressionPeriodKind? periodKind;
  final String? achievementId;
  final List<String> relatedRuleIds;
  final int? minimumLevel;
  final int? minimumTrackedDays;
  final String? assetKey;
  final ProgressionDomain? visualDomain;
  final ProgressionLocalizedText? sourceLabel;
  final String? chainId;
  final ProgressionLocalizedText? chainStepLabel;
  final List<String> nextQuestIds;
  final ProgressionQuestDisplayBucket? displayBucket;
  final String? displayGroupId;
  final String? comboPoolId;
  final String? chapterId;
  final DateTime? chapterStartedAt;
  final ProgressionProgressStartPolicy progressStartPolicy;
  final int? requiredRuleCount;
  final String? dailySequenceId;
  final int? dailySequenceStep;

  bool get isCompleted => status == ProgressionQuestStatus.completed;
  bool get isLocked => status == ProgressionQuestStatus.locked;
  bool get isActive => status == ProgressionQuestStatus.active;
  bool get hasReward => rewardXp > 0;
  bool get isRewardClaimable =>
      rewardStatus == ProgressionRewardStatus.unlocked;
  bool get isRewardClaimed => rewardStatus == ProgressionRewardStatus.claimed;
}
