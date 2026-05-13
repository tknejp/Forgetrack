import '../domain/catalog/engine_catalog_context.dart';
import '../domain/catalog/objective_catalog.dart';
import '../domain/catalog/progression_node_catalog.dart';
import '../domain/evaluator/objective_evaluator.dart';
import '../domain/evaluator/progression_node_resolver.dart';
import '../domain/evaluator/reward_grant_planner.dart';
import '../domain/evaluator/unlock_condition_resolver.dart';
import '../domain/models/engine_evaluation_input.dart';
import '../domain/models/ledger_event.dart';
import '../domain/models/claim_policy.dart';
import '../domain/models/progression_node_definition.dart';
import '../domain/models/progression_resolution_reason.dart';
import '../domain/models/quest_policies.dart';
import '../domain/models/reward_definition.dart';
import '../domain/models/unlock_condition.dart';
import '../domain/models/progression_resolution_result.dart';
import '../domain/repository/ledger_snapshot.dart';
import '../domain/repository/progression_engine_repository.dart';
import 'reward_grant_service.dart';

/// Phase 2 engine orchestrator.
///
/// Composes the four evaluators (objective, unlock, node, reward
/// planner) plus the [RewardGrantService] over a
/// [ProgressionEngineRepository]. One canonical method —
/// [evaluate] — produces a [ProgressionResolutionResult] for one
/// run. The result is the only thing downstream consumers consume;
/// nobody else looks at the ledger directly.
///
/// Idempotency: re-running with the same input + ledger produces a
/// result whose `completedNodes`, `availableNodes`, `grantedRewards`
/// match the same sets but where any redundant ledger appends become
/// `skippedEvents`. Tests assert this.
class ProgressionEngine {
  ProgressionEngine({
    required ProgressionEngineRepository repository,
    ObjectiveCatalog objectiveCatalog = const ObjectiveCatalog(),
    ProgressionNodeCatalog nodeCatalog = const ProgressionNodeCatalog(),
    ObjectiveEvaluator objectiveEvaluator = const ObjectiveEvaluator(),
    UnlockConditionResolver unlockConditionResolver =
        const UnlockConditionResolver(),
    ProgressionNodeResolver nodeResolver = const ProgressionNodeResolver(),
    RewardGrantPlanner rewardGrantPlanner = const RewardGrantPlanner(),
    RewardGrantService rewardGrantService = const RewardGrantService(),
    String Function()? runIdGenerator,
  })  : _repository = repository,
        _objectiveCatalog = objectiveCatalog,
        _nodeCatalog = nodeCatalog,
        _objectiveEvaluator = objectiveEvaluator,
        _unlockConditionResolver = unlockConditionResolver,
        _nodeResolver = nodeResolver,
        _rewardGrantPlanner = rewardGrantPlanner,
        _rewardGrantService = rewardGrantService,
        _runIdGenerator = runIdGenerator ?? _defaultRunId;

  final ProgressionEngineRepository _repository;
  final ObjectiveCatalog _objectiveCatalog;
  final ProgressionNodeCatalog _nodeCatalog;
  final ObjectiveEvaluator _objectiveEvaluator;
  final UnlockConditionResolver _unlockConditionResolver;
  final ProgressionNodeResolver _nodeResolver;
  final RewardGrantPlanner _rewardGrantPlanner;
  final RewardGrantService _rewardGrantService;
  final String Function() _runIdGenerator;

