import 'package:flutter/foundation.dart';

import '../models/engine_evaluation_context.dart';
import 'package:forgetrack/domain/journal/journal_event.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'package:forgetrack/domain/progression/catalog/reward_definition.dart';
import '../repository/ledger_snapshot.dart';
import 'progression_node_resolver.dart';

/// One planned reward grant. Either becomes a [RewardGrantEvent]
/// appended to the ledger, or a `SkippedEvent` if the engine sees
/// the same key already exists (idempotent re-runs).
@immutable
class PlannedRewardGrant {
  const PlannedRewardGrant({
    required this.eventKey,
    required this.node,
    required this.rewardOrdinal,
    required this.reward,
    required this.periodKey,
  });

  final String eventKey;
  final ProgressionEntry node;
  final int rewardOrdinal;
  final RewardDefinition reward;
  final String? periodKey;
}

/// Pure planner. Given a list of nodes that just completed (or were
/// just claimed for manual-claim nodes) plus the current ledger,
/// returns the list of reward grants the engine should attempt to
/// append.
///
/// The planner does not touch the ledger and does not scale XP â€” XP
/// scaling happens in the [RewardGrantService] at append time using
/// the running level. The planner only builds keys + payloads.
class RewardGrantPlanner {
  const RewardGrantPlanner();

  List<PlannedRewardGrant> plan({
    required Iterable<ProgressionEntry> completedNodes,
    required LedgerSnapshot ledger,
    required Map<String, String?> periodKeyByNodeId,
    required EngineEvaluationContext context,
  }) {
    final out = <PlannedRewardGrant>[];
    for (final node in completedNodes) {
      final periodKey = periodKeyByNodeId[node.id];
      for (var i = 0; i < node.rewards.length; i++) {
        final reward = node.rewards[i];
        // Conditional bonus rewards drop out silently when their
        // condition fails â€” the player claimed too late, slept too
        // little, etc. No ledger event is emitted; the bonus just
        // doesn't happen this time. The next claim re-evaluates.
        if (reward is BonusXpReward &&
            !_bonusConditionMet(reward.condition, context)) {
          continue;
        }
        final eventKey = ProgressionNodeResolver.rewardEventKey(
          nodeId: node.id,
          rewardOrdinal: i,
          periodKey: periodKey,
        );
        if (ledger.hasEventKey(eventKey)) continue;
        out.add(PlannedRewardGrant(
          eventKey: eventKey,
          node: node,
          rewardOrdinal: i,
          reward: reward,
          periodKey: periodKey,
        ));
      }
    }
    return out;
  }

  bool _bonusConditionMet(
    BonusXpCondition condition,
    EngineEvaluationContext context,
  ) {
    return switch (condition) {
      CompletedBeforeHour(:final hour) =>
        context.evaluatedAt.toLocal().hour < hour,
      SleepAtLeast(:final minutes) =>
        context.healthSnapshot.sleepMinutesToday >= minutes,
    };
  }
}
