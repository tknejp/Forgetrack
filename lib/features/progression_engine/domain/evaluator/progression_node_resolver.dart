import 'package:flutter/foundation.dart';

import 'package:forgetrack/domain/progression/catalog/activation_policy.dart';
import 'package:forgetrack/domain/progression/catalog/claim_policy.dart';
import '../models/engine_evaluation_context.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import '../repository/ledger_snapshot.dart';
import 'objective_evaluator.dart';

/// What the node resolver decides for one node on this evaluation.
///
/// Classification is derived from the booleans, not stored as a
/// separate enum tag (R.2 cleanup, 2026-05-19):
///   * **locked** = `!eligibleByConditions`
///   * **completed** = `eligibleByConditions && completed`
///   * **available** = otherwise (eligible but not yet a completion
///     event candidate — objective in progress, or manual-claim node
///     waiting on the player's tap)
///
/// Consumers pattern-match on the booleans directly. The legacy
/// `NodeState` enum was a resolver-internal remnant of the V2 origin
/// design; player-facing surfaces use per-aggregate sealed lifecycles
/// (`PlayerQuestLifecycle` / `PlayerAchievementLifecycle` /
/// `ChapterLifecycle`) instead.
@immutable
class NodeResolution {
  const NodeResolution({
    required this.node,
    required this.eligibleByConditions,
    required this.objectiveCompleted,
    required this.completed,
    required this.periodKey,
  });

  final ProgressionEntry node;

  /// Were the unlock conditions satisfied? Distinct from completion:
  /// a node may be eligible (conditions met) but not yet completed
  /// (objective not yet satisfied or claim pending).
  final bool eligibleByConditions;

  /// Was the bound objective satisfied? Null for nodes with no
  /// `objectiveId` (chapter completions, content unlocks).
  final bool? objectiveCompleted;

  /// True iff the resolver classifies this node as a completion event
  /// candidate this run — either already in the ledger (idempotent
  /// re-emit suppressed by the engine's event-key dedup) or
  /// freshly completed (auto-claim objective just satisfied, or
  /// manual-claim already claimed).
  final bool completed;

  /// Period anchor used for ledger key composition. May be null for
  /// lifetime-scoped nodes.
  final String? periodKey;
}

/// Pure resolver. Classifies each node from:
///   - the bound objective's outcome,
///   - unlock conditions,
///   - claim policy,
///   - prior ledger state (already-completed / already-claimed).
///
/// Activation policy gating: when RPG mode is off, nodes with
/// `onlyWhenRpgEnabled*` activation are forced to `locked` regardless
/// of objective outcome.
class ProgressionNodeResolver {
  const ProgressionNodeResolver();

  /// Resolves one node. The caller is responsible for passing the
  /// objective outcome map and the appropriate eligibility sets.
  NodeResolution resolve({
    required ProgressionEntry node,
    required ObjectiveOutcome? objectiveOutcome,
    required bool eligibleByConditions,
    required EngineEvaluationContext context,
    required LedgerSnapshot ledger,
  }) {
    final periodKey = objectiveOutcome?.periodKey;

    // RPG-gated nodes: hidden when RPG off (engine treats as locked
    // and skips evaluation).
    final rpgGated = node.activationPolicy != ActivationPolicy.always;
    if (rpgGated && !context.player.rpgModeEnabled) {
      return NodeResolution(
        node: node,
        eligibleByConditions: false,
        objectiveCompleted: null,
        completed: false,
        periodKey: periodKey,
      );
    }

    if (!eligibleByConditions) {
      return NodeResolution(
        node: node,
        eligibleByConditions: false,
        objectiveCompleted: objectiveOutcome?.completed,
        completed: false,
        periodKey: periodKey,
      );
    }

    // Already in the ledger? Treat as completed regardless of the
    // current objective outcome. This is what makes re-runs
    // idempotent.
    final completionEventKey = _completionEventKey(node.id, periodKey);
    final claimEventKey = _claimEventKey(node.id, periodKey);
    final alreadyCompleted = ledger.hasEventKey(completionEventKey);
    final alreadyClaimed = ledger.hasEventKey(claimEventKey);

    final objectiveCompleted = objectiveOutcome?.completed ?? true;

    if (alreadyCompleted || (node.claimPolicy == ClaimPolicy.manual && alreadyClaimed)) {
      return NodeResolution(
        node: node,
        eligibleByConditions: true,
        objectiveCompleted: objectiveCompleted,
        completed: true,
        periodKey: periodKey,
      );
    }

    if (!objectiveCompleted) {
      // Eligible, objective in progress. UI shows progress; not yet
      // a granting event.
      return NodeResolution(
        node: node,
        eligibleByConditions: true,
        objectiveCompleted: false,
        completed: false,
        periodKey: periodKey,
      );
    }

    // Objective satisfied this run.
    if (node.claimPolicy == ClaimPolicy.manual) {
      // Player must claim before completion lands in the ledger.
      return NodeResolution(
        node: node,
        eligibleByConditions: true,
        objectiveCompleted: true,
        completed: false,
        periodKey: periodKey,
      );
    }
    return NodeResolution(
      node: node,
      eligibleByConditions: true,
      objectiveCompleted: true,
      completed: true,
      periodKey: periodKey,
    );
  }

  // â”€â”€ Event key helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // These are also used by the engine when appending events; kept
  // here so resolver and engine agree on the format.

  static String completionEventKey(String nodeId, String? periodKey) =>
      _completionEventKey(nodeId, periodKey);

  static String claimEventKey(String nodeId, String? periodKey) =>
      _claimEventKey(nodeId, periodKey);

  static String announcementEventKey(String nodeId, String? periodKey) =>
      _announcementEventKey(nodeId, periodKey);

  static String objectiveCompletionEventKey(
    String objectiveId,
    String? periodKey,
  ) =>
      periodKey == null
          ? 'objective|$objectiveId|completed'
          : 'objective|$objectiveId|$periodKey|completed';

  static String rewardEventKey({
    required String nodeId,
    required int rewardOrdinal,
    required String? periodKey,
  }) =>
      periodKey == null
          ? 'reward|$nodeId|$rewardOrdinal|grant'
          : 'reward|$nodeId|$rewardOrdinal|$periodKey|grant';
}

String _completionEventKey(String nodeId, String? periodKey) =>
    periodKey == null
        ? 'node|$nodeId|complete'
        : 'node|$nodeId|$periodKey|complete';

String _claimEventKey(String nodeId, String? periodKey) =>
    periodKey == null
        ? 'node|$nodeId|claim'
        : 'node|$nodeId|$periodKey|claim';

String _announcementEventKey(String nodeId, String? periodKey) =>
    periodKey == null
        ? 'node|$nodeId|announced'
        : 'node|$nodeId|$periodKey|announced';