  /// Run one full evaluation pass.
  ///
  /// Order:
  ///   1. Load ledger.
  ///   2. Evaluate every objective once.
  ///   3. Resolve every node (unlock conditions, claim policy,
  ///      already-completed lookup).
  ///   4. Plan reward grants for newly-completed nodes.
  ///   5. Build reward events with XP scaling.
  ///   6. Append all new events.
  ///   7. Return canonical result.
  Future<ProgressionResolutionResult> evaluate({
    required EngineEvaluationInput input,
    EngineCatalogContext catalogContext = const EngineCatalogContext(),
    ProgressionResolutionReason reason =
        ProgressionResolutionReason.liveUpdate,
  }) async {
    final runId = _runIdGenerator();
    final ledger = await _repository.loadLedger();
    final objectives = _objectiveCatalog.build(catalogContext);
    final nodes = _nodeCatalog.build(catalogContext);
    final timestamp = input.evaluatedAt;

    // Step 2: evaluate objectives.
    //
    // A persisted `ObjectiveCompletionEvent` for the current period is
    // authoritative: it means the engine (or devtools) already
    // declared this objective done. We carry that forward so the
    // node resolver downstream sees `outcome.completed == true` and
    // emits the proper available / completed state. Without this,
    // devtools shortcuts that write only the objective event
    // (`devToolsMarkObjectiveMet`) would never surface the claim
    // pill, because the live metric reading still says "not yet"
    // and the resolver short-circuited to in-progress.
    final outcomes = <String, ObjectiveOutcome>{};
    final newObjectiveEvents = <ObjectiveCompletionEvent>[];
    final completedObjectives = <ObjectiveCompletion>[];
    for (final o in objectives) {
      var outcome = _objectiveEvaluator.evaluate(o, input);
      final key = ProgressionNodeResolver.objectiveCompletionEventKey(
        o.id,
        outcome.periodKey,
      );
      final persistedComplete = ledger.hasEventKey(key);
      if (persistedComplete && !outcome.completed) {
        outcome = ObjectiveOutcome(
          objectiveId: o.id,
          actualValue: o.targetValue,
          completed: true,
          periodKey: outcome.periodKey,
        );
      }
      outcomes[o.id] = outcome;
      if (!outcome.completed) continue;
      if (persistedComplete) continue;
      final event = ObjectiveCompletionEvent(
        eventKey: key,
        timestamp: timestamp,
        objectiveId: o.id,
        actualValue: outcome.actualValue,
        periodKey: outcome.periodKey,
      );
      newObjectiveEvents.add(event);
      completedObjectives.add(ObjectiveCompletion(
        objectiveId: o.id,
        actualValue: outcome.actualValue,
        event: event,
      ));
    }

    // Step 3: resolve nodes.
    final completedObjectiveIds = {
      ...ledger.objectiveCompletions.map((e) => e.objectiveId),
      ...newObjectiveEvents.map((e) => e.objectiveId),
    };
    final priorCompletedNodeIds = {
      for (final e in ledger.nodeCompletions) e.nodeId,
    };
    final priorClaimedNodeIds = {
      for (final e in ledger.nodeClaims) e.nodeId,
    };

    // Phase 2: chapter / companion eligibility sources are empty.
    // Phase 3+ wires real chapter unlocks (from RewardGrantEvent of
    // kind chapterUnlock) and companion availability (from
    // RewardGrantEvent of kind companionAvailability).
    final unlockedChapterIds = {
      for (final e in ledger.rewardGrants)
        if (e.rewardKind == RewardGrantKind.chapterUnlock && e.chapterId != null)
          e.chapterId!,
    };
    final availableCompanionIds = {
      for (final e in ledger.rewardGrants)
        if (e.rewardKind == RewardGrantKind.companionAvailability &&
            e.companionId != null)
          e.companionId!,
    };

    final resolutions = <NodeResolution>[];
    for (final node in nodes) {
      final eligible = _unlockConditionResolver.isEligible(
        conditions: _conditionsFor(node),
        completedObjectiveIds: completedObjectiveIds,
        completedNodesLifetime: priorCompletedNodeIds,
        claimedNodesLifetime: priorClaimedNodeIds,
        unlockedChapterIds: unlockedChapterIds,
        availableCompanionIds: availableCompanionIds,
        input: input,
        ledger: ledger,
      );
      final resolution = _nodeResolver.resolve(
        node: node,
        objectiveOutcome: _outcomeForNode(node, outcomes),
        eligibleByConditions: eligible,
        input: input,
        ledger: ledger,
      );
      resolutions.add(resolution);
    }

    // Step 4: collect *newly* completed / available nodes (delta vs
    // ledger). Pre-existing completions from the ledger never re-emit.
    final newCompletions = <NodeCompletion>[];
    final newCompletionEvents = <NodeCompletionEvent>[];
    final availability = <NodeAvailability>[];
    final newlyAvailable = <NodeAvailability>[];
    final newAnnouncementEvents = <NodeAnnouncedEvent>[];
    final lockedNodeIds = <String>{};
    final periodKeyByNodeId = <String, String?>{};
    for (final r in resolutions) {
      periodKeyByNodeId[r.node.id] = r.periodKey;
      if (!r.eligibleByConditions) lockedNodeIds.add(r.node.id);
      final completionKey = ProgressionNodeResolver.completionEventKey(
        r.node.id,
        r.periodKey,
      );
      // Periodic quests (daily / weekly) need a NodeCompletionEvent
      // every period they're satisfied — yesterday's completion has
      // a different periodKey, so dedup by the period-aware event
      // key, not by raw node id. The old node-id dedup quietly
      // suppressed every subsequent day's completion (and the
      // matching reward grant), which broke devtools day-advance
      // workflows for daily goals and would have broken real
      // post-midnight rotation too.
      switch (r.state) {
        case _ when r.state.name == 'completed' &&
              !ledger.hasEventKey(completionKey):
          final event = NodeCompletionEvent(
            eventKey: completionKey,
            timestamp: timestamp,
            nodeId: r.node.id,
            periodKey: r.periodKey,
          );
          newCompletionEvents.add(event);
          newCompletions.add(NodeCompletion(nodeId: r.node.id, event: event));
        case _ when r.state.name == 'available' &&
              r.objectiveCompleted == true &&
              r.node.claimPolicy.name == 'manual':
          // Manual-claim node whose objective just satisfied. Surface
          // as available; the player's claim action will trigger a
          // second evaluation that produces the completion.
          availability.add(NodeAvailability(nodeId: r.node.id));
          // Persisted first-time announcement marker: if the ledger
          // has no NodeAnnouncedEvent for this (node, period), we
          // flag this resolution as `newlyAvailable` and queue the
          // marker event. The celebration adapter reads this delta
          // to fire a "company unlocked" overlay exactly once, even
          // across app restarts.
          final announceKey = ProgressionNodeResolver.announcementEventKey(
            r.node.id,
            r.periodKey,
          );
          if (!ledger.hasEventKey(announceKey)) {
            newlyAvailable.add(NodeAvailability(nodeId: r.node.id));
            newAnnouncementEvents.add(NodeAnnouncedEvent(
              eventKey: announceKey,
              timestamp: timestamp,
              nodeId: r.node.id,
              periodKey: r.periodKey,
            ));
          }
        default:
          // Locked or in-progress; nothing to emit.
          break;
      }
    }

    // Step 5: plan + build reward events for the newly-completed set.
    final newlyCompletedNodes = [
      for (final c in newCompletions)
        nodes.firstWhere((n) => n.id == c.nodeId)
    ];
    final planned = _rewardGrantPlanner.plan(
      completedNodes: newlyCompletedNodes,
      ledger: ledger,
      periodKeyByNodeId: periodKeyByNodeId,
      input: input,
    );

    final runningXp = _runningClaimedXp(ledger);
    final built = _rewardGrantService.build(
      planned: planned,
      runningClaimedXp: runningXp,
      timestamp: timestamp,
    );

    // Step 6: append.
    final allNewEvents = [
      ...newObjectiveEvents,
      ...newCompletionEvents,
      ...newAnnouncementEvents,
      ...built.events,
    ];
    if (allNewEvents.isNotEmpty) {
      await _repository.appendEvents(allNewEvents);
    }

    // Step 7: assemble result.
    return ProgressionResolutionResult(
      runId: runId,
      reason: reason,
      completedObjectives: completedObjectives,
      completedNodes: newCompletions,
      availableNodes: availability,
      newlyAvailableNodes: newlyAvailable,
      grantedRewards: [for (final e in built.events) RewardGrant(event: e)],
      skippedEvents: const [],
      warnings: const [],
      inputSnapshot: input,
      allObjectiveOutcomes: outcomes.values.toList(growable: false),
      lockedNodeIds: lockedNodeIds,
    );
  }

