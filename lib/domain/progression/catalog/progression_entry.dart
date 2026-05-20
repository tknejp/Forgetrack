// `type_init_formals` fires on every `required ChapterId super.chapterId`
// in the subtypes below. The annotation is deliberate — it narrows
// the base's nullable `chapterId` / `chainId` / `comboPoolId` fields
// to non-null at the subtype's constructor surface (ChapterStep
// can't exist without a chapterId, ComboStep can't exist without
// a comboPoolId). Dropping the type would re-introduce nullability
// and silently break catalog authoring.
// ignore_for_file: type_init_formals

import 'package:meta/meta.dart';

import '../../../shared/domain/rarity.dart';
import 'activation_policy.dart';
import 'claim_policy.dart';
import 'content_tag.dart';
import 'ids.dart';
import 'localized_text.dart';
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
sealed class ProgressionEntry {
  const ProgressionEntry({
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

  final ProgressionEntryId id;
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
sealed class Quest extends ProgressionEntry {
  const Quest({
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

  final ObjectiveId objectiveId;
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

  final ChainId? chainId;
  final int? chainOrder;
  final ChapterId? chapterId;
  final ComboPoolId? comboPoolId;
  final DailyTierGroupId? dailyTierGroupId;
  final int? dailyTier;
  final ProgressStartPolicy progressStartPolicy;

  /// Quest ids whose completion gates this quest. The engine
  /// auto-extends [unlockConditions] with one [NodeCompleted] per id —
  /// authors keep the list ergonomic without learning the
  /// UnlockCondition vocabulary.
  final List<ProgressionEntryId> prerequisiteNodeIds;

  /// Quest ids that follow this one in the same chain. UI-only — the
  /// chain preview walks `nextNodeIds` to render the "open → step →
  /// step → finale" row beneath the active card.
  final List<ProgressionEntryId> nextNodeIds;

  /// Optional one-character / short chain step label. Mirrors V1's
  /// `chainStepLabel` used by the chain preview row ("1", "2", "🛡").
  final LocalizedText? chainStepLabelKey;

  /// Optional named glyph for the chain preview dot. When set, the
  /// chapter card chain row renders the glyph the presentation layer
  /// maps for this enum (Icons.play_arrow_rounded for opener,
  /// Icons.shield_rounded for finale, Icons.flag_rounded for
  /// comboFlag) instead of the [chainStepLabelKey] text — used for
  /// "open" / "finale" markers where a word would be noisier than an
  /// icon.
  final ChainStepIcon? chainStepIcon;
}

// ── Quest subtypes ──────────────────────────────────────────────────

/// A daily goal — one of the main-five per-day targets (steps,
/// nutrition macros, sleep, activity, weight log). Lives in the
/// daily section with the rotation-sticky-until-midnight slot rule.
///
/// Despite extending [Quest] (so the rendering / claim / pill
/// pipeline can treat it uniformly with other daily-section entries
/// like combos and challenges), a `DailyGoal` is **not** a quest in
/// the narrative sense. The distinction matters for streak math:
/// only [DailyGoal] entries carry a [XpReward.streakDomain] and
/// therefore contribute to per-domain streak buffs. Combos / weekly
/// quests / chapter steps / long-term quests / daily challenges
/// never participate in streaks.
class DailyGoal extends Quest {
  const DailyGoal({
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
class WeeklyQuest extends Quest {
  const WeeklyQuest({
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
class ChapterOpener extends Quest {
  const ChapterOpener({
    required super.id,
    required super.titleKey,
    required super.descriptionKey,
    required super.rewards,
    required super.objectiveId,
    required ChapterId super.chapterId,
    required ChainId super.chainId,
    required List<ProgressionEntryId> super.nextNodeIds,
    super.prerequisiteNodeIds,
    super.unlockConditions,
    super.activationPolicy,
    super.contentTags,
    super.rarity,
    super.lockedHintKey,
    super.assetKey,
    super.sortOrder,
    super.chainStepIcon,
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
/// so the chain has at least one step after it.
class ChapterStep extends Quest {
  const ChapterStep({
    required super.id,
    required super.titleKey,
    required super.descriptionKey,
    required super.rewards,
    required super.objectiveId,
    required ChapterId super.chapterId,
    required ChainId super.chainId,
    required int super.chainOrder,
    required List<ProgressionEntryId> super.nextNodeIds,
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
class ChapterFinale extends Quest {
  const ChapterFinale({
    required super.id,
    required super.titleKey,
    required super.descriptionKey,
    required super.rewards,
    required super.objectiveId,
    required ChapterId super.chapterId,
    required ChainId super.chainId,
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
/// its gating chapter step was completed.
class ChapterSideQuest extends Quest {
  const ChapterSideQuest({
    required super.id,
    required super.titleKey,
    required super.descriptionKey,
    required super.rewards,
    required super.objectiveId,
    required ChapterId super.chapterId,
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
class ComboStep extends Quest {
  const ComboStep({
    required super.id,
    required super.titleKey,
    required super.descriptionKey,
    required super.rewards,
    required super.objectiveId,
    required ChainId super.chainId,
    required int super.chainOrder,
    required ComboPoolId super.comboPoolId,
    required List<ProgressionEntryId> super.nextNodeIds,
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
/// [ComboStep] but `nextNodeIds` is empty.
class ComboFinale extends Quest {
  const ComboFinale({
    required super.id,
    required super.titleKey,
    required super.descriptionKey,
    required super.rewards,
    required super.objectiveId,
    required ChainId super.chainId,
    required int super.chainOrder,
    required ComboPoolId super.comboPoolId,
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
class DailyChallenge extends Quest {
  const DailyChallenge({
    required super.id,
    required super.titleKey,
    required super.descriptionKey,
    required super.rewards,
    required super.objectiveId,
    required ComboPoolId super.comboPoolId,
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
class LongTermQuest extends Quest {
  const LongTermQuest({
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

class Achievement extends ProgressionEntry {
  const Achievement({
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
  /// conditions alone). When set, references an [Objective]
  /// in [ObjectiveCatalog].
  final ObjectiveId? objectiveId;
  final String badgeEmoji;
}

class Milestone extends ProgressionEntry {
  const Milestone({
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

  final ObjectiveId objectiveId;
  final bool journeyMapAnchor;
}

class LevelMilestone extends ProgressionEntry {
  const LevelMilestone({
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

class ChapterCompletion extends ProgressionEntry {
  const ChapterCompletion({
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

  final ChapterId chapterId;
}

class CompanionAvailability extends ProgressionEntry {
  const CompanionAvailability({
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

  final CosmeticId companionId;
}

class Relic extends ProgressionEntry {
  const Relic({
    required super.id,
    required super.titleKey,
    required super.descriptionKey,
    required super.rewards,
    required this.relicId,
    required super.unlockConditions,
    super.contentTags = const [ContentTag.rpg, ContentTag.relics],
    super.rarity,
  }) : super(claimPolicy: ClaimPolicy.automatic);

  final CosmeticId relicId;
}

class ContentUnlock extends ProgressionEntry {
  const ContentUnlock({
    required super.id,
    required super.titleKey,
    required super.descriptionKey,
    required super.rewards,
    required super.unlockConditions,
    super.contentTags,
    super.rarity,
  }) : super(claimPolicy: ClaimPolicy.automatic);
}
