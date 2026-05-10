import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../cosmetics/application/cosmetics_provider.dart';
import '../../health_connect/application/fitness_provider.dart';
import '../../health_connect/application/goals_provider.dart';
import '../../nutrition/application/kaloricke_tabulky_provider.dart';
import '../../progression/domain/policy/level_policy.dart';
import '../data/provider_engine_input_source.dart';
import '../domain/catalog/engine_catalog_context.dart';
import '../domain/catalog/objective_catalog.dart';
import '../domain/catalog/progression_node_catalog.dart';
import '../domain/evaluator/engine_streak_source.dart';
import '../domain/models/engine_evaluation_input.dart';
import '../domain/models/ledger_event.dart';
import '../domain/models/objective_definition.dart';
import '../domain/models/objective_metric.dart';
import '../domain/models/objective_operator.dart';
import '../domain/models/objective_scope.dart';
import '../domain/models/progression_node_definition.dart';
import '../domain/models/progression_resolution_reason.dart';
import '../domain/models/progression_resolution_result.dart';
import '../domain/models/quest_display_bucket.dart';
import '../domain/models/reward_definition.dart';
import '../domain/repository/ledger_snapshot.dart';
import '../domain/repository/progression_engine_repository.dart';
import 'cosmetic_unlock_bridge.dart';
import 'progression_engine.dart';

export '../domain/evaluator/engine_streak_source.dart' show EngineStreakSummary;

/// Runtime quest with progress info. Built per-build of the
/// resolution result so progress bars reflect the latest evaluation
/// without UI consumers re-running the engine.
@immutable
class EngineQuestProgress {
  const EngineQuestProgress({
    required this.node,
    required this.actualValue,
    required this.targetValue,
    required this.progress,
    required this.isCompleted,
    required this.isAvailableForClaim,
    required this.baseXp,
    required this.previewXp,
    this.domain,
  });

  final QuestNode node;

  /// Current measured value for the quest's objective.
  final double actualValue;
  final double targetValue;

  /// 0..1 progress, clamped. 1.0 once the objective has fired.
  final double progress;

  /// True when a node-completion event exists in the ledger.
  final bool isCompleted;

  /// True when the objective is satisfied AND the quest is
  /// manual-claim AND no claim event has fired yet — the "Vyzvednout"
  /// pill should be active.
  final bool isAvailableForClaim;

  /// Domain inherited from the quest's bound objective. Null only
  /// when the objective has no domain (cross-domain quests).
  final ProgressionDomain? domain;

  /// Base XP authored on the QuestNode's first XpReward (0 when the
  /// quest has no XP reward — e.g. cosmetic-only quests).
  final int baseXp;

  /// XP the player would receive if they claimed *now*, scaled by the
  /// current level via [ProgressionLevelPolicy.scaledRewardXp]. UI
  /// "locked +96 XP" pills read this — as the player levels up the
  /// preview value updates so the displayed XP and the actually-granted
  /// XP always match.
  final int previewXp;

  String get nodeId => node.id;
}

/// Player profile derived from the ledger — total XP plus the
/// level-policy resolved level / xpIntoLevel / nextLevelXp /
/// levelFloorXp. Mirrors the shape of the legacy
/// `ProgressionProfile` so UI consumers can swap providers without
/// rewriting their layout code.
@immutable
class EngineProfile {
  const EngineProfile({
    required this.totalXp,
    required this.level,
    required this.levelFloorXp,
    required this.nextLevelXp,
    required this.xpIntoLevel,
  });

  const EngineProfile.zero()
      : totalXp = 0,
        level = 1,
        levelFloorXp = 0,
        nextLevelXp = 250,
        xpIntoLevel = 0;

  final int totalXp;
  final int level;
  final int levelFloorXp;
  final int nextLevelXp;
  final int xpIntoLevel;

  int get xpToNextLevel => nextLevelXp - totalXp;

  double get levelProgress {
    final span = nextLevelXp - levelFloorXp;
    if (span <= 0) return 1;
    return (xpIntoLevel / span).clamp(0, 1).toDouble();
  }
}