  /// Player-initiated claim on a manual-claim node. Appends a
  /// [NodeClaimEvent], then re-runs `evaluate` so the resolver sees
  /// the claim and emits the completion + rewards.
  ///
  /// Returns the resolution result of the post-claim evaluation.
  Future<ProgressionResolutionResult> claim({
    required String nodeId,
    required EngineEvaluationInput input,
    EngineCatalogContext catalogContext = const EngineCatalogContext(),
  }) async {
    final ledger = await _repository.loadLedger();
    final node =
        _nodeCatalog.build(catalogContext).firstWhere((n) => n.id == nodeId);

    // Period key tracks the scope of the bound objective. Nodes
    // without an objectiveId (companions, content unlocks) claim at
    // lifetime scope (periodKey == null).
    final boundObjectiveId = _objectiveIdOf(node);
    String? periodKey;
    if (boundObjectiveId != null) {
      final objective = _objectiveCatalog
          .build(catalogContext)
          .firstWhere((o) => o.id == boundObjectiveId);
      periodKey = _objectiveEvaluator.evaluate(objective, input).periodKey;
    }

    final claimKey = ProgressionNodeResolver.claimEventKey(nodeId, periodKey);
    if (!ledger.hasEventKey(claimKey)) {
      await _repository.appendEvents([
        NodeClaimEvent(
          eventKey: claimKey,
          timestamp: input.evaluatedAt,
          nodeId: nodeId,
          periodKey: periodKey,
        ),
      ]);
    }
    return evaluate(
      input: input,
      catalogContext: catalogContext,
      reason: ProgressionResolutionReason.claim,
    );
  }

