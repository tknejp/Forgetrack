import '../domain/evaluator/reward_grant_planner.dart';
import '../domain/models/ledger_event.dart';
import '../domain/models/reward_definition.dart';
import '../../progression/domain/policy/level_policy.dart';

/// Builds [RewardGrantEvent]s from planned grants. XP rewards are
/// scaled at append time using the running level — the same logic
/// the legacy engine applies, lifted here so V2 stays compatible
/// with the existing level / multiplier curve.
///
/// During Phase 2 the legacy [ProgressionLevelPolicy] is reused as
/// the source of truth for the XP↔level table; replacing it is a
/// Phase 3+ task if the curve ever changes.
class RewardGrantService {
  const RewardGrantService({
    this.levelPolicy = const ProgressionLevelPolicy(),
  });

  final ProgressionLevelPolicy levelPolicy;

  /// Builds reward events for one planning batch. The caller passes
  /// `runningClaimedXp` so XP scaling reflects already-claimed XP
  /// from earlier nodes in the same run (and from prior runs).
  ///
  /// Returns the events plus the new running-XP total.
  ({List<RewardGrantEvent> events, int runningClaimedXp}) build({
    required List<PlannedRewardGrant> planned,
    required int runningClaimedXp,
    required DateTime timestamp,
  }) {
    final events = <RewardGrantEvent>[];
    var running = runningClaimedXp;

    for (final p in planned) {
      events.add(_buildOne(p, runningXp: running, timestamp: timestamp));
      if (p.reward is XpReward) {
        final base = (p.reward as XpReward).amount;
        final level = levelPolicy.levelForXp(running);
        final scaled = levelPolicy.scaledRewardXp(baseXp: base, level: level);
        running += scaled;
      }
    }

    return (events: events, runningClaimedXp: running);
  }

  RewardGrantEvent _buildOne(
    PlannedRewardGrant planned, {
    required int runningXp,
    required DateTime timestamp,
  }) {
    final reward = planned.reward;
    return switch (reward) {
      XpReward(:final amount) => () {
          final level = levelPolicy.levelForXp(runningXp);
          final scaled =
              levelPolicy.scaledRewardXp(baseXp: amount, level: level);
          final multiplier = levelPolicy.rewardMultiplierForLevel(level);
          return RewardGrantEvent(
            eventKey: planned.eventKey,
            timestamp: timestamp,
            nodeId: planned.node.id,
            rewardOrdinal: planned.rewardOrdinal,
            rewardKind: RewardGrantKind.xp,
            periodKey: planned.periodKey,
            xpAmount: scaled,
            levelAtGrant: level,
            multiplierAtGrant: multiplier,
          );
        }(),
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
}
