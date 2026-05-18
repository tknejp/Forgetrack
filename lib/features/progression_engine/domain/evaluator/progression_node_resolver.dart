import 'package:flutter/foundation.dart';

import '../models/activation_policy.dart';
import '../models/claim_policy.dart';
import '../models/engine_evaluation_context.dart';
import '../models/progression_node_definition.dart';
import '../repository/ledger_snapshot.dart';
import 'objective_evaluator.dart';

/// Internal classification the resolver assigns to a node on a
/// single evaluation pass. Phase 13 inlined this enum (formerly
/// `lib/features/progression_engine/domain/models/node_state.dart`)
/// into the resolver file — every player-facing surface that used to
/// pattern-match on it has migrated to per-aggregate sealed
/// lifecycles (`PlayerQuestLifecycle` / `PlayerAchievementLifecycle`
/// / `ChapterLifecycle`). The enum survives only as resolver-internal
/// state-machine vocabulary; the engine consumer keys off `.name`
/// strings (not the enum type) so the resolver can keep this private
/// without leaking the type across the application boundary.
///
/// Name values (`locked` / `available` / `completed`) are preserved
/// verbatim from the legacy enum because
/// `lib/features/progression_engine/application/progression_engine.dart`
/// switches on `r.state.name == 'completed'` / `'available'`.
/// Renaming would silently break that match.
enum NodeState {
  /// Unlock conditions not met (or activation policy disables the node
  /// in current RPG mode). Player cannot interact.
  locked,

  /// Unlock conditions met; objective in progress (or already complete
  /// for a manual-claim node awaiting the user's tap).
  available,

  /// Objective complete and rewards granted (automatic claim) — or
  /// player tapped to claim (manual claim).
  completed,
}

/// What the node resolver decides for one node on this evaluation.
@immutable
class NodeResolution {
  const NodeResolution({
    required this.node,
    required this.state,
    required this.eligibleByConditions,
    required this.objectiveCompleted,
    required this.periodKey,
  });

  final ProgressionEntry node;
  final NodeState state;

  /// Were the unlock conditions satisfied? Distinct from completion:
  /// a node may be eligible (conditions met) but not yet completed
  /// (objective not yet satisfied or claim pending).
  final bool eligibleByConditions;

  /// Was the bound objective satisfied? Null for nodes with no
  /// `objectiveId` (chapter completions, content unlocks).
  final bool? objectiveCompleted;

  /// Period anchor used for ledger key composition. May be null for
  /// lifetime-scoped nodes.
  final String? periodKey;
}

/// Pure resolver. Decides each node's [NodeState] from:
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
        state: NodeState.locked,
        eligibleByConditions: false,
        objectiveCompleted: null,
        periodKey: periodKey,
      );
    }

    if (!eligibleByConditions) {
      return NodeResolution(
        node: node,
        state: NodeState.locked,
        eligibleByConditions: false,
        objectiveCompleted: objectiveOutcome?.completed,
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
        state: NodeState.completed,
        eligibleByConditions: true,
        objectiveCompleted: objectiveCompleted,
        periodKey: periodKey,
      );
    }

    if (!objectiveCompleted) {
      // Eligible, objective in progress. UI shows progress; not yet
      // a granting event.
      return NodeResolution(
        node: node,
        state: NodeState.available,
        eligibleByConditions: true,
        objectiveCompleted: false,
        periodKey: periodKey,
      );
    }

    // Objective satisfied this run.
    if (node.claimPolicy == ClaimPolicy.manual) {
      // Player must claim before completion lands in the ledger.
      return NodeResolution(
        node: node,
        state: NodeState.available,
        eligibleByConditions: true,
        objectiveCompleted: true,
        periodKey: periodKey,
      );
    }
    return NodeResolution(
      node: node,
      state: NodeState.completed,
      eligibleByConditions: true,
      objectiveCompleted: true,
      periodKey: periodKey,
    );
  }

  // ── Event key helpers ────────────────────────────────────────────
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
