import 'package:forgetrack/domain/journal/journal_event.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'package:forgetrack/domain/progression/catalog/quest_display_bucket.dart';
import 'package:forgetrack/domain/progression/catalog/reward_definition.dart';

import '../../../core/logging/app_log.dart';
import '../../cosmetics/domain/companion_buff.dart';
import '../../cosmetics/domain/emblem_buff.dart';
import '../domain/evaluator/reward_grant_planner.dart';
import '../domain/models/engine_evaluation_context.dart';
import '../domain/policy/level_policy.dart';
import 'emblem_target_mapping.dart';

const _log = AppLogger('PROGRESSION', scope: 'claim.buff');

/// Builds [RewardGrantEvent]s from planned grants. XP rewards are
/// scaled at append time using the running level — the same logic
/// the legacy engine applies, lifted here so V2 stays compatible
/// with the existing level / multiplier curve.
///
/// Companion + emblem buffs stack **additively** (per the locked
/// design in `docs/emblem_buffs/plan.md`): the final XP is
/// `scaled × (1 + (companion% + emblem%) / 100)`. There is no daily
/// share cap — the level curve compensates for top-end buff stacks.
class RewardGrantService {
  const RewardGrantService({
    this.levelPolicy = const ProgressionLevelPolicy(),
  });

  final ProgressionLevelPolicy levelPolicy;

  /// Builds reward events for one planning batch. The caller passes
  /// `runningClaimedXp` so XP scaling reflects already-claimed XP
  /// from earlier nodes in the same run (and from prior runs).
  ///
  /// [context] supplies the equipped companion buff + emblem buffs +
  /// streak inputs. May be null when called from a code path that
  /// does not have a context yet — buffs are simply skipped in that
  /// case.
  ///
  /// Returns the events plus the new running-XP total.
  ({List<RewardGrantEvent> events, int runningClaimedXp}) build({
    required List<PlannedRewardGrant> planned,
    required int runningClaimedXp,
    required DateTime timestamp,
    EngineEvaluationContext? context,
  }) {
    final events = <RewardGrantEvent>[];
    var running = runningClaimedXp;

    for (final p in planned) {
      final event = _buildOne(
        p,
        runningXp: running,
        timestamp: timestamp,
        context: context,
      );
      events.add(event);
      final eventXp = event.xpAmount ?? 0;
      if (eventXp > 0) {
        running += eventXp;
      }
    }

    return (events: events, runningClaimedXp: running);
  }

  RewardGrantEvent _buildOne(
    PlannedRewardGrant planned, {
    required int runningXp,
    required DateTime timestamp,
    required EngineEvaluationContext? context,
  }) {
    final reward = planned.reward;
    return switch (reward) {
      XpReward(:final amount, :final sourceKind, :final streakDomain) =>
        _buildXpEvent(
          planned: planned,
          runningXp: runningXp,
          timestamp: timestamp,
          baseAmount: amount,
          sourceKind: sourceKind,
          streakDomain: streakDomain,
          context: context,
        ),
      BonusXpReward(:final amount, :final sourceKind, :final streakDomain) =>
        _buildXpEvent(
          planned: planned,
          runningXp: runningXp,
          timestamp: timestamp,
          baseAmount: amount,
          sourceKind: sourceKind,
          streakDomain: streakDomain,
          context: context,
        ),
      CosmeticReward(:final cosmeticId) => RewardGrantEvent(
          eventKey: planned.eventKey,
          timestamp: timestamp,
          nodeId: planned.node.id,
          rewardOrdinal: planned.rewardOrdinal,
          rewardKind: RewardGrantKind.cosmetic,
          periodKey: planned.periodKey,
          cosmeticId: cosmeticId,
        ),
      ChapterUnlockReward(:final chapterId) => RewardGrantEvent(
          eventKey: planned.eventKey,
          timestamp: timestamp,
          nodeId: planned.node.id,
          rewardOrdinal: planned.rewardOrdinal,
          rewardKind: RewardGrantKind.chapterUnlock,
          periodKey: planned.periodKey,
          chapterId: chapterId,
        ),
      CompanionAvailabilityReward(:final companionId) => RewardGrantEvent(
          eventKey: planned.eventKey,
          timestamp: timestamp,
          nodeId: planned.node.id,
          rewardOrdinal: planned.rewardOrdinal,
          rewardKind: RewardGrantKind.companionAvailability,
          periodKey: planned.periodKey,
          companionId: companionId,
        ),
      TitleReward(:final titleId) => RewardGrantEvent(
          eventKey: planned.eventKey,
          timestamp: timestamp,
          nodeId: planned.node.id,
          rewardOrdinal: planned.rewardOrdinal,
          rewardKind: RewardGrantKind.title,
          periodKey: planned.periodKey,
          titleId: titleId,
        ),
      EmblemReward(:final emblemId) => RewardGrantEvent(
          eventKey: planned.eventKey,
          timestamp: timestamp,
          nodeId: planned.node.id,
          rewardOrdinal: planned.rewardOrdinal,
          rewardKind: RewardGrantKind.emblem,
          periodKey: planned.periodKey,
          emblemId: emblemId,
        ),
      RelicReward(:final relicId) => RewardGrantEvent(
          eventKey: planned.eventKey,
          timestamp: timestamp,
          nodeId: planned.node.id,
          rewardOrdinal: planned.rewardOrdinal,
          rewardKind: RewardGrantKind.relic,
          periodKey: planned.periodKey,
          relicId: relicId,
        ),
    };
  }