/// Riverpod-style ChangeNotifier wrapper around [ProgressionEngine].
///
/// Phase 6: exposes `bind(goals, fitness, nutrition, cosmetics)` which
/// wires live source providers, builds an [EngineEvaluationInput] +
/// [EngineCatalogContext] on every relevant change, runs `evaluate()`,
/// and dispatches granted cosmetics through [CosmeticUnlockBridge].
///
/// Derived getters (`profile`, `level`, `totalXp`, `completedNodeIds`,
/// `availableNodeIds`) match the V1 provider's shape closely enough
/// that simple UI screens can swap providers with minimal reshaping.
class ProgressionEngineProvider extends ChangeNotifier {
  ProgressionEngineProvider({
    required ProgressionEngine engine,
    required ProgressionEngineRepository repository,
    CosmeticUnlockBridge? cosmeticBridge,
    ProgressionLevelPolicy levelPolicy = const ProgressionLevelPolicy(),
  })  : _engine = engine,
        _repository = repository,
        _cosmeticBridge = cosmeticBridge ?? CosmeticUnlockBridge(),
        _levelPolicy = levelPolicy {
    unawaited(_hydrate());
  }

  final ProgressionEngine _engine;
  final ProgressionEngineRepository _repository;
  final CosmeticUnlockBridge _cosmeticBridge;
  final ProgressionLevelPolicy _levelPolicy;
  final EngineStreakSource _streakSource = const EngineStreakSource();
  final ObjectiveCatalog _objectiveCatalog = const ObjectiveCatalog();
  final ProgressionNodeCatalog _nodeCatalog = const ProgressionNodeCatalog();

  ProviderEngineInputSource? _source;
  String? _lastEvaluatedSignature;
  bool _evaluateQueued = false;

  ProgressionResolutionResult? _lastResult;
  LedgerSnapshot? _ledger;
  bool _isLoading = true;
  bool _isEvaluating = false;
  String? _error;

  // Streak caches — recomputed after every ledger refresh.
  Map<String, EngineStreakSummary> _objectiveStreaks = const {};
  Map<ProgressionDomain, EngineStreakSummary> _domainStreaks = const {};

  // Static node-type id caches. Catalog is const so these are
  // computed once on first access.
  static final Set<String> _achievementNodeIds = {
    for (final n in const ProgressionNodeCatalog().build())
      if (n is AchievementNode) n.id,
  };
  static final Set<String> _questNodeIds = {
    for (final n in const ProgressionNodeCatalog().build())
      if (n is QuestNode) n.id,
  };

  final List<ProgressionResolutionResult> _pendingCelebrations = [];

  bool get isLoading => _isLoading;
  bool get isEvaluating => _isEvaluating;
  String? get error => _error;
  ProgressionResolutionResult? get lastResult => _lastResult;
  LedgerSnapshot? get ledger => _ledger;

  // ── Derived state ────────────────────────────────────────────────

  /// Player profile resolved from the ledger's XP grants. When the
  /// ledger has not yet loaded, returns [EngineProfile.zero].
  EngineProfile get profile {
    final l = _ledger;
    if (l == null) return const EngineProfile.zero();
    final totalXp = _totalClaimedXp(l);
    final base = _levelPolicy.resolve(totalXp);
    return EngineProfile(
      totalXp: base.totalXp,
      level: base.level,
      levelFloorXp: base.levelFloorXp,
      nextLevelXp: base.nextLevelXp,
      xpIntoLevel: base.xpIntoLevel,
    );
  }

  int get level => profile.level;
  int get totalXp => profile.totalXp;

  /// Set of node ids the engine has marked completed. Order is not
  /// guaranteed; consumers should iterate via the catalog when they
  /// need a stable display order.
  Set<String> get completedNodeIds {
    final l = _ledger;
    if (l == null) return const {};
    return {for (final e in l.nodeCompletions) e.nodeId};
  }

  /// Set of manual-claim node ids currently in `available` state per
  /// the most recent resolution. These have the gold "Vyzvednout"
  /// pill on quest cards and home-card pending badges count from this.
  Set<String> get availableNodeIds {
    final r = _lastResult;
    if (r == null) return const {};
    return {for (final a in r.availableNodes) a.nodeId};
  }

  /// Quick alias used by home-card / quests UI for the pending-claim
  /// badge ("3 nevyzvednutých" → `pendingClaimNodeIds.length`).
  Set<String> get pendingClaimNodeIds => availableNodeIds;

  /// Count of unlocked achievements — node completions whose node
  /// type is [AchievementNode]. Cached per-build of the catalog
  /// since the catalog is static.
  int get unlockedAchievementCount {
    final completed = completedNodeIds;
    if (completed.isEmpty) return 0;
    return completed.where(_achievementNodeIds.contains).length;
  }

