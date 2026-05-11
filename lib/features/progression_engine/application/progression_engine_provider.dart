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
import '../domain/models/unlock_condition.dart';
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
    this.levelGate,
    this.prereqGateNodeId,
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

  /// Level the player must reach for this node's [LevelAtLeast]
  /// unlock condition to pass. Null when the node has no level gate
  /// (or the gate has already been cleared). Chapter cards render a
  /// "Reach level X" lock overlay when this is set.
  final int? levelGate;

  /// Id of the first prerequisite node from
  /// [QuestNode.prerequisiteNodeIds] that hasn't been completed yet.
  /// Null when every prereq is satisfied. Drives the "finish chapter
  /// X first" hint on locked chapter opens — without this, a player
  /// past the level gate but still mid-previous-chapter would see
  /// the next chapter's open in the active section instead of in
  /// ZAMČENÉ.
  final String? prereqGateNodeId;

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

  // Tracked references to currently-subscribed source providers.
  // [bind] is invoked by the ChangeNotifierProxyProvider's `update`
  // callback on every dependency rebuild — without these guards, each
  // bind would `addListener` again and the same `_onSourceChanged`
  // would fire dozens of times per notification. Remember the
  // instance we last attached to and only re-subscribe when it
  // actually changes (provider hot-reload, sign-out, tests).
  GoalsProvider? _subscribedGoals;
  FitnessProvider? _subscribedFitness;
  KalorickeTabulkyProvider? _subscribedNutrition;

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
  /// Returns a deterministic per-date pick of [dailyQuestPickCount]
  /// quests so the player sees a stable rotation each day (V1 parity
  /// — `selectDailyGoalQuestsForDate`). On the same calendar day the
  /// same quests come back regardless of which daily quests have
  /// already been completed; once a quest is in the rotation, it stays
  /// there even if the player completes it (so the card persists with
  /// a check / claimed pill).
  List<EngineQuestProgress> get currentDailyQuests {
    final all = _questsForBucket(QuestDisplayBucket.daily);
    final picked = _pickDailyQuests(all, DateTime.now());
    // Always surface claimable daily quests, even when they fall
    // outside today's rotation. Without this a satisfied-but-unclaimed
    // daily (e.g. yesterday's weight log claim that wasn't picked up by
    // V1 → still pending in the V2 ledger) stays counted in
    // `pendingClaimNodeIds` with nowhere on screen to actually claim
    // it, so the badge reads "1" and the row is invisible. Order:
    // today's rotation first, then any leftover claimable picks.
    final pickedIds = {for (final q in picked) q.nodeId};
    final extras = [
      for (final q in all)
        if (q.isAvailableForClaim && !pickedIds.contains(q.nodeId)) q,
    ];
    if (extras.isEmpty) return picked;
    return [...picked, ...extras];
  }

  /// Returns the full daily quest pool (all daily-bucket quests in
  /// the catalog). Used by the long-term goals section and tests that
  /// need the un-narrowed list.
  List<EngineQuestProgress> get allDailyQuests {
    return _questsForBucket(QuestDisplayBucket.daily);
  }

  /// How many daily quests the rotation surfaces per day. V1 parity:
  /// 2. Devtools / tests can override by reading [allDailyQuests]
  /// directly.
  static const int dailyQuestPickCount = 2;

  /// Same shape, but for the weekly bucket.
  List<EngineQuestProgress> get currentWeeklyQuests {
    return _questsForBucket(QuestDisplayBucket.weekly);
  }

  /// Long-term quests aggregated with any companion nodes that share
  /// the same objective. Drives the "DLOUHODOBÉ CÍLE" section.
  ///
  /// Chain handling mirrors [currentChapterQuests] — for each chain id
  /// we surface the lowest-chainOrder step the player has not yet
  /// completed; orphan long-term quests (no chain) appear one row
  /// each. This matches V1's `compactQuestChainRepresentatives` where
  /// the screen showed one card per chain (the active step) and the
  /// chain preview row inside the card communicated overall progress.
  ///
  /// Each entry also carries the companion nodes that share its
  /// objective (typically the matching achievement). The screen
  /// renders the quest's own pill + non-XP reward chips and surfaces
  /// the companions in the "Also unlocks" expanded panel — V2 design
  /// rule (quest + achievement on the same objective should not
  /// duplicate UI).
  List<EngineLongTermEntry> get currentLongTermQuests {
    final all = _questsForBucket(QuestDisplayBucket.longTerm);
    if (all.isEmpty) return const [];

    // Group by chain so we can pick one representative per chain.
    // Quests without a chainId become their own one-element "chain".
    final byChain = <String, List<EngineQuestProgress>>{};
    final orphans = <EngineQuestProgress>[];
    for (final q in all) {
      final chainId = q.node.chainId;
      if (chainId == null || chainId.isEmpty) {
        orphans.add(q);
      } else {
        byChain.putIfAbsent(chainId, () => []).add(q);
      }
    }

    final reps = <EngineQuestProgress>[];
    for (final entry in byChain.entries) {
      final chain = [...entry.value]
        ..sort((a, b) => (a.node.chainOrder ?? 0)
            .compareTo(b.node.chainOrder ?? 0));
      EngineQuestProgress? active;
      for (final q in chain) {
        // Skip claimed AND claimable steps — they now live in
        // DOKONČENÉ. The long-term card surfaces only the
        // in-progress step.
        if (!q.isCompleted && !q.isAvailableForClaim) {
          active = q;
          break;
        }
      }
      if (active != null) reps.add(active);
    }
    for (final q in orphans) {
      if (!q.isCompleted && !q.isAvailableForClaim) reps.add(q);
    }
    reps.sort((a, b) => a.node.sortOrder.compareTo(b.node.sortOrder));
    if (reps.isEmpty) return const [];

    // Build objective → nodes index once so the per-entry companion
    // lookup is O(1).
    final byObjective = <String, List<ProgressionNode>>{};
    for (final node in _nodeCatalog.build()) {
      final objectiveId = _objectiveIdOf(node);
      if (objectiveId == null) continue;
      byObjective.putIfAbsent(objectiveId, () => []).add(node);
    }

    return [
      for (final quest in reps)
        EngineLongTermEntry(
          quest: quest,
          companions: [
            for (final n in byObjective[quest.node.objectiveId] ?? const [])
              if (n.id != quest.node.id) n,
          ],
        ),
    ];
  }

  static String? _objectiveIdOf(ProgressionNode node) {
    return switch (node) {
      QuestNode() => node.objectiveId,
      AchievementNode() => node.objectiveId,
      MilestoneNode() => node.objectiveId,
      _ => null,
    };
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
        // Skip claimed AND claimable steps — both live in DOKONČENÉ
        // now; the active section shows only the in-progress step.
        if (!q.isCompleted && !q.isAvailableForClaim) {
          active = q;
          break;
        }
      }
      // Skip chapters whose active step is still gated — either by
      // an unmet level requirement or by an unfinished prereq chapter.
      // Those surface in [lockedQuests] / the ZAMČENÉ QUESTY section
      // instead, mirroring V1 behavior where a locked chapter is shown
      // as a compact locked row rather than its full chapter card.
      if (active != null &&
          active.levelGate == null &&
          active.prereqGateNodeId == null) {
        out.add(active);
      }
    }
    out.sort((a, b) =>
        (a.node.sortOrder).compareTo(b.node.sortOrder));
    return out;
  }

  /// Quests that are gated and not yet started — either by an unmet
  /// level requirement or by an unfinished prerequisite chapter.
  /// Surfaces in the "ZAMČENÉ QUESTY" section so the player sees what
  /// is coming up without it crowding the active sections.
  ///
  /// Chapter chains are sequential (`pilgrim_path → forest_trial →
  /// ruins_discipline → …`); the locked section surfaces *only the
  /// single next-up chain* — the lowest-sortOrder chapter whose open
  /// hasn't yet auto-fired. Listing every future chapter would crowd
  /// the section and spoil progression. Non-chapter level-gated quests
  /// (e.g. a standalone weekly with [LevelAtLeast]) are still surfaced
  /// individually.
  List<EngineQuestProgress> get lockedQuests {
    final out = <EngineQuestProgress>[];

    // ── Non-chapter level-gated quests ──────────────────────────────
    // Same shape as the legacy behaviour: any non-chain quest with
    // an unmet level gate gets its own row.
    final seenChains = <String>{};
    for (final bucket in QuestDisplayBucket.values) {
      if (bucket == QuestDisplayBucket.chapter) continue;
      for (final q in _questsForBucket(bucket)) {
        if (q.levelGate == null && q.prereqGateNodeId == null) continue;
        if (q.isCompleted) continue;
        final chainId = q.node.chainId;
        if (chainId != null) {
          if (seenChains.contains(chainId)) continue;
          if ((q.node.chainOrder ?? 0) > 0) continue;
          seenChains.add(chainId);
        }
        out.add(q);
      }
    }

    // ── Chapter chains: surface only the next-up locked chain ──────
    final chapters = _questsForBucket(QuestDisplayBucket.chapter);
    final chapterChains = <String, List<EngineQuestProgress>>{};
    for (final q in chapters) {
      final chainId = q.node.chainId;
      if (chainId == null) continue;
      chapterChains.putIfAbsent(chainId, () => []).add(q);
    }
    // Stable ordering: walk chains by their open (chainOrder 0)
    // sortOrder so Pilgrim → Forest Trial → Ruins → … is preserved.
    final chainsByOpenSortOrder = chapterChains.entries
        .map((e) {
          final sorted = [...e.value]
            ..sort((a, b) =>
                (a.node.chainOrder ?? 0).compareTo(b.node.chainOrder ?? 0));
          return sorted;
        })
        .toList()
      ..sort((a, b) => a.first.node.sortOrder.compareTo(b.first.node.sortOrder));
    for (final chain in chainsByOpenSortOrder) {
      final open = chain.first;
      // Chain already started (open auto-claimed) — handled by
      // currentChapterQuests, never locked here.
      if (open.isCompleted) continue;
      // Open has no gate at all — would auto-fire on next evaluation.
      // Skip; the engine will surface it as active soon.
      if (open.levelGate == null && open.prereqGateNodeId == null) continue;
      // Found the next-up locked chapter. Surface and stop — later
      // chapters stay hidden until this one is reached.
      out.add(open);
      break;
    }

    out.sort((a, b) {
      final byLevel = (a.levelGate ?? 0).compareTo(b.levelGate ?? 0);
      if (byLevel != 0) return byLevel;
      return a.node.sortOrder.compareTo(b.node.sortOrder);
    });
    return out;
  }

  /// Resolves the chain (in chainOrder) for a given chain id. Used by
  /// the chapter card chain preview and the long-term card chain
  /// preview — both render the same dot/connector strip. Scans every
  /// display bucket so chains can live across daily/weekly/chapter/
  /// long-term as authors see fit.
  List<EngineQuestProgress> chainQuestsFor(String chainId) {
    final out = <EngineQuestProgress>[];
    for (final bucket in QuestDisplayBucket.values) {
      for (final q in _questsForBucket(bucket)) {
        if (q.node.chainId == chainId) out.add(q);
      }
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
      totalRewardCount: _totalRewardCountFromLedger(),
      rewardCountByDomain: _rewardCountByDomainFromLedger(),
      nodeCompletionCounts: _nodeCompletionCountsFromLedger(),
      bestStreakByRule: _bestStreakByRuleFromLedger(),
      bestStreakByDomain: _bestStreakByDomainFromLedger(),
      objectiveActualOverrides: _objectiveActualOverridesFromLedger(),
    );
  }

  // ── Ledger-derived input helpers ────────────────────────────────

  /// Total XP-grant count from the ledger. Drives the reward-hunter
  /// chain (RewardCountMetric) and any other counter objective that
  /// reads `input.totalRewardCount`.
  int _totalRewardCountFromLedger() {
    final l = _ledger;
    if (l == null) return 0;
    var n = 0;
    for (final g in l.rewardGrants) {
      if (g.rewardKind == RewardGrantKind.xp) n++;
    }
    return n;
  }

  /// XP-grant counts grouped by domain. Resolves each grant's source
  /// node → objective → domain. Used by domain-scoped reward counters
  /// (e.g. nutrition rewards mastery).
  Map<String, int> _rewardCountByDomainFromLedger() {
    final l = _ledger;
    if (l == null) return const {};
    final out = <String, int>{};
    for (final g in l.rewardGrants) {
      if (g.rewardKind != RewardGrantKind.xp) continue;
      final domain = domainForNodeId(g.nodeId);
      out[domain.name] = (out[domain.name] ?? 0) + 1;
    }
    return out;
  }

  /// Node-completion counts from the ledger. Drives the
  /// [NodeCompletionsMetric] used by chapter step objectives
  /// (forest_trial step 1 needs N completions of `daily_steps_today`).
  Map<String, int> _nodeCompletionCountsFromLedger() {
    final l = _ledger;
    if (l == null) return const {};
    final out = <String, int>{};
    for (final e in l.nodeCompletions) {
      out[e.nodeId] = (out[e.nodeId] ?? 0) + 1;
    }
    return out;
  }

  /// Per-objective measured-value overrides for objectives with a
  /// `baselineFromNodeId`. The override = count of completions of the
  /// objective's metric node *after* the baseline node first
  /// completed. Today only [NodeCompletionsMetric] is supported —
  /// chapter step objectives use this so e.g. `daily_steps_today`
  /// completions banked before a chain step unlocked don't auto-
  /// satisfy the new step. Other metrics drop back to the regular
  /// lifetime read until/if they grow per-event histories.
  Map<String, double> _objectiveActualOverridesFromLedger() {
    final l = _ledger;
    if (l == null) return const {};

    // Earliest completion timestamp per node — defines the unlock
    // moment we baseline from.
    final firstCompletionAt = <String, DateTime>{};
    for (final e in l.nodeCompletions) {
      final existing = firstCompletionAt[e.nodeId];
      if (existing == null || e.timestamp.isBefore(existing)) {
        firstCompletionAt[e.nodeId] = e.timestamp;
      }
    }

    final overrides = <String, double>{};
    for (final objective in _objectiveCatalog.build()) {
      final baselineId = objective.baselineFromNodeId;
      if (baselineId == null) continue;
      final metric = objective.metric;
      final baselineTs = firstCompletionAt[baselineId];
      if (baselineTs == null) {
        // Baseline node hasn't completed yet — the chain step isn't
        // unlocked. Override the value to 0 so the objective reads as
        // not-yet-progressed regardless of historical activity.
        if (metric is NodeCompletionsMetric || metric is RewardCountMetric) {
          overrides[objective.id] = 0;
        }
        continue;
      }
      if (metric is NodeCompletionsMetric) {
        var count = 0;
        for (final e in l.nodeCompletions) {
          if (e.nodeId == metric.nodeId && !e.timestamp.isBefore(baselineTs)) {
            count++;
          }
        }
        overrides[objective.id] = count.toDouble();
      } else if (metric is RewardCountMetric) {
        var count = 0;
        for (final g in l.rewardGrants) {
          if (g.rewardKind != RewardGrantKind.xp) continue;
          if (g.timestamp.isBefore(baselineTs)) continue;
          if (metric.ruleId != null) {
            // Map grant → source node → objective → ruleId is not
            // currently tracked; ruleId-scoped reward counts fall back
            // to lifetime by leaving the override unset.
            continue;
          }
          if (metric.domain != null) {
            final domain = domainForNodeId(g.nodeId);
            if (domain.name != metric.domain) continue;
          }
          count++;
        }
        // Only emit when the metric variant is one we can compute
        // since-unlock for. ruleId-scoped reward counts skip the
        // override and fall back to the lifetime input value.
        if (metric.ruleId == null) {
          overrides[objective.id] = count.toDouble();
        }
      }
      // StepsMetric / CaloriesMetric / etc. baselines are not yet
      // supported — without per-event history we cannot reconstruct
      // the metric value at the baseline timestamp. Chapter steps that
      // use those metrics will fall back to lifetime and can
      // insta-satisfy if the player is already past the threshold at
      // unlock; chain prereqs still enforce sequential ordering.
    }
    return overrides;
  }

  /// Best streak per daily-objective id. The engine's
  /// [StreakDaysMetric.byRule] keys on the objective id (V2 daily
  /// objective ≈ V1 rule id), so this map mirrors what V1 fed in.
  Map<String, int> _bestStreakByRuleFromLedger() {
    return {
      for (final e in _objectiveStreaks.entries) e.key: e.value.bestStreak,
    };
  }

  /// Best streak per domain — feeds [StreakDaysMetric.byDomain].
  Map<String, int> _bestStreakByDomainFromLedger() {
    return {
      for (final e in _domainStreaks.entries) e.key.name: e.value.bestStreak,
    };
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

  /// Reward grants from the ledger, newest first. Includes every
  /// grant kind — useful for devtools, exports, audit trails. The
  /// quests screen does not render this directly anymore: completed
  /// quests, achievements, and milestones are unified under
  /// [completedNodes] and each row already shows its rewards inline.
  List<RewardGrantEvent> get rewardHistory {
    final l = _ledger;
    if (l == null) return const [];
    final list = [...l.rewardGrants];
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return List.unmodifiable(list);
  }

  /// Chain-aware view of every non-daily quest that has progressed
  /// past its objective — either already claimed (`isCompleted`) or
  /// satisfied but pending claim (`isAvailableForClaim`).
  ///
  /// Each entry represents *one* surface in the DOKONČENÉ QUESTY
  /// section:
  ///
  /// - **Chain quests** collapse into a single entry whose chain row
  ///   accumulates a dot per progressed step (V1 parity — one row per
  ///   chain, not per step). The representative is the latest step the
  ///   player has touched (highest chainOrder among claimed +
  ///   claimable), so the row title reads as the most recent progress.
  /// - **Non-chain quests** (orphan weekly / long-term) become their
  ///   own one-step entries.
  ///
  /// Daily quests stay out of this list — they have their own
  /// "Nedávné odměny" surface backed by [recentDailyCompletions].
  ///
  /// Sorted newest-event first so the most recently progressed entry
  /// shows up at the top.
  List<EngineCompletedEntry> get completedEntries {
    final l = _ledger;
    if (l == null) return const [];

    // 1. Collect every non-daily quest that's claimed OR claimable.
    final touched = <EngineQuestProgress>[];
    for (final bucket in QuestDisplayBucket.values) {
      if (bucket == QuestDisplayBucket.daily) continue;
      for (final q in _questsForBucket(bucket)) {
        if (q.isCompleted || q.isAvailableForClaim) touched.add(q);
      }
    }
    if (touched.isEmpty) return const [];

    // 2. Per-node lookups (latest completion event, XP totals,
    //    objective-completion timestamps).
    final completionTsByNode = <String, DateTime>{};
    for (final e in l.nodeCompletions) {
      final existing = completionTsByNode[e.nodeId];
      if (existing == null || e.timestamp.isAfter(existing)) {
        completionTsByNode[e.nodeId] = e.timestamp;
      }
    }
    final objectiveTsByObjective = <String, DateTime>{};
    for (final e in l.objectiveCompletions) {
      final existing = objectiveTsByObjective[e.objectiveId];
      if (existing == null || e.timestamp.isAfter(existing)) {
        objectiveTsByObjective[e.objectiveId] = e.timestamp;
      }
    }
    final xpByNode = <String, int>{};
    for (final g in l.rewardGrants) {
      if (g.rewardKind != RewardGrantKind.xp) continue;
      xpByNode[g.nodeId] = (xpByNode[g.nodeId] ?? 0) + (g.xpAmount ?? 0);
    }

    DateTime tsFor(EngineQuestProgress q) {
      return completionTsByNode[q.nodeId] ??
          objectiveTsByObjective[q.node.objectiveId] ??
          DateTime.now();
    }

    // 3. Bucket by chain id; non-chain quests become orphans.
    // Also build a parallel map of the FULL chain (touched + locked
    // future steps) so the entry can render every dot in its chain
    // preview, not just the steps the player has reached. Locked
    // future steps render as 🔒 dots, communicating "more to come".
    final byChain = <String, List<EngineQuestProgress>>{};
    final fullChainById = <String, List<EngineQuestProgress>>{};
    final orphans = <EngineQuestProgress>[];
    for (final q in touched) {
      final chainId = q.node.chainId;
      if (chainId == null || chainId.isEmpty) {
        orphans.add(q);
      } else {
        byChain.putIfAbsent(chainId, () => []).add(q);
      }
    }
    if (byChain.isNotEmpty) {
      for (final bucket in QuestDisplayBucket.values) {
        if (bucket == QuestDisplayBucket.daily) continue;
        for (final q in _questsForBucket(bucket)) {
          final chainId = q.node.chainId;
          if (chainId == null || !byChain.containsKey(chainId)) continue;
          fullChainById.putIfAbsent(chainId, () => []).add(q);
        }
      }
    }

    // 4. Build companion index once (objective id → sibling nodes).
    final companionsByObjective = <String, List<ProgressionNode>>{};
    for (final node in _nodeCatalog.build()) {
      final id = _objectiveIdOf(node);
      if (id == null) continue;
      companionsByObjective.putIfAbsent(id, () => []).add(node);
    }
    List<ProgressionNode> companionsFor(ProgressionNode self) {
      final id = _objectiveIdOf(self);
      if (id == null) return const [];
      return [
        for (final n in companionsByObjective[id] ?? const [])
          if (n.id != self.id) n,
      ];
    }

    // 5. Build entries.
    final entries = <EngineCompletedEntry>[];

    for (final entryGroup in byChain.entries) {
      final chainId = entryGroup.key;
      final touchedSteps = [...entryGroup.value]
        ..sort((a, b) =>
            (a.node.chainOrder ?? 0).compareTo(b.node.chainOrder ?? 0));
      final fullChain = [...?fullChainById[chainId]]
        ..sort((a, b) =>
            (a.node.chainOrder ?? 0).compareTo(b.node.chainOrder ?? 0));
      // Representative = highest-chainOrder touched step (most recent
      // progress). The chain row shown on the card walks `fullChain`
      // so locked future steps render as 🔒 dots — gives the player
      // a visible "more to come" cue.
      final representative = touchedSteps.last;
      final lastEventAt = touchedSteps
          .map(tsFor)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      final claimedXp = touchedSteps
          .where((q) => q.isCompleted)
          .fold<int>(0, (s, q) => s + (xpByNode[q.nodeId] ?? 0));
      final pendingXp = touchedSteps
          .where((q) => q.isAvailableForClaim && !q.isCompleted)
          .fold<int>(0, (s, q) => s + q.previewXp);
      final hasClaimable =
          touchedSteps.any((q) => q.isAvailableForClaim && !q.isCompleted);
      entries.add(EngineCompletedEntry(
        representative: representative,
        chainQuests: fullChain.isEmpty ? touchedSteps : fullChain,
        companions: companionsFor(representative.node),
        lastEventAt: lastEventAt,
        totalXpClaimed: claimedXp,
        pendingXp: pendingXp,
        hasClaimable: hasClaimable,
      ));
    }

    for (final q in orphans) {
      final claimable = q.isAvailableForClaim && !q.isCompleted;
      entries.add(EngineCompletedEntry(
        representative: q,
        chainQuests: const [],
        companions: companionsFor(q.node),
        lastEventAt: tsFor(q),
        totalXpClaimed: q.isCompleted ? (xpByNode[q.nodeId] ?? 0) : 0,
        pendingXp: claimable ? q.previewXp : 0,
        hasClaimable: claimable,
      ));
    }

    // Sort: pending-claim entries float to the top so the player
    // doesn't miss waiting XP. Within each group, newest event first
    // (latest claim or objective completion) so the most recent
    // activity is the most visible.
    entries.sort((a, b) {
      if (a.hasClaimable != b.hasClaimable) {
        return a.hasClaimable ? -1 : 1;
      }
      return b.lastEventAt.compareTo(a.lastEventAt);
    });
    return List.unmodifiable(entries);
  }

  /// Daily-bucket quest completions only — the "Recent rewards"
  /// section on the quests screen surfaces these so the player sees
  /// what they wrapped up today / this week. Sorted newest first.
  List<EngineCompletedQuest> get recentDailyCompletions {
    return _completedQuestsForBuckets(
      includeBuckets: const {QuestDisplayBucket.daily},
    );
  }

  List<EngineCompletedQuest> _completedQuestsForBuckets({
    Set<QuestDisplayBucket>? includeBuckets,
    Set<QuestDisplayBucket> excludeBuckets = const {},
  }) {
    final l = _ledger;
    if (l == null) return const [];

    final latestByNode = <String, NodeCompletionEvent>{};
    for (final e in l.nodeCompletions) {
      final existing = latestByNode[e.nodeId];
      if (existing == null || e.timestamp.isAfter(existing.timestamp)) {
        latestByNode[e.nodeId] = e;
      }
    }

    // Sum XP grants per node so completed rows can display the actual
    // claimed XP (V1 "+750 XP" pill) instead of just a check.
    final xpByNode = <String, int>{};
    for (final g in l.rewardGrants) {
      if (g.rewardKind != RewardGrantKind.xp) continue;
      xpByNode[g.nodeId] = (xpByNode[g.nodeId] ?? 0) + (g.xpAmount ?? 0);
    }

    final out = <EngineCompletedQuest>[];
    for (final node in _nodeCatalog.build()) {
      if (node is! QuestNode) continue;
      if (includeBuckets != null &&
          !includeBuckets.contains(node.displayBucket)) {
        continue;
      }
      if (excludeBuckets.contains(node.displayBucket)) continue;
      final event = latestByNode[node.id];
      if (event == null) continue;
      out.add(EngineCompletedQuest(
        node: node,
        completedAt: event.timestamp,
        xpGranted: xpByNode[node.id] ?? 0,
      ));
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
    //
    // `bind` is invoked on every proxy-provider rebuild; guard each
    // attach against the instance we already subscribed to so we
    // don't stack duplicate listeners. If the provider instance
    // genuinely changes (sign-out, hot reload), detach from the old
    // one first.
    if (!identical(_subscribedGoals, goalsProvider)) {
      _subscribedGoals?.removeListener(_onSourceChanged);
      goalsProvider.addListener(_onSourceChanged);
      _subscribedGoals = goalsProvider;
    }
    if (!identical(_subscribedFitness, fitnessProvider)) {
      _subscribedFitness?.removeListener(_onSourceChanged);
      fitnessProvider.addListener(_onSourceChanged);
      _subscribedFitness = fitnessProvider;
    }
    if (!identical(_subscribedNutrition, nutritionProvider)) {
      _subscribedNutrition?.removeListener(_onSourceChanged);
      nutritionProvider.addListener(_onSourceChanged);
      _subscribedNutrition = nutritionProvider;
    }

    unawaited(refresh());
  }

  @override
  void dispose() {
    _subscribedGoals?.removeListener(_onSourceChanged);
    _subscribedFitness?.removeListener(_onSourceChanged);
    _subscribedNutrition?.removeListener(_onSourceChanged);
    super.dispose();
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
      totalRewardCount: _totalRewardCountFromLedger(),
      rewardCountByDomain: _rewardCountByDomainFromLedger(),
      nodeCompletionCounts: _nodeCompletionCountsFromLedger(),
      bestStreakByRule: _bestStreakByRuleFromLedger(),
      bestStreakByDomain: _bestStreakByDomainFromLedger(),
      objectiveActualOverrides: _objectiveActualOverridesFromLedger(),
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

  /// Claim a manual-claim node and re-evaluate.
  ///
  /// `input` is treated as a hint, not authoritative — the provider
  /// always rebuilds [currentInput] from the latest ledger before the
  /// engine runs so per-claim counters (totalRewardCount,
  /// nodeCompletionCounts, etc.) reflect every prior claim in the same
  /// loop. Without this rebuild, a sequential claim-all that captures
  /// `input` once at the start ends with a stale resolution result and
  /// can leave nodes hanging in `availableNodes` (e.g. the
  /// reward_count_first quest that only becomes satisfied after the
  /// earlier claims appended reward grants).
  Future<ProgressionResolutionResult?> claimNode({
    required String nodeId,
    EngineEvaluationInput? input,
    EngineCatalogContext? catalogContext,
  }) async {
    if (_isEvaluating) return null;
    _isEvaluating = true;
    _error = null;
    notifyListeners();

    try {
      final freshInput = currentInput ?? input;
      if (freshInput == null) {
        _error = 'claimNode called before sources were bound';
        return null;
      }
      final ctx =
          catalogContext ?? currentCatalogContext ?? const EngineCatalogContext();
      final result = await _engine.claim(
        nodeId: nodeId,
        input: freshInput,
        catalogContext: ctx,
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

  /// Deterministic per-date selection of daily quests. Uses the same
  /// FNV-1a hash V1 used so the rotation lines up across engines until
  /// V1 is removed. Stable for a given (date, questId) pair so a
  /// quest doesn't shuffle out mid-day after the player completes it.
  List<EngineQuestProgress> _pickDailyQuests(
    List<EngineQuestProgress> all,
    DateTime date, {
    int count = dailyQuestPickCount,
  }) {
    if (all.length <= count) return all;
    final dayKey = _dateKey(date);
    final ranked = [...all]..sort((a, b) {
        final byScore = _dailyScore(dayKey, a.nodeId)
            .compareTo(_dailyScore(dayKey, b.nodeId));
        if (byScore != 0) return byScore;
        return a.nodeId.compareTo(b.nodeId);
      });
    return ranked.take(count).toList(growable: false);
  }

  String _dateKey(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  int _dailyScore(String dayKey, String questId) {
    var hash = 0x811c9dc5;
    for (final unit in '$dayKey|$questId'.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
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

      // Surface any LevelAtLeast unlock condition that the player
      // hasn't yet cleared — chapter cards render a "Reach level X"
      // lock overlay when this is set.
      int? levelGate;
      for (final c in node.unlockConditions) {
        if (c is LevelAtLeast && profile.level < c.level) {
          if (levelGate == null || c.level > levelGate) levelGate = c.level;
        }
      }

      // First unmet `prerequisiteNodeIds` entry, in catalog order.
      // The engine resolver also derives `NodeCompleted` conditions
      // from this list, but the resolver only exposes the resulting
      // available/locked state, not *which* prereq is blocking. We
      // recompute here so the ZAMČENÉ row can say "Dokonči X" with
      // the actual blocker name.
      String? prereqGate;
      for (final id in node.prerequisiteNodeIds) {
        if (!completed.contains(id)) {
          prereqGate = id;
          break;
        }
      }

      out.add(EngineQuestProgress(
        node: node,
        actualValue: actual,
        targetValue: target,
        progress: progress,
        isCompleted: isCompleted,
        isAvailableForClaim: isAvailable,
        domain: objective.domain,
        baseXp: baseXp,
        levelGate: levelGate,
        prereqGateNodeId: prereqGate,
        previewXp: scaledXp,
      ));
    }
    return out;
  }
}

/// One row in the "DLOUHODOBÉ CÍLE" section. Wraps a long-term
/// QuestNode with every catalog node that references the same
/// objective, so the UI can surface the shared-objective intent
/// (V2 design rule: quest + achievement on the same goal should not
/// duplicate; the long-term card displays both as one entry).
///
/// Example — `worldwalker_quest` and `steps_total_10000000` both bind
/// to `lifetime_steps_10m`. The screen renders the quest's pill and
/// drops every reward from the achievement (frame, relic cosmetics)
/// into the same card via [companions].
@immutable
class EngineLongTermEntry {
  const EngineLongTermEntry({
    required this.quest,
    required this.companions,
  });

  final EngineQuestProgress quest;

  /// Other nodes in the catalog whose objectiveId matches
  /// `quest.node.objectiveId`. Almost always achievements; could also
  /// be milestones. Empty when the quest stands alone.
  final List<ProgressionNode> companions;

  /// Non-XP rewards across the primary quest + every companion. The
  /// reward chip strip on the card surfaces one chip per entry so the
  /// player sees "+badge, +emblem, +relic" alongside the XP pill.
  List<RewardDefinition> get nonXpRewards {
    final out = <RewardDefinition>[];
    for (final r in quest.node.rewards) {
      if (r is! XpReward) out.add(r);
    }
    for (final c in companions) {
      for (final r in c.rewards) {
        if (r is! XpReward) out.add(r);
      }
    }
    return out;
  }
}

/// One row in the DOKONČENÉ QUESTY section.
///
/// Aggregates the chain (when the representative belongs to one) so the
/// section shows a single entry per chain — dots in the entry's chain
/// row grow as more steps progress. Standalone quests become
/// one-step entries (`chainQuests` empty / single-element).
///
/// Carries enough state to drive the compact card directly:
///
/// - [representative] — the quest whose title / domain / asset / pill
///   drive the collapsed row. Picked as the highest-chainOrder step
///   the player has actually touched (most recent progress).
/// - [chainQuests] — every step in the chain that's claimed or pending
///   claim, in chainOrder. Empty for non-chain entries.
/// - [companions] — sibling catalog nodes sharing the representative's
///   objective (achievement on the same goal). Shown in the expanded
///   panel as the "Také odemkne" list.
/// - [hasClaimable] — there's at least one step waiting on a manual
///   claim. Drives the gold pill in the row.
/// - [pendingXp] / [totalXpClaimed] — sums for the pill label.
@immutable
class EngineCompletedEntry {
  const EngineCompletedEntry({
    required this.representative,
    required this.chainQuests,
    required this.companions,
    required this.lastEventAt,
    required this.totalXpClaimed,
    required this.pendingXp,
    required this.hasClaimable,
  });

  final EngineQuestProgress representative;
  final List<EngineQuestProgress> chainQuests;
  final List<ProgressionNode> companions;
  final DateTime lastEventAt;
  final int totalXpClaimed;
  final int pendingXp;
  final bool hasClaimable;

  bool get isChain => chainQuests.length > 1;
}

/// A single completed quest row — built by
/// [ProgressionEngineProvider.recentDailyCompletions] for the
/// "Nedávné odměny" surface from the most recent
/// [LedgerSnapshot.nodeCompletions] event per node.
@immutable
class EngineCompletedQuest {
  const EngineCompletedQuest({
    required this.node,
    required this.completedAt,
    this.xpGranted = 0,
  });

  final QuestNode node;
  final DateTime completedAt;

  /// Total XP credited by this quest's reward grants in the ledger.
  /// Zero when the catalog node carries no XP reward, or when the
  /// grant pre-dates the field being tracked. UI surfaces a "+XP"
  /// pill on the completed row when this is > 0.
  final int xpGranted;

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