  String? _objectiveIdOf(ProgressionNode node) {
    return switch (node) {
      QuestNode(:final objectiveId) => objectiveId,
      AchievementNode(:final objectiveId) => objectiveId,
      MilestoneNode(:final objectiveId) => objectiveId,
      LevelMilestoneNode() => null,
      ChapterCompletionNode() => null,
      CompanionAvailabilityNode() => null,
      RelicNode() => null,
      ContentUnlockNode() => null,
    };
  }

  // ── Authoring / devtools API ────────────────────────────────────
  //
  // Two narrow primitives the devtools layer used to do by hand,
  // moved inside the engine so it stays the single source of ledger
  // writes. Both go through the same period-key resolution +
  // idempotent appendEvents path the production `claim` / `evaluate`
  // flows use; the only difference is that the metric doesn't have
  // to actually satisfy — the engine seeds the events directly and
  // re-evaluates so the rest of the pipeline (resolver, reward
  // planner, celebration adapter) reacts normally.

  /// Mark the node's bound objective as met for the current period
  /// **without** writing a claim. Manual-claim nodes will surface
  /// their normal Vyzvednout pill on the next refresh; auto-claim
  /// nodes complete + grant on the re-evaluation pass.
  ///
  /// Returns the post-write evaluation result, so callers can chain
  /// celebrations / cosmetic dispatch the same way they would after
  /// a normal claim.
  Future<ProgressionResolutionResult> simulateObjectiveMet({
    required String nodeId,
    required EngineEvaluationInput input,
    EngineCatalogContext catalogContext = const EngineCatalogContext(),
  }) async {
    final node = _nodeCatalog
        .build(catalogContext)
        .firstWhere((n) => n.id == nodeId);
    final objectiveId = _objectiveIdOf(node);
    if (objectiveId == null) {
      // Condition-only node (welcome flow, content unlock). Nothing
      // to seed; just re-evaluate so the resolver picks up whatever
      // changed externally.
      return evaluate(
        input: input,
        catalogContext: catalogContext,
        reason: ProgressionResolutionReason.liveUpdate,
      );
    }
    final objective = _objectiveCatalog
        .build(catalogContext)
        .firstWhere((o) => o.id == objectiveId);
    final outcome = _objectiveEvaluator.evaluate(objective, input);
    await _repository.appendEvents([
      ObjectiveCompletionEvent(
        eventKey: ProgressionNodeResolver.objectiveCompletionEventKey(
          objective.id,
          outcome.periodKey,
        ),
        timestamp: input.evaluatedAt,
        objectiveId: objective.id,
        actualValue: objective.targetValue,
        periodKey: outcome.periodKey,
      ),
    ]);
    return evaluate(
      input: input,
      catalogContext: catalogContext,
      reason: ProgressionResolutionReason.liveUpdate,
    );
  }