  /// Count of completed quest nodes — analog of V1's
  /// `completedQuests.length`.
  int get completedQuestCount {
    final completed = completedNodeIds;
    if (completed.isEmpty) return 0;
    return completed.where(_questNodeIds.contains).length;
  }

  /// Runtime quest+progress info for daily-bucket quests. Reads
  /// `allObjectiveOutcomes` from the latest result so progress bars
  /// show in-progress state, not just completed.
  ///
  /// Order matches catalog declaration order.
  List<EngineQuestProgress> get currentDailyQuests {
    return _questsForBucket(QuestDisplayBucket.daily);
  }

  /// Same shape, but for the weekly bucket.
  List<EngineQuestProgress> get currentWeeklyQuests {
    return _questsForBucket(QuestDisplayBucket.weekly);
  }

  /// One representative [EngineQuestProgress] per active chapter.
  ///
  /// "Active" means at least one step in the chain is still in
  /// progress or waiting for a claim. We pick the lowest-chainOrder
  /// step that is not yet completed; that's what the player should be
  /// working on right now. Returns an empty list when all chapters are
  /// either fully completed or not yet unlocked.
  List<EngineQuestProgress> get currentChapterQuests {
    final all = _questsForBucket(QuestDisplayBucket.chapter);
    if (all.isEmpty) return const [];

    final byChain = <String, List<EngineQuestProgress>>{};
    for (final q in all) {
      final chainId = q.node.chainId;
      if (chainId == null) continue;
      byChain.putIfAbsent(chainId, () => []).add(q);
    }

    final out = <EngineQuestProgress>[];
    for (final entry in byChain.entries) {
      final chain = [...entry.value]
        ..sort((a, b) => (a.node.chainOrder ?? 0)
            .compareTo(b.node.chainOrder ?? 0));
      EngineQuestProgress? active;
      for (final q in chain) {
        if (!q.isCompleted) {
          active = q;
          break;
        }
      }
      if (active != null) out.add(active);
    }
    out.sort((a, b) =>
        (a.node.sortOrder).compareTo(b.node.sortOrder));
    return out;
  }

  /// Resolves the chain (in chainOrder) for a given chain id. Used by
  /// the screen's chapter chain preview to render the open → step →
  /// step → finale dots beneath the active card.
  List<EngineQuestProgress> chainQuestsFor(String chainId) {
    final out = <EngineQuestProgress>[];
    for (final q in _questsForBucket(QuestDisplayBucket.chapter)) {
      if (q.node.chainId == chainId) out.add(q);
    }
    out.sort((a, b) =>
        (a.node.chainOrder ?? 0).compareTo(b.node.chainOrder ?? 0));
    return out;
  }

  /// Streak by objective id (only daily-scoped objectives have a
  /// meaningful streak). Returns an empty summary when the
  /// objective is unknown or has no completions yet.
  EngineStreakSummary streakForObjective(String objectiveId) {
    return _objectiveStreaks[objectiveId] ?? const EngineStreakSummary.empty();
  }

  /// Streak by domain — counts consecutive days where any
  /// daily-scoped objective tagged with that domain completed.
  EngineStreakSummary streakForDomain(ProgressionDomain domain) {
    return _domainStreaks[domain] ?? const EngineStreakSummary.empty();
  }

  /// Resolution results that have not yet been consumed by the
  /// celebration overlay host.
  List<ProgressionResolutionResult> get pendingCelebrations =>
      List.unmodifiable(_pendingCelebrations);

  /// Latest [EngineEvaluationInput] derived from the bound source
  /// providers, with ledger totals (totalXp, level) filled in. Returns
  /// null when no source has been bound yet (headless tests, devtools
  /// before init).
  ///
  /// UI claim handlers read this so they don't have to assemble an
  /// input themselves — `provider.currentInput` then
  /// `provider.claimNode(nodeId: ..., input: input)`.
  EngineEvaluationInput? get currentInput {
    final source = _source;
    if (source == null) return null;
    return source.buildInput(
      totalXpFromLedger: totalXp,
      levelFromLedger: level,
    );
  }

