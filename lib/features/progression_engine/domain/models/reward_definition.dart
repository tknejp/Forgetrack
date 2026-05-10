import 'content_tag.dart';

/// One concrete reward attached to a [ProgressionNode]. Sealed so the
/// dispatcher and celebration mapper get exhaustive switch checking
/// — adding a new reward type cannot silently slip past the consumer
/// list.
///
/// Q4 / Q5 decisions: there is no `Difficulty` reward — the
/// `difficultyScore` field is dropped. Rarity is the single grading
/// axis, carried on the node itself, not on individual rewards.
sealed class RewardDefinition {
  const RewardDefinition({this.contentTags = const []});

  final List<ContentTag> contentTags;
}

/// XP reward — the only reward that flows through the level / scaling
/// policy. Amount is the *base* XP; the engine scales at claim time
/// using the running level and the multiplier table.
class XpReward extends RewardDefinition {
  const XpReward({required this.amount, super.contentTags});
  final int amount;
}

/// Cosmetic unlock — frame, background, emblem, title flair, map
/// effect, etc. The cosmetics feature owns the actual unlock; the
/// engine just hands the id to the dispatcher.
class CosmeticReward extends RewardDefinition {
  const CosmeticReward({required this.cosmeticId, super.contentTags});
  final String cosmeticId;
}

/// Unlocks a chapter so its quests / nodes become available.
class ChapterUnlockReward extends RewardDefinition {
  const ChapterUnlockReward({required this.chapterId, super.contentTags});
  final String chapterId;
}

/// Marks a companion as **available**. The actual equip step is a
/// separate manual claim on a [CompanionAvailabilityNode] — Q3
/// decision: companions are never auto-equipped.
class CompanionAvailabilityReward extends RewardDefinition {
  const CompanionAvailabilityReward({
    required this.companionId,
    super.contentTags,
  });
  final String companionId;
}

/// Player-facing title (e.g. "Pathfinder", "Iron Warden"). Currently
/// shown on the hero card and journey screen.
class TitleReward extends RewardDefinition {
  const TitleReward({required this.titleId, super.contentTags});
  final String titleId;
}

/// Emblem / badge reward — small icon shown on profile / feed.
class EmblemReward extends RewardDefinition {
  const EmblemReward({required this.emblemId, super.contentTags});
  final String emblemId;
}

/// Relic reward — auto-unlocked passive RPG item (Q3 decision: relics
/// are 2-state, no manual claim).
class RelicReward extends RewardDefinition {
  const RelicReward({required this.relicId, super.contentTags});
  final String relicId;
}
