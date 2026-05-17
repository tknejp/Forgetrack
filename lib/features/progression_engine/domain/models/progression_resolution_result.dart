import 'package:flutter/foundation.dart';

import '../evaluator/objective_evaluator.dart' show ObjectiveOutcome;
import 'engine_evaluation_input.dart';
import 'package:forgetrack/domain/journal/journal_event.dart';
import 'progression_resolution_reason.dart';

export '../evaluator/objective_evaluator.dart' show ObjectiveOutcome;

/// Canonical engine output. Every consumer downstream of the engine
/// (celebration adapter, social publisher, devtools logger, future
/// cloud sync) reads from this; nobody re-evaluates progression
/// logic on top.
@immutable
class ProgressionResolutionResult {
  const ProgressionResolutionResult({
    required this.runId,
    required this.reason,
    required this.completedObjectives,
    required this.completedNodes,
    required this.availableNodes,
    required this.grantedRewards,
    required this.skippedEvents,
    required this.warnings,
    required this.inputSnapshot,
    this.allObjectiveOutcomes = const [],
    this.newlyAvailableNodes = const [],
    this.lockedNodeIds = const {},
  });

  final String runId;
  final ProgressionResolutionReason reason;

  /// Objectives that newly completed during this run. Pre-existing
  /// completions are not re-emitted.
  final List<ObjectiveCompletion> completedObjectives;

  /// Every objective's outcome from this run, regardless of whether
  /// it newly completed. UI consumers (home card progress bars,
  /// quest progress %) read from this so they can show in-progress
  /// state without invoking the engine themselves.
  final List<ObjectiveOutcome> allObjectiveOutcomes;

  /// Nodes that newly entered `completed` state during this run.
  final List<NodeCompletion> completedNodes;

  /// **Snapshot** of every manual-claim node that's currently in
  /// the `available` state — i.e. its objective is satisfied but no
  /// claim event has fired yet. Re-emitted on every evaluation so
  /// UI consumers (XP-pill claimable state, "Vyzvednout vše" CTA)
  /// can read "what's claimable right now" without re-running the
  /// engine. For *first-time announcements* (celebration trigger),
  /// see [newlyAvailableNodes].
  final List<NodeAvailability> availableNodes;

  /// Snapshot of every node the engine resolved to `locked` this run
  /// — its [ProgressionNode.unlockConditions] (incl. derived
  /// `NodeCompleted` / `NodeCompletedBeforeToday` from prereqs +
  /// gatePolicy) were not satisfied. UI surfaces (the daily section
  /// resolver, locked-row builders) read this to drop nodes whose
  /// eligibility state isn't already captured by the cheaper
  /// `levelGate` / `prereqGateNodeId` hints — e.g. a chapter side
  /// quest whose chapter has finished (`ChapterActive` false) was
  /// otherwise indistinguishable from an in-progress one.
  final Set<String> lockedNodeIds;

  /// **Delta** subset of [availableNodes]: nodes that are surfacing
  /// as available for the first time, tracked via a persisted
  /// `NodeAnnouncedEvent` in the ledger. Survives app restarts —
  /// the celebration adapter reads this so a companion-unlocked
  /// overlay fires exactly once across the player's lifetime
  /// (instead of every refresh / cold start), without the
  /// in-memory dedup that the CelebrationController used to keep.
  final List<NodeAvailability> newlyAvailableNodes;

  /// Reward grants newly created during this run. Idempotency: if
  /// a reward was already granted in a prior run, it lands in
  /// [skippedEvents] instead.
  final List<RewardGrant> grantedRewards;

  /// Events the planner intended to emit but the repository or the
  /// engine itself deduped. Surfaced for debug visibility — most
  /// consumers ignore.
  final List<SkippedEvent> skippedEvents;

  /// Soft issues the engine surfaced during resolution (e.g. catalog
  /// references that did not resolve, missing source data). Errors
  /// throw; warnings flow through.
  final List<ResolutionWarning> warnings;

  /// The input the engine evaluated against. Useful for devtools
  /// dumps and cloud sync (so we can re-execute with the same input
  /// later if needed).
  final EngineEvaluationInput inputSnapshot;

  bool get isEmpty =>
      completedObjectives.isEmpty &&
      completedNodes.isEmpty &&
      availableNodes.isEmpty &&
      grantedRewards.isEmpty;
}

@immutable
class ObjectiveCompletion {
  const ObjectiveCompletion({
    required this.objectiveId,
    required this.actualValue,
    required this.event,
  });

  final String objectiveId;
  final double actualValue;

  /// The ledger event that was appended.
  final ObjectiveCompletionEvent event;
}

@immutable
class NodeCompletion {
  const NodeCompletion({
    required this.nodeId,
    required this.event,
  });

  final String nodeId;
  final NodeCompletionEvent event;
}

@immutable
class NodeAvailability {
  const NodeAvailability({
    required this.nodeId,
  });

  final String nodeId;
}

@immutable
class RewardGrant {
  const RewardGrant({
    required this.event,
  });

  final RewardGrantEvent event;
}

@immutable
class SkippedEvent {
  const SkippedEvent({
    required this.eventKey,
    required this.reason,
  });

  final String eventKey;
  final String reason;
}

@immutable
class ResolutionWarning {
  const ResolutionWarning({
    required this.path,
    required this.message,
  });

  final String path;
  final String message;
}
