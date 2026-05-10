import 'package:flutter/foundation.dart';

import '../../../../shared/domain/rarity.dart';
import '../localized_text.dart';
import 'activation_policy.dart';
import 'claim_policy.dart';
import 'content_tag.dart';
import 'progress_start_policy.dart';
import 'quest_display_bucket.dart';
import 'reward_definition.dart';
import 'unlock_condition.dart';

/// Player-facing meaning of a completed objective or unlock condition.
/// Sealed so each node type carries only its own fields and the
/// resolver / display layer get exhaustive switch checking.
///
/// V1 had a single monolithic `ProgressionQuestDefinition` with 35+
/// optional fields whose meaning depended on a `category` enum. V2
/// splits that into one subclass per node type: each carries only the
/// fields it actually needs.
@immutable
sealed class ProgressionNode {
  const ProgressionNode({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.rewards,
    this.unlockConditions = const [],
    this.claimPolicy = ClaimPolicy.automatic,
    this.activationPolicy = ActivationPolicy.always,
    this.contentTags = const [],
    this.rarity = Rarity.common,
    this.lockedHintKey,
    this.assetKey,
    this.sortOrder = 0,
  });

  final String id;
  final LocalizedText titleKey;
  final LocalizedText descriptionKey;
  final List<RewardDefinition> rewards;
  final List<UnlockCondition> unlockConditions;
  final ClaimPolicy claimPolicy;
  final ActivationPolicy activationPolicy;
  final List<ContentTag> contentTags;

  /// Single grading axis (Q5 decision: drop `Difficulty`, keep
  /// `Rarity`). Drives celebration accent and visual density.
  final Rarity rarity;

  final LocalizedText? lockedHintKey;
  final String? assetKey;
  final int sortOrder;
}

// ── Concrete node types ─────────────────────────────────────────────

class QuestNode extends ProgressionNode {
  const QuestNode({
    required super.id,
    required super.titleKey,
    required super.descriptionKey,
    required super.rewards,
    required this.objectiveId,
    required this.displayBucket,
    this.chainId,
    this.chainOrder,
    this.chapterId,
    this.displayGroupId,
    this.comboPoolId,
    this.dailyTierGroupId,
    this.dailyTier,
    this.progressStartPolicy = ProgressStartPolicy.lifetime,
    super.unlockConditions,
    super.claimPolicy,
    super.activationPolicy,
    super.contentTags,
    super.rarity,
    super.lockedHintKey,
    super.assetKey,
    super.sortOrder,
  });

  final String objectiveId;
  final QuestDisplayBucket displayBucket;
  final String? chainId;
  final int? chainOrder;
  final String? chapterId;
  final String? displayGroupId;
  final String? comboPoolId;
  final String? dailyTierGroupId;
  final int? dailyTier;
  final ProgressStartPolicy progressStartPolicy;
}

class AchievementNode extends ProgressionNode {
  const AchievementNode({
    required super.id,
    required super.titleKey,
    required super.descriptionKey,
    required super.rewards,
    required this.objectiveId,
    this.badgeEmoji = '\u{1F3C5}',
    super.unlockConditions,
    super.activationPolicy,
    super.contentTags,
    super.rarity,
    super.assetKey,
    super.sortOrder,
  }) : super(claimPolicy: ClaimPolicy.automatic);

  final String objectiveId;
  final String badgeEmoji;
}

class MilestoneNode extends ProgressionNode {
  const MilestoneNode({
    required super.id,
    required super.titleKey,
    required super.descriptionKey,
    required super.rewards,
    required this.objectiveId,
    this.journeyMapAnchor = false,
    super.unlockConditions,
    super.activationPolicy,
    super.contentTags,
    super.rarity,
    super.assetKey,
    super.sortOrder,
  }) : super(claimPolicy: ClaimPolicy.automatic);

  final String objectiveId;
  final bool journeyMapAnchor;
}

class LevelMilestoneNode extends ProgressionNode {
  const LevelMilestoneNode({
    required super.id,
    required super.titleKey,
    required super.descriptionKey,
    required super.rewards,
    required this.level,
    required this.emoji,
    super.unlockConditions = const [],
    this.isTitleBreakpoint = false,
    this.isJourneyMapAnchor = true,
    super.contentTags,
    super.rarity,
  }) : super(claimPolicy: ClaimPolicy.automatic);

  final int level;
  final String emoji;
  final bool isTitleBreakpoint;
  final bool isJourneyMapAnchor;
}

class ChapterCompletionNode extends ProgressionNode {
  const ChapterCompletionNode({
    required super.id,
    required super.titleKey,
    required super.descriptionKey,
    required super.rewards,
    required this.chapterId,
    required super.unlockConditions,
    super.activationPolicy,
    super.contentTags,
    super.rarity,
  }) : super(claimPolicy: ClaimPolicy.automatic);

  final String chapterId;
}

class CompanionAvailabilityNode extends ProgressionNode {
  const CompanionAvailabilityNode({
    required super.id,
    required super.titleKey,
    required super.descriptionKey,
    required super.rewards,
    required this.companionId,
    required super.unlockConditions,
    super.contentTags = const [ContentTag.rpg, ContentTag.companions],
    super.rarity,
    super.lockedHintKey,
  }) : super(claimPolicy: ClaimPolicy.manual);

  final String companionId;
}

class RelicNode extends ProgressionNode {
  const RelicNode({
    required super.id,
    required super.titleKey,
    required super.descriptionKey,
    required super.rewards,
    required this.relicId,
    required super.unlockConditions,
    super.contentTags = const [ContentTag.rpg, ContentTag.relics],
    super.rarity,
  }) : super(claimPolicy: ClaimPolicy.automatic);

  final String relicId;
}

class ContentUnlockNode extends ProgressionNode {
  const ContentUnlockNode({
    required super.id,
    required super.titleKey,
    required super.descriptionKey,
    required super.rewards,
    required super.unlockConditions,
    super.contentTags,
    super.rarity,
  }) : super(claimPolicy: ClaimPolicy.automatic);
}
