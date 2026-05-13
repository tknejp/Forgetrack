// `type_init_formals` fires on every `required String super.chapterId`
// in the subtypes below. The annotation is deliberate — it narrows
// the base's nullable `chapterId` / `chainId` / `comboPoolId` fields
// to non-null at the subtype's constructor surface (ChapterStepNode
// can't exist without a chapterId, ComboStepNode can't exist without
// a comboPoolId). Dropping the type would re-introduce nullability
// and silently break catalog authoring.
// ignore_for_file: type_init_formals

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show IconData;

import '../../../../shared/domain/rarity.dart';
import '../localized_text.dart';
import 'activation_policy.dart';
import 'claim_policy.dart';
import 'content_tag.dart';
import 'progress_start_policy.dart';
import 'quest_display_bucket.dart';
import 'quest_policies.dart';
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

/// Sealed base for every "quest" — the progress + claim primitive
/// the player sees on screen.
///
/// Phase 1 of the subtype refactor: concrete subtypes carry an
/// implicit `displayBucket` and tighten the constructor surface for
/// catalog authors. Behavioural policies (slot persistence, gate
/// cooldown, celebration variant) currently live in providers and
/// the adapter as ad-hoc checks; Phase 2 moves them onto these
/// subtypes as declarative fields so the rules live exactly once.
///
/// The base constructor stays wide enough for the existing catalog
/// content to migrate mechanically — only the class name changes
/// per node. Subtypes that don't use a given field (e.g. a
/// standalone daily quest has no `chainId`) simply omit it.
sealed class QuestNode extends ProgressionNode {
  const QuestNode({
    required super.id,
    required super.titleKey,
    required super.descriptionKey,
    required super.rewards,
    required this.objectiveId,
    required this.displayBucket,
    required this.slotPolicy,
    required this.gatePolicy,
    required this.celebrationPolicy,
    this.chainId,
    this.chainOrder,
    this.chapterId,
    this.displayGroupId,
    this.comboPoolId,
    this.dailyTierGroupId,
    this.dailyTier,
    this.progressStartPolicy = ProgressStartPolicy.lifetime,
    this.prerequisiteNodeIds = const [],
    this.nextNodeIds = const [],
    this.chainStepLabelKey,
    this.chainStepIcon,
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

  /// How this quest shows up in the daily / weekly / chapter
  /// section pickers. Each subtype hardcodes a default that matches
  /// its display bucket; catalog authors don't override.
  final SlotPolicy slotPolicy;

  /// Time-based gate on top of [prerequisiteNodeIds]. When set to
  /// [CooldownDays] the engine derives a `NodeCompletedBeforeToday`
  /// for every prereq automatically, so combo / side-quest catalog
  /// content doesn't have to spell those conditions out.
  final GatePolicy gatePolicy;

  /// How the celebration overlay should react when this quest's
  /// objective completes. Read by the celebration adapter to skip
  /// type-based branching.
  final CelebrationPolicy celebrationPolicy;

  final String? chainId;
  final int? chainOrder;
  final String? chapterId;
  final String? displayGroupId;
  final String? comboPoolId;
  final String? dailyTierGroupId;
  final int? dailyTier;
  final ProgressStartPolicy progressStartPolicy;

  /// Quest ids whose completion gates this quest. The engine
  /// auto-extends [unlockConditions] with one [NodeCompleted] per id —
  /// authors keep the list ergonomic without learning the
  /// UnlockCondition vocabulary.
  final List<String> prerequisiteNodeIds;

  /// Quest ids that follow this one in the same chain. UI-only — the
  /// chain preview walks `nextNodeIds` to render the "open → step →
  /// step → finale" row beneath the active card.
  final List<String> nextNodeIds;

  /// Optional one-character / short chain step label. Mirrors V1's
  /// `chainStepLabel` used by the chain preview row ("1", "2", "🛡").
  final LocalizedText? chainStepLabelKey;

  /// Optional Material icon for the chain preview dot. When set, the
  /// chapter card chain row renders this glyph instead of the
  /// [chainStepLabelKey] text — used for "open" (play arrow) and
  /// "finale" (shield) markers where a word would be noisier than an
  /// icon.
  final IconData? chainStepIcon;
}

// ── Quest subtypes ──────────────────────────────────────────────────
//
// Each subtype:
// * Locks `displayBucket` to one value so authors stop having to
//   spell it, and so `switch (node)` on the catalog is exhaustive
//   instead of branching on a stringly-typed enum.
// * Restricts the constructor to the fields that actually make
//   sense for that flavour (e.g. a standalone daily quest can't
//   carry a `chainId` — the constructor doesn't expose it).
// * Acts as the type identity that Phase 2 will hang slot /
//   celebration / cooldown policies on, eliminating the ad-hoc
//   `displayBucket == ...` / `chainOrder == 0` / `nextNodeIds.isEmpty`
//   checks scattered across the provider, adapter, and resolver.

/// Standalone daily quest — e.g. `daily_steps_today`. Lives in the
/// daily section with the rotation-sticky-until-midnight slot rule.
class DailyQuestNode extends QuestNode {
  const DailyQuestNode({
    required super.id,
    required super.titleKey,
    required super.descriptionKey,
    required super.rewards,
    required super.objectiveId,
    super.progressStartPolicy,
    super.unlockConditions,
    super.claimPolicy,
    super.activationPolicy,
    super.contentTags,
    super.rarity,
    super.lockedHintKey,
    super.assetKey,
    super.sortOrder,
    super.dailyTierGroupId,
    super.dailyTier,
  }) : super(
          displayBucket: QuestDisplayBucket.daily,
          slotPolicy: const HashRotationStickyUntilMidnight(),
          gatePolicy: const NoCooldown(),
          celebrationPolicy: const SilentCelebration(),
        );
}

/// Weekly quest — currently only `weekly_activity`. Stays visible in
/// the weekly section until claimed / week rolls over.
class WeeklyQuestNode extends QuestNode {
  const WeeklyQuestNode({
    required super.id,
    required super.titleKey,
    required super.descriptionKey,
    required super.rewards,
    required super.objectiveId,
    super.unlockConditions,
    super.claimPolicy,
    super.activationPolicy,
    super.contentTags,
    super.rarity,
    super.lockedHintKey,
    super.assetKey,
    super.sortOrder,
  }) : super(
          displayBucket: QuestDisplayBucket.weekly,
          slotPolicy: const Persistent(),
          gatePolicy: const NoCooldown(),
          celebrationPolicy: const SilentCelebration(),
        );
}

/// Chapter chain *opener* — `chainOrder=0`, auto-claim when the level
/// gate clears. Fires the "Nová kapitola otevřena" fullscreen
/// celebration.
class ChapterOpenerNode extends QuestNode {
  const ChapterOpenerNode({
    required super.id,
    required super.titleKey,
    required super.descriptionKey,
    required super.rewards,
    required super.objectiveId,
    required String super.chapterId,
    required String super.chainId,
    required List<String> super.nextNodeIds,
    super.prerequisiteNodeIds,
    super.unlockConditions,
    super.activationPolicy,
    super.contentTags,
    super.rarity,
    super.lockedHintKey,
    super.assetKey,
    super.sortOrder,
    super.chainStepIcon,
    super.displayGroupId,
  }) : super(
          displayBucket: QuestDisplayBucket.chapter,
          chainOrder: 0,
          claimPolicy: ClaimPolicy.automatic,
          slotPolicy: const ChapterCardSticky(),
          gatePolicy: const NoCooldown(),
          celebrationPolicy: const ChapterOpenedCelebration(),
        );
}

/// Mid-chain chapter step. Manual claim — `nextNodeIds` is non-empty
/// so the chain has at least one step after it. Silent on claim
/// (Phase 2 will say so via [CelebrationPolicy]); the player sees
/// the XP pill flip state on the chapter card.
class ChapterStepNode extends QuestNode {
  const ChapterStepNode({
    required super.id,
    required super.titleKey,
    required super.descriptionKey,
    required super.rewards,
    required super.objectiveId,
    required String super.chapterId,
    required String super.chainId,
    required int super.chainOrder,
    required List<String> super.nextNodeIds,
    super.prerequisiteNodeIds,
    super.unlockConditions,
    super.activationPolicy,
    super.contentTags,
    super.rarity,
    super.lockedHintKey,
    super.assetKey,
    super.sortOrder,
    super.chainStepLabelKey,
    super.chainStepIcon,
    super.displayGroupId,
  }) : super(
          displayBucket: QuestDisplayBucket.chapter,
          claimPolicy: ClaimPolicy.manual,
          slotPolicy: const ChapterCardSticky(),
          gatePolicy: const NoCooldown(),
          celebrationPolicy: const SilentCelebration(),
        );
}

/// Final step of a chapter chain. `nextNodeIds` is empty by
/// definition. Fires the "Kapitola dokončena" fullscreen
/// celebration with the chapter icon as headliner.
class ChapterFinaleNode extends QuestNode {
  const ChapterFinaleNode({
    required super.id,
    required super.titleKey,
    required super.descriptionKey,
    required super.rewards,
    required super.objectiveId,
    required String super.chapterId,
    required String super.chainId,
    required int super.chainOrder,
    super.prerequisiteNodeIds,
    super.unlockConditions,
    super.activationPolicy,
    super.contentTags,
    super.rarity,
    super.lockedHintKey,
    super.assetKey,
    super.sortOrder,
    super.chainStepLabelKey,
    super.chainStepIcon,
    super.displayGroupId,
  }) : super(
          displayBucket: QuestDisplayBucket.chapter,
          claimPolicy: ClaimPolicy.manual,
          nextNodeIds: const [],
          slotPolicy: const ChapterCardSticky(),
          gatePolicy: const NoCooldown(),
          celebrationPolicy: const ChapterCompletedCelebration(),
        );
}

/// Narrative bonus quest tied to an active chapter. Surfaces only
/// while `ChapterActive(chapterId)` is true; the daily section's
/// surprise slot picks one at a time. Once-and-done (`LifetimeScope`
/// objective). Carries a cooldown so it doesn't unlock the same day
/// its gating chapter step was completed (Phase 2 will encode this
/// as `CooldownDays(1)` instead of explicit unlock conditions).
class ChapterSideQuestNode extends QuestNode {
  const ChapterSideQuestNode({
    required super.id,
    required super.titleKey,
    required super.descriptionKey,
    required super.rewards,
    required super.objectiveId,
    required String super.chapterId,
    super.chainId,
    super.chainOrder,
    super.nextNodeIds,
    super.prerequisiteNodeIds,
    super.unlockConditions,
    super.claimPolicy,
    super.activationPolicy,
    super.contentTags,
    super.rarity,
    super.lockedHintKey,
    super.assetKey,
    super.sortOrder,
    super.chainStepLabelKey,
  }) : super(
          displayBucket: QuestDisplayBucket.chapterSideQuest,
          slotPolicy: const PinClaimedTodayUntilMidnight(),
          gatePolicy: const CooldownDays(1),
          celebrationPolicy: const SilentCelebration(),
        );
}

/// Step in a daily combo chain. Manual claim, gated by
/// `NodeCompletedBeforeToday(prev)` so only one chain step lands
/// per day. `comboPoolId` ties the step to a shared completion
/// pool that combo achievements ride on.
class ComboStepNode extends QuestNode {
  const ComboStepNode({
    required super.id,
    required super.titleKey,
    required super.descriptionKey,
    required super.rewards,
    required super.objectiveId,
    required String super.chainId,
    required int super.chainOrder,
    required String super.comboPoolId,
    required List<String> super.nextNodeIds,
    super.prerequisiteNodeIds,
    super.unlockConditions,
    super.activationPolicy,
    super.contentTags,
    super.rarity,
    super.lockedHintKey,
    super.assetKey,
    super.sortOrder,
    super.chainStepLabelKey,
  }) : super(
          displayBucket: QuestDisplayBucket.combo,
          claimPolicy: ClaimPolicy.manual,
          slotPolicy: const ChainPlaceholderUntilMidnight(),
          gatePolicy: const CooldownDays(1),
          celebrationPolicy: const SilentCelebration(),
        );
}

/// Final step of a daily combo chain. Same gating rules as
/// [ComboStepNode] but `nextNodeIds` is empty. Phase 2 will give
/// this a louder celebration than mid-chain steps.
class ComboFinaleNode extends QuestNode {
  const ComboFinaleNode({
    required super.id,
    required super.titleKey,
    required super.descriptionKey,
    required super.rewards,
    required super.objectiveId,
    required String super.chainId,
    required int super.chainOrder,
    required String super.comboPoolId,
    super.prerequisiteNodeIds,
    super.unlockConditions,
    super.activationPolicy,
    super.contentTags,
    super.rarity,
    super.lockedHintKey,
    super.assetKey,
    super.sortOrder,
    super.chainStepLabelKey,
    super.chainStepIcon,
  }) : super(
          displayBucket: QuestDisplayBucket.combo,
          claimPolicy: ClaimPolicy.manual,
          nextNodeIds: const [],
          slotPolicy: const ChainPlaceholderUntilMidnight(),
          gatePolicy: const CooldownDays(1),
          celebrationPolicy: const SilentCelebration(),
        );
}

/// Daily challenge template — `LifetimeScope` objective; today's pick
/// surfaces via deterministic hash and retires once claimed.
class DailyChallengeNode extends QuestNode {
  const DailyChallengeNode({
    required super.id,
    required super.titleKey,
    required super.descriptionKey,
    required super.rewards,
    required super.objectiveId,
    required String super.comboPoolId,
    super.unlockConditions,
    super.claimPolicy,
    super.activationPolicy,
    super.contentTags,
    super.rarity,
    super.lockedHintKey,
    super.assetKey,
    super.sortOrder,
  }) : super(
          displayBucket: QuestDisplayBucket.dailyChallenge,
          slotPolicy: const DailyChallengeHashPick(),
          gatePolicy: const NoCooldown(),
          celebrationPolicy: const SilentCelebration(),
        );
}

/// Long-term lifetime objective (mastery chain). Persistent — stays
/// visible until claimed, no per-day rotation. Chain progression
/// across many sessions.
class LongTermQuestNode extends QuestNode {
  const LongTermQuestNode({
    required super.id,
    required super.titleKey,
    required super.descriptionKey,
    required super.rewards,
    required super.objectiveId,
    super.chainId,
    super.chainOrder,
    super.nextNodeIds,
    super.prerequisiteNodeIds,
    super.unlockConditions,
    super.claimPolicy,
    super.activationPolicy,
    super.contentTags,
    super.rarity,
    super.lockedHintKey,
    super.assetKey,
    super.sortOrder,
    super.chainStepLabelKey,
    super.chainStepIcon,
  }) : super(
          displayBucket: QuestDisplayBucket.longTerm,
          slotPolicy: const Persistent(),
          gatePolicy: const NoCooldown(),
          celebrationPolicy: const SilentCelebration(),
        );
}

class AchievementNode extends ProgressionNode {
  const AchievementNode({
    required super.id,
    required super.titleKey,
    required super.descriptionKey,
    required super.rewards,
    this.objectiveId,
    this.badgeEmoji = '\u{1F3C5}',
    super.unlockConditions,
    super.activationPolicy,
    super.contentTags,
    super.rarity,
    super.assetKey,
    super.sortOrder,
  }) : super(claimPolicy: ClaimPolicy.automatic);

  /// When null, the achievement is condition-driven only (welcome
  /// achievements, level milestones, anything satisfied by unlock
  /// conditions alone). When set, references an [ObjectiveDefinition]
  /// in [ObjectiveCatalog].
  final String? objectiveId;
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