  /// Latest [EngineCatalogContext] from the bound source. Null when no
  /// source is bound. UI callers should pair this with [currentInput]
  /// when calling [claimNode] so the engine sees the player's actual
  /// goals.
  EngineCatalogContext? get currentCatalogContext {
    final source = _source;
    if (source == null) return null;
    return source.currentContext();
  }

  /// Reward grants from the ledger, newest first. The quests-screen
  /// "Recent rewards" feed reads this to render a chronological list of
  /// XP / cosmetic / chapter unlocks the player has earned.
  List<RewardGrantEvent> get rewardHistory {
    final l = _ledger;
    if (l == null) return const [];
    final list = [...l.rewardGrants];
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return List.unmodifiable(list);
  }

  /// Completed quest nodes paired with their (most recent) completion
  /// timestamp, newest first. Used by the quests-screen "Completed"
  /// rollup. Filters [LedgerSnapshot.nodeCompletions] down to nodes
  /// the catalog still classifies as a [QuestNode] — stale ledger
  /// entries (catalog drift) are skipped silently.
  List<EngineCompletedQuest> get completedQuests {
    final l = _ledger;
    if (l == null) return const [];

    final latestByNode = <String, NodeCompletionEvent>{};
    for (final e in l.nodeCompletions) {
      final existing = latestByNode[e.nodeId];
      if (existing == null || e.timestamp.isAfter(existing.timestamp)) {
        latestByNode[e.nodeId] = e;
      }
    }

    final out = <EngineCompletedQuest>[];
    for (final node in _nodeCatalog.build()) {
      if (node is! QuestNode) continue;
      final event = latestByNode[node.id];
      if (event == null) continue;
      out.add(EngineCompletedQuest(node: node, completedAt: event.timestamp));
    }
    out.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return List.unmodifiable(out);
  }

  /// Resolves a node id to its catalog definition, or null when the
  /// catalog no longer knows that id. UI consumers (history feed,
  /// completed rollup) call this to look up titles / asset keys for
  /// ledger entries.
  ProgressionNode? nodeById(String id) {
    return ProgressionNodeCatalog.definitionForId(id);
  }

  /// Resolves the visual domain a ledger entry should render under.
  /// Walks node → objective → domain so the history feed and completed
  /// rollup can colour each row by its source domain. Falls back to
  /// `ProgressionDomain.steps` when the node or its objective is not
  /// in the catalog (catalog drift, devtools synthetic grants).
  ProgressionDomain domainForNodeId(String id) {
    final node = ProgressionNodeCatalog.definitionForId(id);
    if (node == null) return ProgressionDomain.steps;
    final objectiveId = switch (node) {
      QuestNode() => node.objectiveId,
      AchievementNode() => node.objectiveId,
      MilestoneNode() => node.objectiveId,
      _ => null,
    };
    if (objectiveId == null) return ProgressionDomain.steps;
    for (final o in _objectiveCatalog.build()) {
      if (o.id == objectiveId) return o.domain ?? ProgressionDomain.steps;
    }
    return ProgressionDomain.steps;
  }

  ProgressionResolutionResult? takePendingCelebration() {
    if (_pendingCelebrations.isEmpty) return null;
    return _pendingCelebrations.removeAt(0);
  }

  // ── Source binding ───────────────────────────────────────────────

  /// Wire live source providers. Builds inputs on every change and
  /// triggers a re-evaluation when the audit signature shifts.
  void bind({
    required GoalsProvider goalsProvider,
    required FitnessProvider fitnessProvider,
    required KalorickeTabulkyProvider nutritionProvider,
    CosmeticsProvider? cosmeticsProvider,
  }) {
    _source = ProviderEngineInputSource(
      goals: goalsProvider,
      fitness: fitnessProvider,
      nutrition: nutritionProvider,
    );
    if (cosmeticsProvider != null) {
      _cosmeticBridge.bindCosmetics(cosmeticsProvider);
    }

    // Subscribe to source changes — every fitness/nutrition/goal
    // notification kicks an audit-signature recheck. Only when the
    // signature changes do we run a real evaluation pass.
    goalsProvider.addListener(_onSourceChanged);
    fitnessProvider.addListener(_onSourceChanged);
    nutritionProvider.addListener(_onSourceChanged);

    unawaited(refresh());
  }

  void _onSourceChanged() {
    final source = _source;
    if (source == null) return;
    final signature = source.auditSignature();
    if (signature == _lastEvaluatedSignature) return;
    unawaited(refresh());
  }

