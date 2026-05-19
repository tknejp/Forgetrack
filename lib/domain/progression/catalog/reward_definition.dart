import 'bonus_xp_condition.dart';
import 'content_tag.dart';
import 'ids.dart';

export 'bonus_xp_condition.dart';

/// One concrete reward attached to a [ProgressionEntry]. Sealed so the
/// dispatcher and celebration mapper get exhaustive switch checking
/// — adding a new reward type cannot silently slip past the consumer
/// list.
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

/// Conditional XP bonus — only fires when the attached
/// [BonusXpCondition] evaluates to true at claim time. Scales
/// through the same level / multiplier table as [XpReward], so a
/// "+80 XP bonus before 18:00" on top of a base 80 XP reward gives
/// the player a clean 2× reward when claimed early.
///
/// The planner filters bonus grants whose condition fails; failed
/// bonuses leave no trace in the ledger (no "unclaimed bonus"
/// event), they simply never happen.
class BonusXpReward extends RewardDefinition {
  const BonusXpReward({
    required this.amount,
    required this.condition,
    super.contentTags,
  });

  final int amount;
  final BonusXpCondition condition;
}

/// Cosmetic unlock — frame, background, emblem, title flair, map
/// effect, etc. The cosmetics feature owns the actual unlock; the
/// engine just hands the id to the dispatcher.
class CosmeticReward extends RewardDefinition {
  const CosmeticReward({required this.cosmeticId, super.contentTags});
  final CosmeticId cosmeticId;
}

/// Unlocks a chapter so its quests / nodes become available.
class ChapterUnlockReward extends RewardDefinition {
  const ChapterUnlockReward({required this.chapterId, super.contentTags});
  final ChapterId chapterId;
}

/// Marks a companion as **available**. The actual equip step is a
/// separate manual claim on a [CompanionAvailability] — Q3
/// decision: companions are never auto-equipped.
class CompanionAvailabilityReward extends RewardDefinition {
  const CompanionAvailabilityReward({
    required this.companionId,
    super.contentTags,
  });
  final CosmeticId companionId;
}

/// Player-facing title (e.g. "Pathfinder", "Iron Warden"). Currently
/// shown on the hero card and journey screen.
class TitleReward extends RewardDefinition {
  const TitleReward({required this.titleId, super.contentTags});
  final TitleId titleId;
}

/// Emblem / badge reward — small icon shown on profile / feed.
class EmblemReward extends RewardDefinition {
  const EmblemReward({required this.emblemId, super.contentTags});
  final EmblemId emblemId;
}

/// Relic reward — auto-unlocked passive RPG item (Q3 decision: relics
/// are 2-state, no manual claim).
class RelicReward extends RewardDefinition {
  const RelicReward({required this.relicId, super.contentTags});
  final CosmeticId relicId;
}