  RewardGrantEvent _buildXpEvent({
    required PlannedRewardGrant planned,
    required int runningXp,
    required DateTime timestamp,
    required int baseAmount,
    required RewardSourceKind? sourceKind,
    required ProgressionDomain? streakDomain,
    required EngineEvaluationContext? context,
  }) {
    final level = levelPolicy.levelForXp(runningXp);
    final scaled = levelPolicy.scaledRewardXp(baseXp: baseAmount, level: level);
    final multiplier = levelPolicy.rewardMultiplierForLevel(level);

    final companionPct = _resolveCompanionPercent(
      sourceKind: sourceKind,
      streakDomain: streakDomain,
      node: planned.node,
      context: context,
    );
    final emblemPct = _resolveEmblemPercent(
      node: planned.node,
      sourceKind: sourceKind,
      context: context,
    );

    final totalPct = companionPct + emblemPct;
    final bonus = totalPct > 0 ? (scaled * totalPct / 100).round() : 0;

    int companionBonusXp = 0;
    int emblemBonusXp = 0;
    if (bonus > 0 && totalPct > 0) {
      companionBonusXp = (bonus * companionPct / totalPct).round();
      emblemBonusXp = bonus - companionBonusXp;
    }

    if (bonus > 0) {
      _log.debug(
        'claim buff applied',
        payload:
            'node=${planned.node.id} kind=${sourceKind?.name} '
            'compPct=$companionPct embPct=$emblemPct '
            'compBonus=$companionBonusXp embBonus=$emblemBonusXp '
            'finalXp=${scaled + bonus}',
      );
    }

    return RewardGrantEvent(
      eventKey: planned.eventKey,
      timestamp: timestamp,
      nodeId: planned.node.id,
      rewardOrdinal: planned.rewardOrdinal,
      rewardKind: RewardGrantKind.xp,
      periodKey: planned.periodKey,
      xpAmount: scaled + bonus,
      levelAtGrant: level,
      multiplierAtGrant: multiplier,
      companionBuffBonusXp: companionBonusXp > 0 ? companionBonusXp : null,
      emblemBuffBonusXp: emblemBonusXp > 0 ? emblemBonusXp : null,
    );
  }

  /// Percent contribution from the equipped companion buff for the
  /// given reward. Returns 0 when no companion is equipped, RPG mode
  /// is off, the reward has no [sourceKind], or the buff resolves
  /// to 0 against its self-matching gates.
  int _resolveCompanionPercent({
    required RewardSourceKind? sourceKind,
    required ProgressionDomain? streakDomain,
    required ProgressionEntry node,
    required EngineEvaluationContext? context,
  }) {
    if (context == null) return 0;
    if (!context.player.rpgModeEnabled) return 0;
    final buff = context.equippedCompanionBuff;
    if (buff == null) return 0;
    if (sourceKind == null) return 0;

    final isWeekly = node is Quest && node.displayBucket == QuestDisplayBucket.weekly;
    final chainPos = (node is Quest && node.chapterId != null)
        ? node.chainOrder
        : null;
    final domainStreak = streakDomain == null
        ? 0
        : context.currentStreakByDomain[streakDomain] ?? 0;

    final percent = buff.resolvePercent(
      CompanionBuffContext(
        rewardSourceKind: sourceKind,
        streakDomain: streakDomain,
        currentStreak: domainStreak,
        isWeeklyQuestSource: isWeekly,
        chapterChainPosition: chainPos,
      ),
    );
    return percent > 0 ? percent : 0;
  }

  /// Sum of percent contributions from every equipped emblem buff
  /// for the given reward. Returns 0 when RPG mode is off, no emblem
  /// buffs are equipped, the node has no [EmblemTarget] mapping, or
  /// every buff resolves to 0.
  int _resolveEmblemPercent({
    required ProgressionEntry node,
    required RewardSourceKind? sourceKind,
    required EngineEvaluationContext? context,
  }) {
    if (context == null) return 0;
    if (!context.player.rpgModeEnabled) return 0;
    final buffs = context.equippedEmblemBuffs;
    if (buffs.isEmpty) return 0;
    final target = emblemTargetForNode(node);
    if (target == null) return 0;
    if (sourceKind == null) return 0;

    final ctx = EmblemBuffContext(
      target: target,
      rewardSourceKind: sourceKind,
    );
    var total = 0;
    for (final b in buffs) {
      final p = b.resolvePercent(ctx);
      if (p > 0) total += p;
    }
    return total;
  }
}