  /// Force a refresh against the bound sources. Coalesces concurrent
  /// requests — a refresh in flight queues a follow-up so we always
  /// end with the latest data.
  Future<void> refresh() async {
    final source = _source;
    if (source == null) return;
    if (_isEvaluating) {
      _evaluateQueued = true;
      return;
    }

    final context = source.currentContext();
    final input = source.buildInput(
      totalXpFromLedger: totalXp,
      levelFromLedger: level,
    );
    _lastEvaluatedSignature = source.auditSignature();
    await evaluateWith(input: input, catalogContext: context);

    if (_evaluateQueued) {
      _evaluateQueued = false;
      // Latest sources may have shifted while we were running.
      if (source.auditSignature() != _lastEvaluatedSignature) {
        unawaited(refresh());
      }
    }
  }

  // ── Engine entry points ──────────────────────────────────────────

  Future<ProgressionResolutionResult?> evaluateWith({
    required EngineEvaluationInput input,
    EngineCatalogContext catalogContext = const EngineCatalogContext(),
    ProgressionResolutionReason reason =
        ProgressionResolutionReason.liveUpdate,
  }) async {
    if (_isEvaluating) return null;
    _isEvaluating = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _engine.evaluate(
        input: input,
        catalogContext: catalogContext,
        reason: reason,
      );
      _lastResult = result;
      _ledger = await _repository.loadLedger();
      _recomputeStreaks();
      if (!result.isEmpty) _pendingCelebrations.add(result);
      // Cosmetic dispatch happens after ledger refresh so the
      // bridge sees a consistent picture.
      await _cosmeticBridge.dispatch(result);
      return result;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isEvaluating = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ProgressionResolutionResult?> claimNode({
    required String nodeId,
    required EngineEvaluationInput input,
    EngineCatalogContext catalogContext = const EngineCatalogContext(),
  }) async {
    if (_isEvaluating) return null;
    _isEvaluating = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _engine.claim(
        nodeId: nodeId,
        input: input,
        catalogContext: catalogContext,
      );
      _lastResult = result;
      _ledger = await _repository.loadLedger();
      _recomputeStreaks();
      if (!result.isEmpty) _pendingCelebrations.add(result);
      await _cosmeticBridge.dispatch(result);
      return result;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isEvaluating = false;
      notifyListeners();
    }
  }

  /// Devtools — seed the ledger with a synthetic XP grant so the
  /// profile reflects the chosen total. Wipes existing grants first
  /// so `totalXp` matches [xp] exactly. Mirrors V1's
  /// `devToolsSetTotalXp` so devtools testing of high-level flows
  /// (level milestones, XP thresholds) does not require completing
  /// dozens of real quests.
  ///
  /// The synthetic grant is recorded with eventKey
  /// `reward|devtools_xp_override|0|grant`, levelAtGrant=1,
  /// multiplierAtGrant=1.0 so it is distinguishable in the ledger
  /// dump.
  Future<void> devToolsSetTotalXp(int xp) async {
    final clamped = xp < 0 ? 0 : xp;
    final repo = _repository;
    if (repo is! ProgressionEngineLocalRepository) return;

    _isEvaluating = true;
    notifyListeners();
    try {
      await repo.wipeAll();
      _lastResult = null;
      _pendingCelebrations.clear();
      _lastEvaluatedSignature = null;

      if (clamped > 0) {
        await repo.appendEvents([
          RewardGrantEvent(
            eventKey: 'reward|devtools_xp_override|0|grant',
            timestamp: DateTime.now(),
            nodeId: 'devtools_xp_override',
            rewardOrdinal: 0,
            rewardKind: RewardGrantKind.xp,
            xpAmount: clamped,
            levelAtGrant: 1,
            multiplierAtGrant: 1.0,
          ),
        ]);
      }

      _ledger = await _repository.loadLedger();
      _recomputeStreaks();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isEvaluating = false;
      notifyListeners();
    }
  }

  /// Devtools — wipe the local ledger. No-op when the bound
  /// repository is not the local Isar variant.
  Future<void> devToolsWipeLedger() async {
    final repo = _repository;
    if (repo is! ProgressionEngineLocalRepository) return;
    _isEvaluating = true;
    notifyListeners();
    try {
      await repo.wipeAll();
      _lastResult = null;
      _pendingCelebrations.clear();
      _ledger = await _repository.loadLedger();
      _recomputeStreaks();
      _lastEvaluatedSignature = null;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isEvaluating = false;
      notifyListeners();
    }
  }