  /// Fast-forward the node to a fully claimed state:
  ///
  /// * For **manual-claim** nodes: writes the objective completion
  ///   + the claim event. The resolver sees `alreadyClaimed`, emits
  ///   `NodeCompletionEvent` on this run, and the reward planner
  ///   grants whatever the node carries.
  /// * For **auto-claim** nodes: writes the objective completion +
  ///   the node completion + every XP/cosmetic reward event directly.
  ///   No celebration fires (the node is already in
  ///   `priorCompletedNodeIds` on the next eval) but XP and any
  ///   downstream unlocks pick up correctly.
  ///
  /// Returns the post-write evaluation result.
  Future<ProgressionResolutionResult> simulateClaim({
    required String nodeId,
    required EngineEvaluationInput input,
    int levelAtGrant = 1,
    EngineCatalogContext catalogContext = const EngineCatalogContext(),
  }) async {
    final ledger = await _repository.loadLedger();
    final node = _nodeCatalog
        .build(catalogContext)
        .firstWhere((n) => n.id == nodeId);
    final objectiveId = _objectiveIdOf(node);
    String? periodKey;
    if (objectiveId != null) {
      final objective = _objectiveCatalog
          .build(catalogContext)
          .firstWhere((o) => o.id == objectiveId);
      periodKey = _objectiveEvaluator.evaluate(objective, input).periodKey;
    }

    final events = <LedgerEvent>[];
    if (objectiveId != null) {
      final objective = _objectiveCatalog
          .build(catalogContext)
          .firstWhere((o) => o.id == objectiveId);
      events.add(ObjectiveCompletionEvent(
        eventKey: ProgressionNodeResolver.objectiveCompletionEventKey(
          objective.id,
          periodKey,
        ),
        timestamp: input.evaluatedAt,
        objectiveId: objective.id,
        actualValue: objective.targetValue,
        periodKey: periodKey,
      ));
    }
    if (node.claimPolicy == ClaimPolicy.manual) {
      events.add(NodeClaimEvent(
        eventKey: ProgressionNodeResolver.claimEventKey(nodeId, periodKey),
        timestamp: input.evaluatedAt,
        nodeId: nodeId,
        periodKey: periodKey,
      ));
    } else {
      events.add(NodeCompletionEvent(
        eventKey: ProgressionNodeResolver.completionEventKey(
          nodeId,
          periodKey,
        ),
        timestamp: input.evaluatedAt,
        nodeId: nodeId,
        periodKey: periodKey,
      ));
      var grantOrdinal = ledger.rewardGrants.length;
      for (final reward in node.rewards) {
        if (reward is XpReward) {
          events.add(RewardGrantEvent(
            eventKey: ProgressionNodeResolver.rewardEventKey(
              nodeId: nodeId,
              rewardOrdinal: grantOrdinal,
              periodKey: periodKey,
            ),
            timestamp: input.evaluatedAt,
            nodeId: nodeId,
            rewardOrdinal: grantOrdinal,
            rewardKind: RewardGrantKind.xp,
            xpAmount: reward.amount,
            periodKey: periodKey,
            levelAtGrant: levelAtGrant,
            multiplierAtGrant: 1.0,
          ));
          grantOrdinal++;
        } else if (reward is CosmeticReward) {
          events.add(RewardGrantEvent(
            eventKey: ProgressionNodeResolver.rewardEventKey(
              nodeId: nodeId,
              rewardOrdinal: grantOrdinal,
              periodKey: periodKey,
            ),
            timestamp: input.evaluatedAt,
            nodeId: nodeId,
            rewardOrdinal: grantOrdinal,
            rewardKind: RewardGrantKind.cosmetic,
            cosmeticId: reward.cosmeticId,
            periodKey: periodKey,
            levelAtGrant: levelAtGrant,
            multiplierAtGrant: 1.0,
          ));
          grantOrdinal++;
        }
        // Other reward kinds (relic, companion availability, chapter
        // unlock) auto-flow from the node completion on the next
        // evaluate pass; no explicit grant event needed here.
      }
    }
    await _repository.appendEvents(events);
    return evaluate(
      input: input,
      catalogContext: catalogContext,
      reason: ProgressionResolutionReason.claim,
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────

  ObjectiveOutcome? _outcomeForNode(
    ProgressionNode node,
    Map<String, ObjectiveOutcome> outcomes,
  ) {
    return switch (node) {
      QuestNode(:final objectiveId) => outcomes[objectiveId],
      AchievementNode(:final objectiveId) => outcomes[objectiveId],
      MilestoneNode(:final objectiveId) => outcomes[objectiveId],
      _ => null,
    };
  }

  int _runningClaimedXp(LedgerSnapshot ledger) {
    var sum = 0;
    for (final e in ledger.rewardGrants) {
      if (e.rewardKind == RewardGrantKind.xp) {
        sum += e.xpAmount ?? 0;
      }
    }
    return sum;
  }

  /// Combines [ProgressionNode.unlockConditions] with derived
  /// conditions from [QuestNode.prerequisiteNodeIds] and the node's
  /// [QuestNode.gatePolicy].
  ///
  /// `prerequisiteNodeIds` always expand to `NodeCompleted(pid)` —
  /// catalog authors keep the list ergonomic without learning the
  /// UnlockCondition vocabulary. On top of that, [GatePolicy] adds
  /// time-based gates: a [CooldownDays] of 1 day pins a
  /// `NodeCompletedBeforeToday(pid)` for every prereq so combo
  /// chains advance one step per day and chapter side quests reveal
  /// the day after their gating chapter step lands. Catalog content
  /// therefore stops spelling out `NodeCompletedBeforeToday` — the
  /// subtype declares the cadence and the engine wires the gate.
  List<UnlockCondition> _conditionsFor(ProgressionNode node) {
    if (node is! QuestNode || node.prerequisiteNodeIds.isEmpty) {
      return node.unlockConditions;
    }
    final gate = node.gatePolicy;
    final cooldownDays = gate is CooldownDays ? gate.days : 0;
    return [
      ...node.unlockConditions,
      for (final pid in node.prerequisiteNodeIds) NodeCompleted(pid),
      // Today only CooldownDays(1) maps cleanly to a primitive
      // condition. Larger cooldowns would need a new
      // `NodeCompletedAtLeastDaysAgo` condition; deferred until a
      // catalog node actually wants one.
      if (cooldownDays == 1)
        for (final pid in node.prerequisiteNodeIds)
          NodeCompletedBeforeToday(pid),
    ];
  }
}

String _defaultRunId() {
  final ts = DateTime.now().microsecondsSinceEpoch;
  return 'run-$ts';
}