  // ── Internals ────────────────────────────────────────────────────

  Future<void> _hydrate() async {
    try {
      _ledger = await _repository.loadLedger();
      _recomputeStreaks();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int _totalClaimedXp(LedgerSnapshot ledger) {
    var sum = 0;
    for (final e in ledger.rewardGrants) {
      if (e.rewardKind == RewardGrantKind.xp) {
        sum += e.xpAmount ?? 0;
      }
    }
    return sum;
  }

  /// Recomputes streak summaries against the current ledger. Called
  /// from [_hydrate] and after every successful evaluation pass.
  void _recomputeStreaks() {
    final l = _ledger;
    if (l == null) {
      _objectiveStreaks = const {};
      _domainStreaks = const {};
      return;
    }
    final objectives = _objectiveCatalog.build();
    _objectiveStreaks = _streakSource.summarizeByObjective(
      ledger: l,
      objectives: objectives,
    );
    _domainStreaks = _streakSource.summarizeByDomain(
      ledger: l,
      objectives: objectives,
    );
  }

  /// Builds [EngineQuestProgress] entries for every QuestNode in the
  /// requested display bucket. Reads the latest objective outcomes
  /// for in-progress %, the ledger for completion state, and the
  /// last-result availability set for the claim pill.
  List<EngineQuestProgress> _questsForBucket(QuestDisplayBucket bucket) {
    final r = _lastResult;
    final outcomesById = <String, ObjectiveOutcome>{
      for (final o in r?.allObjectiveOutcomes ?? const <ObjectiveOutcome>[])
        o.objectiveId: o,
    };
    final completed = completedNodeIds;
    final available = availableNodeIds;

    final out = <EngineQuestProgress>[];
    for (final node in _nodeCatalog.build()) {
      if (node is! QuestNode) continue;
      if (node.displayBucket != bucket) continue;

      final outcome = outcomesById[node.objectiveId];
      // Look up the objective to get its target — actualValue alone
      // is not enough for a progress bar.
      final objective = _objectiveCatalog.build().firstWhere(
            (o) => o.id == node.objectiveId,
            orElse: () => objectiveCatalogFallback(node.objectiveId),
          );

      final actual = outcome?.actualValue ?? 0;
      final target = objective.targetValue;
      final isCompleted = completed.contains(node.id);
      final isAvailable = available.contains(node.id);

      double progress;
      if (isCompleted) {
        progress = 1.0;
      } else if (target <= 0) {
        progress = 0.0;
      } else {
        progress = (actual / target).clamp(0.0, 1.0).toDouble();
      }

      // Pull the first XP reward off the node (V1 questy nevedou
      // víc XP rewardů, V2 to teoreticky umožňuje — bereme první
      // a sumarizujeme zbytek). Žádný XP reward → previewXp 0.
      var baseXp = 0;
      for (final r in node.rewards) {
        if (r is XpReward) {
          baseXp += r.amount;
        }
      }
      final scaledXp = baseXp == 0
          ? 0
          : _levelPolicy
              .scaledRewardXp(baseXp: baseXp, level: profile.level)
              .round();

      out.add(EngineQuestProgress(
        node: node,
        actualValue: actual,
        targetValue: target,
        progress: progress,
        isCompleted: isCompleted,
        isAvailableForClaim: isAvailable,
        domain: objective.domain,
        baseXp: baseXp,
        previewXp: scaledXp,
      ));
    }
    return out;
  }
}

/// A completed quest node paired with the timestamp of its most
/// recent completion event. Built by
/// [ProgressionEngineProvider.completedQuests] from the ledger.
@immutable
class EngineCompletedQuest {
  const EngineCompletedQuest({required this.node, required this.completedAt});

  final QuestNode node;
  final DateTime completedAt;

  String get nodeId => node.id;
}

/// Synthetic fallback used when a quest references an objective that
/// is no longer in the catalog (catalog drift / stale build). Returns
/// a zero-target objective so progress falls back to 0 instead of
/// throwing.
ObjectiveDefinition objectiveCatalogFallback(String id) => ObjectiveDefinition(
      id: id,
      metric: const StepsMetric(),
      scope: const TodayScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 0,
      debugLabel: 'fallback for missing objective',
    );
