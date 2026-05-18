import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:forgetrack/domain/progression/catalog/ids.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../cosmetics/application/cosmetics_provider.dart';
import '../../health_connect/application/fitness_provider.dart';
import '../../health_connect/application/goals_provider.dart';
import '../../nutrition/application/kaloricke_tabulky_provider.dart';
import '../domain/activity_claim/activity_claim_constants.dart';
import '../domain/activity_claim/activity_claim_key.dart';
import '../domain/activity_claim/activity_claim_state.dart';
import '../domain/activity_claim/activity_reward_formula.dart';
import '../domain/backfill/daily_backfill_models.dart';
import '../domain/historical_claim_window.dart';
import '../domain/policy/level_policy.dart';
import '../../health_connect/domain/activity_record.dart';
import '../data/provider_engine_input_source.dart';
import '../domain/catalog/engine_catalog_context.dart';
import '../domain/catalog/objective_catalog.dart';
import '../domain/catalog/progression_node_catalog.dart';
import '../domain/evaluator/engine_streak_source.dart';
import '../domain/evaluator/progression_node_resolver.dart';
import '../domain/models/claim_policy.dart';
import '../domain/models/engine_evaluation_input.dart';
import 'package:forgetrack/domain/journal/journal_event.dart';
import 'package:forgetrack/domain/player/player.dart';
import 'package:forgetrack/domain/progression/player/player_achievement_shelf.dart';
import 'package:forgetrack/domain/progression/player/player_quest_catalog.dart';
import 'package:forgetrack/domain/progression/player/player_quest_lifecycle.dart';
import 'player_achievement_shelf_service.dart';
import 'player_quest_catalog_service.dart';
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
import '../../../core/logging/app_log.dart';
import '../domain/repository/progression_engine_repository.dart';
import '../data/hybrid_progression_engine_repository.dart';
import 'cosmetic_unlock_bridge.dart';
import 'daily_section_resolver.dart';
import 'progression_engine.dart';

export '../domain/evaluator/engine_streak_source.dart' show EngineStreakSummary;

/// How [EngineQuestProgress.actualValue] / [EngineQuestProgress.targetValue]
/// should be presented to the player.
///
/// Daily sleep stores its raw value in minutes (Health Connect API
/// convention + matches V1's ledger semantics), but a "0 / 480"
/// progress label reads as nonsense to the player — they think of
/// sleep in hours. The UI consults this hint to format `480` as
/// `8 h` while leaving step / kcal / count metrics untouched.
enum EngineQuestValueUnit {
  /// Default — render as a plain integer count.
  count,

  /// Stored in minutes; render as hours (`raw / 60`) with an "h" suffix.
  minutes,
}

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
    this.valueUnit = EngineQuestValueUnit.count,
    this.isLockedByConditions = false,
  });

  final Quest node;

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
  /// [Quest.prerequisiteNodeIds] that hasn't been completed yet.
  /// Null when every prereq is satisfied. Drives the "finish chapter
  /// X first" hint on locked chapter opens — without this, a player
  /// past the level gate but still mid-previous-chapter would see
  /// the next chapter's open in the active section instead of in
  /// ZAMČENÉ.
  final String? prereqGateNodeId;

  /// How the UI should format [actualValue] / [targetValue]. Set by
  /// the provider from the bound objective's metric — sleep metrics
  /// resolve to [EngineQuestValueUnit.minutes] so labels render as
  /// hours instead of raw minute counts.
  final EngineQuestValueUnit valueUnit;

  /// True when the engine resolved this node to `locked` because its
  /// unlock conditions weren't satisfied — covers gates that the
  /// cheaper `levelGate` / `prereqGateNodeId` hints don't surface,
  /// e.g. a chapter side quest whose `ChapterActive` window has
  /// closed. The daily section resolver drops these so a finished
  /// chapter's side quests don't keep leaking into DENNÍ ÚKOLY.
  final bool isLockedByConditions;

  String get nodeId => node.id;

  /// Phase 6 bridge: derives the [PlayerQuestLifecycle] sealed
  /// discriminator from the three engine-output booleans. Widgets
  /// pattern-match on the sealed type instead of inspecting flags
  /// directly. Mapping pinned by
  /// `test/domain/progression/player/player_quest_lifecycle_test.dart`:
  ///
  ///   - `isLockedByConditions == true` → [QuestLocked]
  ///   - `isCompleted == true`          → [QuestClaimed]
  ///   - `isAvailableForClaim == true`  → [QuestCompletedPendingClaim]
  ///   - otherwise                       → [QuestAvailable]
  ///
  /// Precedence matters: `isLockedByConditions` wins over claim flags
  /// because the daily resolver still rolls up locked side-quests for
  /// the chapter rollup, where the boolean coincidence (`isCompleted`
  /// could be true on a locked-by-conditions side-quest that the
  /// player already finished before the chapter closed) would
  /// otherwise misclassify the row.
  ///
  /// Phase 7 retires the flags and moves authority into
  /// `PlayerQuestCatalogService`; this getter goes away with them.
  PlayerQuestLifecycle get lifecycle {
    if (isLockedByConditions) return const QuestLocked();
    if (isCompleted) return QuestClaimed(finalXp: previewXp);
    if (isAvailableForClaim) {
      return QuestCompletedPendingClaim(previewXp: previewXp);
    }
    return QuestAvailable(
      actual: actualValue,
      target: targetValue,
      progress: progress,
    );
  }
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
    HybridProgressionEngineRepository? cloudSync,
    CosmeticUnlockBridge? cosmeticBridge,
    ProgressionLevelPolicy levelPolicy = const ProgressionLevelPolicy(),
  })  : _engine = engine,
        _repository = repository,
        _cloudSync = cloudSync,
        _cosmeticBridge = cosmeticBridge ?? CosmeticUnlockBridge(),
        _levelPolicy = levelPolicy {
    unawaited(_hydrate());
  }

  final ProgressionEngine _engine;
  final ProgressionEngineRepository _repository;
  // Optional cloud-sync wrapper. When wired, claims/evaluations push
  // ledger events through to Firestore (best-effort, idempotent) and
  // [bindCloudUser] triggers a pull-and-merge so a fresh install /
  // second device converges to the cloud's state on first sign-in.
  // Null in tests and any environment without Firestore.
  final HybridProgressionEngineRepository? _cloudSync;
  final CosmeticUnlockBridge _cosmeticBridge;
  final ProgressionLevelPolicy _levelPolicy;

  String? _boundCloudUid;
  bool _cloudPullInFlight = false;
  final EngineStreakSource _streakSource = const EngineStreakSource();
  final ObjectiveCatalog _objectiveCatalog = const ObjectiveCatalog();
  final ProgressionEntryCatalog _nodeCatalog = const ProgressionEntryCatalog();

  ProviderEngineInputSource? _source;
  String? _lastEvaluatedSignature;
  bool _evaluateQueued = false;

  /// SharedPreferences key carrying the user's "joined the game"
  /// timestamp — the floor for retroactive claim windows. Persisted
  /// once on first hydrate so a fresh install or a future change in
  /// ledger semantics can't shift the player's effective join date.
  static const String _prefsJoinedAtKey = 'forgetrack_joined_at_iso';

  /// Cached join timestamp. Populated by [_hydrate] from prefs (or
  /// seeded there on first run). Null only between provider
  /// construction and the first `_hydrate` completion, in which
  /// window [joinedAt] falls back to `_engineNow`.
  DateTime? _joinedAtCache;

  /// Whole-day clock offset applied to *every* `DateTime.now()` the
  /// provider hands to the engine + rotation helpers. Defaults to 0
  /// in production. Devtools' "Advance day" button bumps this so the
  /// provider behaves as if the player slept and woke up tomorrow —
  /// daily-quest hash rotates, combo `NodeCompletedBeforeToday`
  /// gates open, period keys roll forward, claimed dailies retire.
  int _devDayOffset = 0;

  /// Public read for devtools UI ("Day +N"). Never modify outside
  /// [devToolsAdvanceDay] / [devToolsResetDayOffset].
  int get devDayOffset => _devDayOffset;

  /// Single seam for "now" inside the engine surface. All daily-hash
  /// math, `nodesCompletedToday` filters, evaluation timestamps, and
  /// ledger event timestamps route through here so the devtools
  /// day-offset stays consistent end-to-end. Production never calls
  /// the setter, so this is identical to `DateTime.now()`.
  DateTime _engineNow() =>
      DateTime.now().add(Duration(days: _devDayOffset));

  /// Compact fingerprint of ledger state, mixed into the refresh
  /// cache key so any new event (claim, devtools force-complete,
  /// objective completion) invalidates the cache and triggers a
  /// fresh evaluation. Without this, devtools writes that don't
  /// touch the input sources never invalidate the audit signature
  /// and the UI sticks on a stale `_lastResult` until the next
  /// real-world data shift.
  String _ledgerEventSignature() {
    final l = _ledger;
    if (l == null) return '0|0|0|0|$_devDayOffset';
    return '${l.objectiveCompletions.length}|'
        '${l.nodeCompletions.length}|'
        '${l.nodeClaims.length}|'
        '${l.rewardGrants.length}|'
        '$_devDayOffset';
  }

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
  DateTime? _lastEvaluatedAt;
  bool _isLoading = true;
  bool _isEvaluating = false;
  String? _error;

  // Streak caches — recomputed after every ledger refresh.
  Map<String, EngineStreakSummary> _objectiveStreaks = const {};
  Map<ProgressionDomain, EngineStreakSummary> _domainStreaks = const {};

  // Static node-type id caches. Catalog is const so these are
  // computed once on first access.
  static final Set<String> _achievementIds = {
    for (final n in const ProgressionEntryCatalog().build())
      if (n is Achievement) n.id,
  };
  static final Set<String> _questNodeIds = {
    for (final n in const ProgressionEntryCatalog().build())
      if (n is Quest) n.id,
  };

  final List<ProgressionResolutionResult> _pendingCelebrations = [];

  bool get isLoading => _isLoading;
  bool get isEvaluating => _isEvaluating;
  String? get error => _error;
  ProgressionResolutionResult? get lastResult => _lastResult;
  LedgerSnapshot? get ledger => _ledger;

  /// Timestamp of the most recent successful evaluation or claim. Null
  /// until the first evaluation completes. UI surfaces that want to show
  /// "last synced at" (e.g. the social profile snapshot's `updatedAt`)
  /// read this so the value matches when the engine actually ran rather
  /// than when the surface happened to read.
  DateTime? get lastEvaluatedAt => _lastEvaluatedAt;

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

  /// Public alias for the engine's level-scaling math so out-of-provider
  /// consumers (notably the achievement view adapter) can compute the
  /// preview XP a node would grant at the player's current level
  /// without reaching into the private [_levelPolicy] field. Mirrors
  /// the same call the engine itself uses for quest preview pills.
  int scaledRewardXp({required int baseXp}) =>
      baseXp == 0
          ? 0
          : _levelPolicy.scaledRewardXp(baseXp: baseXp, level: profile.level);

  // ── PlayerQuestCatalog projection ────────────────────────────────
  //
  // Phase 7 read projection. Built lazily on read from the union of
  // the engine's bucket lists, cached by `_ledger` reference identity
  // + dev-day-offset so repeated reads in the same eval window are
  // O(1) instead of O(buckets · resolver). Invalidates implicitly
  // whenever a new ledger snapshot lands (the next read sees a
  // different identity and rebuilds).
  //
  // See:
  //   - lib/domain/progression/player/player_quest_catalog.dart
  //   - ADR `player-quest-catalog-projection`.

  static const PlayerQuestCatalogService _playerQuestCatalogService =
      PlayerQuestCatalogService();

  PlayerQuestCatalog? _cachedPlayerQuestCatalog;
  int? _playerQuestCatalogCacheKey;

  /// Phase 7 read projection. Returns [PlayerQuestCatalog.empty]
  /// before the first ledger load completes; once the ledger is in
  /// place, the catalog rebuilds from the union of
  /// [currentDailyQuests] + [currentWeeklyQuests] +
  /// [currentChapterQuests] + [currentLongTermQuests] (unwrapped
  /// from their `EngineLongTermEntry.quest`) + [lockedQuests].
  ///
  /// Cache by `(identityHashCode(_ledger), _devDayOffset)` — any
  /// devtools "advance day" tap shifts the offset, which shifts the
  /// daily-section pick, which must reseed the catalog even when
  /// the underlying ledger reference is stable.
  PlayerQuestCatalog get playerQuestCatalog {
    final l = _ledger;
    if (l == null) return PlayerQuestCatalog.empty;
    final cacheKey = Object.hash(identityHashCode(l), _devDayOffset);
    final cached = _cachedPlayerQuestCatalog;
    if (cached != null && _playerQuestCatalogCacheKey == cacheKey) {
      return cached;
    }
    final entries = <EngineQuestProgress>[
      ...currentDailyQuests,
      ...currentWeeklyQuests,
      ...currentChapterQuests,
      for (final lt in currentLongTermQuests) lt.quest,
      ...lockedQuests,
    ];
    final catalog = _playerQuestCatalogService.build(
      questProgressEntries: entries,
      evaluatedAt: _lastEvaluatedAt ?? _engineNow(),
    );
    _cachedPlayerQuestCatalog = catalog;
    _playerQuestCatalogCacheKey = cacheKey;
    return catalog;
  }

  // ── PlayerAchievementShelf projection ────────────────────────────
  //
  // Phase 8 read projection mirroring Phase 7. Built lazily from the
  // achievement catalog + the engine's completed/locked sets + the
  // objective outcome lookups. Cached by the same identity-keyed
  // strategy as the quest catalog: a fresh ledger reference or a
  // shifted dev-day-offset rebuilds the shelf; otherwise repeated
  // reads are O(1).
  //
  // See:
  //   - lib/domain/progression/player/player_achievement_shelf.dart
  //   - ADR `player-achievement-shelf-projection`.

  static const PlayerAchievementShelfService _playerAchievementShelfService =
      PlayerAchievementShelfService();

  PlayerAchievementShelf? _cachedPlayerAchievementShelf;
  int? _playerAchievementShelfCacheKey;

  /// Phase 8 read projection. Returns [PlayerAchievementShelf.empty]
  /// before the first evaluation completes; once `_lastResult` is in
  /// place the shelf rebuilds from the achievement catalog +
  /// completed/locked node id sets + per-objective outcome lookups.
  ///
  /// Cache key reuses the Phase 7 scheme:
  /// `(identityHashCode(_ledger), _devDayOffset)`. _lastResult is
  /// refreshed whenever the ledger changes or the engine re-evaluates
  /// — identity-equality on the ledger detects both. The
  /// dev-day-offset term keeps the cache honest when devtools "advance
  /// day" shifts the resolver output without a ledger append.
  PlayerAchievementShelf get playerAchievementShelf {
    final l = _ledger;
    final r = _lastResult;
    if (l == null || r == null) return PlayerAchievementShelf.empty;
    final cacheKey = Object.hash(identityHashCode(l), _devDayOffset);
    final cached = _cachedPlayerAchievementShelf;
    if (cached != null && _playerAchievementShelfCacheKey == cacheKey) {
      return cached;
    }
    final completed = completedNodeIds;
    final locked = lockedNodeIds;
    final shelf = _playerAchievementShelfService.build(
      achievements: achievements,
      completedNodeIds: completed,
      lockedNodeIds: locked,
      earliestCompletionAt: earliestCompletionAt,
      objectiveActual: objectiveActualValue,
      objectiveTarget: (id) =>
          objectiveById(id)?.targetValue.toDouble() ?? 0.0,
      scaledRewardXp: (baseXp) => scaledRewardXp(baseXp: baseXp),
      evaluatedAt: _lastEvaluatedAt ?? _engineNow(),
    );
    _cachedPlayerAchievementShelf = shelf;
    _playerAchievementShelfCacheKey = cacheKey;
    return shelf;
  }

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
  /// badge ("3 nevyzvednutých" → `pendingClaimNodeIds.length`). Counts
  /// **everything** the engine resolved to `available` — daily-goal
  /// atoms (steps / kcal / macros / sleep / activity / weight) plus the
  /// real quests (combo / challenge / chapter / weekly / long-term /
  /// achievements). The home progression card uses this number because
  /// every one of those claims has a surface on home (per-metric pills)
  /// or on the quests tab.
  Set<String> get pendingClaimNodeIds => availableNodeIds;

  /// Pending claims that live on the **quests tab**, excluding daily-goal
  /// atoms (`QuestDisplayBucket.daily`). Those are claimed directly from
  /// the per-metric home cards and would otherwise inflate the quest-tab
  /// badge with claims that have no surface inside the quests screen.
  /// Bottom-nav quest badge reads this so tapping it always lands on a
  /// screen with at least that many claimable affordances visible.
  Set<String> get pendingQuestClaimNodeIds {
    final r = _lastResult;
    if (r == null) return const {};
    final out = <String>{};
    for (final a in r.availableNodes) {
      final def = ProgressionEntryCatalog.definitionForId(a.nodeId);
      if (def is Quest &&
          def.displayBucket == QuestDisplayBucket.daily) {
        continue;
      }
      out.add(a.nodeId);
    }
    return out;
  }

  /// Node ids the engine resolved to `locked` because their unlock
  /// conditions failed. Read by [_questsForBucket] so consumers
  /// (notably [DailySectionResolver]) can drop quests whose lock
  /// state isn't captured by `levelGate` / `prereqGateNodeId` —
  /// e.g. chapter side quests for a finished chapter.
  Set<String> get lockedNodeIds {
    final r = _lastResult;
    if (r == null) return const {};
    return r.lockedNodeIds;
  }

  /// All [Achievement]s from the catalog. Cached on first access
  /// since the catalog is const. Hero/Journey surfaces iterate this to
  /// render the achievement grid and the journey side events.
  Iterable<Achievement> get achievements => _allAchievements;
  static final List<Achievement> _allAchievements = [
    for (final n in const ProgressionEntryCatalog().build())
      if (n is Achievement) n,
  ];

  /// Earliest completion timestamp for [nodeId] from the ledger. Null
  /// when the node has not been completed.
  DateTime? earliestCompletionAt(String nodeId) {
    final l = _ledger;
    if (l == null) return null;
    DateTime? best;
    for (final e in l.nodeCompletions) {
      if (e.nodeId != nodeId) continue;
      if (best == null || e.timestamp.isBefore(best)) {
        best = e.timestamp;
      }
    }
    return best;
  }

  /// Current measured value for an objective from the latest
  /// resolution result. Falls back to 0 when there is no outcome yet
  /// (e.g. before the first evaluation) or [objectiveId] is null.
  double objectiveActualValue(String? objectiveId) {
    if (objectiveId == null) return 0;
    final r = _lastResult;
    if (r == null) return 0;
    for (final o in r.allObjectiveOutcomes) {
      if (o.objectiveId == objectiveId) return o.actualValue;
    }
    return 0;
  }

  /// Catalog lookup for an objective id. Returns null when the
  /// objective is not in the catalog.
  Objective? objectiveById(String? objectiveId) {
    if (objectiveId == null) return null;
    for (final o in _objectiveCatalog.build()) {
      if (o.id == objectiveId) return o;
    }
    return null;
  }

  /// Every quest node that has at least one completion event, paired
  /// with the most recent completion timestamp. Feeds the journey
  /// event feed — the V2 equivalent of legacy
  /// `provider.completedQuests`.
  List<EngineQuestCompletion> get allCompletedQuests {
    final l = _ledger;
    if (l == null) return const [];
    final latestByNode = <String, DateTime>{};
    for (final e in l.nodeCompletions) {
      final existing = latestByNode[e.nodeId];
      if (existing == null || e.timestamp.isAfter(existing)) {
        latestByNode[e.nodeId] = e.timestamp;
      }
    }
    final out = <EngineQuestCompletion>[];
    for (final node in _nodeCatalog.build()) {
      if (node is! Quest) continue;
      final at = latestByNode[node.id];
      if (at == null) continue;
      out.add(EngineQuestCompletion(node: node, completedAt: at));
    }
    out.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return List.unmodifiable(out);
  }

  /// Count of unlocked achievements — node completions whose node
  /// type is [Achievement]. Cached per-build of the catalog
  /// since the catalog is static.
  int get unlockedAchievementCount {
    final completed = completedNodeIds;
    if (completed.isEmpty) return 0;
    return completed.where(_achievementIds.contains).length;
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
  /// "DENNÍ ÚKOLY" — the **bonus** daily-quests pool surfaced on the
  /// quests tab. Per-metric daily goals (`QuestDisplayBucket.daily` —
  /// steps / calories / macros / sleep / activity / weight) do not
  /// appear here; they're claimed directly from the matching home-
  /// screen stat card. This pool only carries the bonus tier:
  ///
  ///   * **Active combo step** (`QuestDisplayBucket.combo`) — the
  ///     one step of the active chain that's not gated by a same-day
  ///     `NodeCompletedBeforeToday`. LifetimeScope → once-and-done.
  ///   * **Daily challenge** (`QuestDisplayBucket.dailyChallenge`) —
  ///     today's deterministic pick from the 6-template pool.
  ///     LifetimeScope → once-and-done.
  ///   * **Chapter side quests** (`QuestDisplayBucket.chapterSideQuest`) —
  ///     surprise unlocks tied to the active chapter's progress.
  ///     When pending they MAY take priority over the other picks.
  ///
  /// **Selection.** Pending chapter side quests (those whose
  /// `ChapterActive` + `NodeCompleted` unlock conditions are
  /// satisfied right now and which aren't claimed yet) **fill the
  /// slots first** — at most two. Remaining slots draw from the
  /// active combo step + today's daily challenge.
  List<EngineQuestProgress> get currentDailyQuests {
    // The resolver knows how to read each quest's [SlotPolicy] and
    // dispatch — pin-claimed-today (side quest), chain placeholder
    // (combo), or hash rotation (daily / daily challenge). All the
    // ad-hoc "is this claimed today?" / "is this step gated by a
    // same-day cooldown?" logic that used to live inline here is
    // now centralised in [DailySectionResolver].
    //
    // The resolver is pure — it only reads the ledger's
    // [QuestOfferedEvent]s; persistence of new offerings happens in
    // [evaluateWith] via [_persistDailyOfferings]. Calling this
    // getter on every UI rebuild is safe.
    return _resolveDailySection().slots;
  }

  DailySectionResolution _resolveDailySection() {
    return const DailySectionResolver().resolve(
      quests: [
        ..._questsForBucket(QuestDisplayBucket.daily),
        ..._questsForBucket(QuestDisplayBucket.dailyChallenge),
        ..._questsForBucket(QuestDisplayBucket.chapterSideQuest),
        ..._questsForBucket(QuestDisplayBucket.combo),
      ],
      ledger: _ledger,
      now: _engineNow(),
      nodesCompletedTodayIds: _nodesCompletedTodayFromLedger(),
    );
  }

  /// Writes today's planned [QuestOfferedEvent]s for slots the
  /// resolver just filled. Idempotent — anything already in the
  /// ledger is dropped before `appendEvents` runs. Called once per
  /// evaluation cycle (after the engine's own writes land) so daily
  /// rotation rolls forward across midnight without depending on UI
  /// rebuilds.
  Future<void> _persistDailyOfferings() async {
    final ledger = _ledger;
    if (ledger == null) return;
    final resolution = _resolveDailySection();
    if (resolution.plannedOfferings.isEmpty) return;
    final newEvents = <QuestOfferedEvent>[
      for (final e in resolution.plannedOfferings)
        if (!ledger.hasEventKey(e.eventKey)) e,
    ];
    if (newEvents.isEmpty) return;
    _ledger = await _repository.appendEvents(newEvents);
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
        // Pick the first not-yet-completed step. Claimable steps
        // (`isAvailableForClaim` true, objective satisfied, awaiting
        // tap) must stay here — the player tracks progress on this
        // card and expects to claim in place. Shunting them to
        // DOKONČENÉ made the workflow feel broken ("I just finished
        // it, why did the card move?").
        if (!q.isCompleted) {
          active = q;
          break;
        }
      }
      if (active != null) reps.add(active);
    }
    for (final q in orphans) {
      if (!q.isCompleted) reps.add(q);
    }
    reps.sort((a, b) => a.node.sortOrder.compareTo(b.node.sortOrder));
    if (reps.isEmpty) return const [];

    // Build objective → nodes index once so the per-entry companion
    // lookup is O(1).
    final byObjective = <String, List<ProgressionEntry>>{};
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

  static String? _objectiveIdOf(ProgressionEntry node) {
    return switch (node) {
      Quest() => node.objectiveId,
      Achievement() => node.objectiveId,
      Milestone() => node.objectiveId,
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
  ///
  /// **Stickiness until midnight.** If the player just claimed a
  /// chapter step today, the *claimed* step stays in the slot
  /// (reading as "Splněno") until midnight — the chain doesn't
  /// snap to the next step the instant the pill is tapped. Tomorrow
  /// the timestamp falls behind today's midnight, the claimed-today
  /// match fails, and the chain advances to the next uncompleted
  /// step. This mirrors the daily / side-quest slot rule so all
  /// claim cards age out at the same wall-clock boundary.
  List<EngineQuestProgress> get currentChapterQuests {
    final all = _questsForBucket(QuestDisplayBucket.chapter);
    if (all.isEmpty) return const [];

    final byChain = <String, List<EngineQuestProgress>>{};
    for (final q in all) {
      final chainId = q.node.chainId;
      if (chainId == null) continue;
      byChain.putIfAbsent(chainId, () => []).add(q);
    }

    final now = _engineNow();
    final out = <EngineQuestProgress>[];
    for (final entry in byChain.entries) {
      final chain = [...entry.value]
        ..sort((a, b) => (a.node.chainOrder ?? 0)
            .compareTo(b.node.chainOrder ?? 0));
      // Walk the chain looking for the first uncompleted step. Track
      // the immediately-preceding completed step so we can pin it
      // when its claim event lands on today's date.
      EngineQuestProgress? lastCompleted;
      EngineQuestProgress? firstUncompleted;
      for (final q in chain) {
        if (q.isCompleted) {
          lastCompleted = q;
        } else {
          firstUncompleted = q;
          break;
        }
      }
      // Same-day pin: if the most recently completed step *landed in
      // the ledger* today, surface it as the active card. We check
      // the NodeCompletionEvent (not NodeClaimEvent) because auto-
      // claim nodes — `ChapterOpener` is the canonical case —
      // never write a claim event, so the chain would silently skip
      // the just-opened chapter card. Completion events are written
      // for both manual + auto claim flows; their timestamp matches
      // `_engineNow` on the run that produced them.
      if (lastCompleted != null &&
          _wasNodeCompletedOnDate(lastCompleted.nodeId, now)) {
        out.add(lastCompleted);
        continue;
      }
      if (firstUncompleted == null) continue;
      // Skip chapters whose next step is still gated — either by an
      // unmet level requirement or by an unfinished prereq chapter.
      // Those surface in [lockedQuests] / the ZAMČENÉ QUESTY section
      // instead, mirroring V1 behavior where a locked chapter is
      // shown as a compact locked row rather than its full card.
      if (firstUncompleted.levelGate != null ||
          firstUncompleted.prereqGateNodeId != null) {
        continue;
      }
      out.add(firstUncompleted);
    }
    out.sort((a, b) =>
        (a.node.sortOrder).compareTo(b.node.sortOrder));
    return out;
  }

  /// True when the ledger holds a `NodeCompletionEvent` for [nodeId]
  /// whose timestamp falls on the same local day as [now]. Used to
  /// keep just-completed chapter chain steps pinned in their card
  /// until midnight (mirrors the slot rule daily / side quests
  /// already use). Reads completion events rather than claim events
  /// so the signal also covers auto-claim nodes (`ChapterOpener`,
  /// finale auto-grants) — those never write a NodeClaimEvent, but
  /// they DO write a NodeCompletionEvent in the same evaluation
  /// pass that decided the node completed.
  bool _wasNodeCompletedOnDate(String nodeId, DateTime now) {
    final l = _ledger;
    if (l == null) return false;
    for (final e in l.nodeCompletions) {
      if (e.nodeId != nodeId) continue;
      final t = e.timestamp.toLocal();
      if (t.year == now.year && t.month == now.month && t.day == now.day) {
        return true;
      }
    }
    return false;
  }

  /// The next-up locked chapter chain (lowest-sortOrder chapter whose
  /// open hasn't auto-fired yet). Returns null when there's no
  /// upcoming locked chapter — either the player is mid-chapter on
  /// every chain or they've completed everything.
  ///
  /// Exposed separately from [lockedQuests] so the JOURNEY section
  /// can render a compact teaser ("Odemkne se na úrovni 30") in
  /// place of the just-finished chapter, instead of pushing it down
  /// into the generic ZAMČENO bucket where it reads as a side note.
  EngineQuestProgress? get nextLockedChapter {
    final chapters = _questsForBucket(QuestDisplayBucket.chapter);
    if (chapters.isEmpty) return null;
    final chains = <String, List<EngineQuestProgress>>{};
    for (final q in chapters) {
      final chainId = q.node.chainId;
      if (chainId == null) continue;
      chains.putIfAbsent(chainId, () => []).add(q);
    }
    final sorted = chains.entries
        .map((e) {
          final c = [...e.value]
            ..sort((a, b) =>
                (a.node.chainOrder ?? 0).compareTo(b.node.chainOrder ?? 0));
          return c;
        })
        .toList()
      ..sort((a, b) => a.first.node.sortOrder.compareTo(b.first.node.sortOrder));
    for (final chain in sorted) {
      final open = chain.first;
      if (open.isCompleted) continue;
      if (open.levelGate == null && open.prereqGateNodeId == null) continue;
      return open;
    }
    return null;
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
      // Combo chains are sequentially gated by `prerequisiteNodeIds`
      // (cross-chain), so they always have a tail of locked steps
      // behind the active one. Surfacing each as its own locked row
      // would crowd the section — the combo section already shows
      // the single active step + a chain preview that hints at
      // what's coming next.
      if (bucket == QuestDisplayBucket.combo) continue;
      // Daily challenge pool — only today's pick surfaces in its
      // own section; the rest of the templates are dormant until
      // tomorrow's hash picks them. Don't crowd the locked section.
      if (bucket == QuestDisplayBucket.dailyChallenge) continue;
      // Chapter side quests are gated by ChapterActive — they're
      // either eligible (visible in the side-quest section) or
      // dormant (chapter not active). They never read as "locked"
      // in the player's sense, so don't list them.
      if (bucket == QuestDisplayBucket.chapterSideQuest) continue;
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

    // Chapter chains used to surface their next-up locked open here
    // too, but the JOURNEY section now renders that teaser inline
    // (via [nextLockedChapter]) so a freshly-completed chapter
    // visibly rolls over to its successor instead of pushing the
    // hint down into the generic ZAMČENO bucket. Keep this method
    // focused on non-chapter level-gated content.

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
    final quests = _questCompletionsFromLedger();
    return source.buildInput(
      totalXpFromLedger: totalXp,
      levelFromLedger: level,
      totalRewardCount: _totalRewardCountFromLedger(),
      rewardCountByDomain: _rewardCountByDomainFromLedger(),
      nodeCompletionCounts: _nodeCompletionCountsFromLedger(),
      bestStreakByRule: _bestStreakByRuleFromLedger(),
      bestStreakByDomain: _bestStreakByDomainFromLedger(),
      totalQuestCompletions: quests.total,
      questCompletionsByBucket: quests.byBucket,
      distinctActiveDays: _distinctActiveDaysFromLedger(),
      nodesCompletedToday: _nodesCompletedTodayFromLedger(),
      comboPoolCompletionCounts: _comboPoolCompletionCountsFromLedger(),
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

  /// Total QuestNode completion count + breakdown by display bucket.
  /// Drives [QuestCompletionsByBucketMetric]. Computed by joining the
  /// ledger's node-completion events with the catalog to filter to
  /// quests only (chapter completions, achievements, etc. are
  /// excluded).
  ({int total, Map<String, int> byBucket}) _questCompletionsFromLedger() {
    final l = _ledger;
    if (l == null) return (total: 0, byBucket: const {});
    var total = 0;
    final byBucket = <String, int>{};
    for (final e in l.nodeCompletions) {
      final node = ProgressionEntryCatalog.definitionForId(e.nodeId);
      if (node is! Quest) continue;
      total += 1;
      final key = node.displayBucket.name;
      byBucket[key] = (byBucket[key] ?? 0) + 1;
    }
    return (total: total, byBucket: byBucket);
  }

  /// Distinct calendar dates with at least one node completion. Drives
  /// [DistinctActiveDaysMetric]. Date-of-event truncation to local
  /// midnight is done here so the evaluator stays pure.
  int _distinctActiveDaysFromLedger() {
    final l = _ledger;
    if (l == null) return 0;
    final days = <DateTime>{};
    for (final e in l.nodeCompletions) {
      final t = e.timestamp.toLocal();
      days.add(DateTime(t.year, t.month, t.day));
    }
    return days.length;
  }

  /// Set of node ids whose **goal is done today** — covers both the
  /// "goal met but not yet claimed" state (objective fired) and the
  /// "claim landed" state (node completion). Drives
  /// [TodayCompletionsAmongMetric] — combo / extra-chapter / daily
  /// challenge cards check "K of {daily_steps_today, …} done today?"
  ///
  /// Reading just `nodeCompletions` would lag the player by a claim:
  /// they walk 8000 steps → daily steps goal met → combo card still
  /// reads 0/2 until the player taps Vyzvednout. The combo metric
  /// reflects work done, not button presses performed, so we union
  /// the objective fires with the node claims. The objective period
  /// key (`yyyy-MM-dd` for TodayScope) is the authoritative "this
  /// happened on day X" marker — no timezone reinterpretation needed
  /// here.
  Set<String> _nodesCompletedTodayFromLedger() {
    final l = _ledger;
    if (l == null) return const {};
    final now = _engineNow();
    final todayKey = _localDateKey(now);
    final out = <String>{};
    for (final e in l.nodeCompletions) {
      final t = e.timestamp.toLocal();
      if (t.year == now.year && t.month == now.month && t.day == now.day) {
        out.add(e.nodeId);
      }
    }
    // Mark a daily quest as "done today" when its bound TodayScope
    // objective has an event for today, even if no node completion
    // has landed yet (manual-claim daily not yet tapped). The catalog
    // wires every daily_X_today node to a unique daily_X objective,
    // so the binding lookup is 1:1.
    final firedToday = <String>{
      for (final e in l.objectiveCompletions)
        if (e.periodKey == todayKey) e.objectiveId,
    };
    if (firedToday.isNotEmpty) {
      for (final node in _nodeCatalog.build()) {
        if (node is! Quest) continue;
        if (firedToday.contains(node.objectiveId)) out.add(node.id);
      }
    }
    return out;
  }

  /// Local-date stamp in the same `yyyy-MM-dd` shape the
  /// [ObjectiveEvaluator] uses for TodayScope periodKeys — equality
  /// against `ObjectiveCompletionEvent.periodKey` lines up.
  String _localDateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  /// `comboPoolId → completions in the pool`. Drives
  /// [ComboPoolCompletionsMetric] used by combo achievements
  /// (`combo_victory_10`, `combo_triple_victory_25/100`). Pool
  /// membership is declared on each [Quest.comboPoolId]; we walk
  /// the ledger, look up each completion in the catalog, and bump the
  /// pool counter when the node is a quest with a non-null pool id.
  Map<String, int> _comboPoolCompletionCountsFromLedger() {
    final l = _ledger;
    if (l == null) return const {};
    final out = <String, int>{};
    for (final e in l.nodeCompletions) {
      final node = ProgressionEntryCatalog.definitionForId(e.nodeId);
      if (node is! Quest) continue;
      final pool = node.comboPoolId;
      if (pool == null) continue;
      out[pool] = (out[pool] ?? 0) + 1;
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

    // Map daily/weekly quest node id → its bound objective id, so the
    // NodeCompletionsMetric path below can also credit objective
    // fires (goal met, claim pending) — see the dedup-by-day logic
    // there for why.
    final objectiveIdByQuestNode = <String, String>{};
    for (final node in _nodeCatalog.build()) {
      if (node is Quest) {
        objectiveIdByQuestNode[node.id] = node.objectiveId;
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
        if (metric is NodeCompletionsMetric ||
            metric is RewardCountMetric ||
            metric is DaysWithAtLeastKAmongMetric) {
          overrides[objective.id] = 0;
        }
        continue;
      }
      if (metric is DaysWithAtLeastKAmongMetric) {
        // Group "done" events by local day, restricted to after the
        // baseline node completed. Count days where at least
        // `atLeast` of `nodeIds` were done. "Done" unions both
        // NodeCompletionEvents (claim landed) and the matching daily
        // ObjectiveCompletionEvents (goal met, claim still pending)
        // — same goal-met-counts-as-done shift the single-node
        // NodeCompletionsMetric path uses below.
        final doneNodesByDay = <String, Set<String>>{};
        for (final nodeId in metric.nodeIds) {
          for (final e in l.nodeCompletions) {
            if (e.nodeId != nodeId) continue;
            if (e.timestamp.isBefore(baselineTs)) continue;
            final dayKey = _localDateKey(e.timestamp.toLocal());
            doneNodesByDay.putIfAbsent(dayKey, () => {}).add(nodeId);
          }
          final boundObjectiveId = objectiveIdByQuestNode[nodeId];
          if (boundObjectiveId == null) continue;
          for (final e in l.objectiveCompletions) {
            if (e.objectiveId != boundObjectiveId) continue;
            if (e.timestamp.isBefore(baselineTs)) continue;
            final dayKey = _localDateKey(e.timestamp.toLocal());
            doneNodesByDay.putIfAbsent(dayKey, () => {}).add(nodeId);
          }
        }
        var qualifyingDays = 0;
        for (final entry in doneNodesByDay.entries) {
          if (entry.value.length >= metric.atLeast) qualifyingDays++;
        }
        overrides[objective.id] = qualifyingDays.toDouble();
      } else if (metric is NodeCompletionsMetric) {
        // Count distinct DAYS (or periodKeys for periodic objectives)
        // on which the metric's quest node was "done" since baseline.
        // "Done" unions:
        //   - NodeCompletionEvent (claim landed), and
        //   - ObjectiveCompletionEvent for the node's bound objective
        //     (goal met but not yet claimed).
        //
        // The second source matters for chapter steps that gate on
        // daily quests: the player walks 8000 steps, daily_steps fires
        // its objective event, the chapter step's "daily steps done
        // once since unlock" check should tick immediately — waiting
        // for the manual Vyzvednout tap before the chapter advances
        // makes the chain feel like double-bookkeeping.
        final boundObjectiveId = objectiveIdByQuestNode[metric.nodeId];
        final periodsSeen = <String>{};
        for (final e in l.nodeCompletions) {
          if (e.nodeId != metric.nodeId) continue;
          if (e.timestamp.isBefore(baselineTs)) continue;
          periodsSeen.add(
            e.periodKey ?? 'ts-${_localDateKey(e.timestamp.toLocal())}',
          );
        }
        if (boundObjectiveId != null) {
          for (final e in l.objectiveCompletions) {
            if (e.objectiveId != boundObjectiveId) continue;
            if (e.timestamp.isBefore(baselineTs)) continue;
            periodsSeen.add(
              e.periodKey ?? 'ts-${_localDateKey(e.timestamp.toLocal())}',
            );
          }
        }
        overrides[objective.id] = periodsSeen.length.toDouble();
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
    //
    // Chapter quests are excluded — they live in the JOURNEY section
    // now, including their "available for claim" state. Surfacing
    // them here again would double-list the same chapter step on
    // both surfaces while the player decides whether to claim.
    //
    // Daily challenges are excluded — they're surfaced in the
    // backfill section ("Historie odměn"), bound to the day they
    // were offered on. Showing them here again would double-list a
    // claim across two surfaces.
    final touched = <EngineQuestProgress>[];
    for (final bucket in QuestDisplayBucket.values) {
      if (bucket == QuestDisplayBucket.daily) continue;
      if (bucket == QuestDisplayBucket.chapter) continue;
      if (bucket == QuestDisplayBucket.dailyChallenge) continue;
      // Long-term quests now stay in the active DLOUHODOBÉ section
      // until claimed (see `currentLongTermQuests`). Surfacing the
      // same claimable card here too would split the claim flow
      // between two surfaces — exactly the confusion the player
      // reported. Only completed long-term entries belong here.
      final longTerm = bucket == QuestDisplayBucket.longTerm;
      for (final q in _questsForBucket(bucket)) {
        if (q.isCompleted) {
          touched.add(q);
        } else if (q.isAvailableForClaim && !longTerm) {
          touched.add(q);
        }
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
          _engineNow();
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
        if (bucket == QuestDisplayBucket.dailyChallenge) continue;
        for (final q in _questsForBucket(bucket)) {
          final chainId = q.node.chainId;
          if (chainId == null || !byChain.containsKey(chainId)) continue;
          fullChainById.putIfAbsent(chainId, () => []).add(q);
        }
      }
    }

    // 4. Build companion index once (objective id → sibling nodes).
    final companionsByObjective = <String, List<ProgressionEntry>>{};
    for (final node in _nodeCatalog.build()) {
      final id = _objectiveIdOf(node);
      if (id == null) continue;
      companionsByObjective.putIfAbsent(id, () => []).add(node);
    }
    List<ProgressionEntry> companionsFor(ProgressionEntry self) {
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

      // Combo chains hide their per-step entries here — those live in
      // the backfill section attached to the day each step was
      // offered. The aggregate chain card only surfaces once the
      // finale is claimable or claimed, signalling the narrative
      // milestone moment ("you closed the chain").
      final isCombo =
          touchedSteps.first.node.displayBucket == QuestDisplayBucket.combo;
      if (isCombo) {
        final finale = fullChain.isEmpty ? touchedSteps.last : fullChain.last;
        if (!finale.isCompleted && !finale.isAvailableForClaim) continue;
      }
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

  /// Resolves a node id to its catalog definition, or null when the
  /// catalog no longer knows that id. UI consumers (history feed,
  /// completed rollup) call this to look up titles / asset keys for
  /// ledger entries.
  ProgressionEntry? nodeById(String id) {
    return ProgressionEntryCatalog.definitionForId(id);
  }

  /// Resolves the visual domain a ledger entry should render under.
  /// Walks node → objective → domain so the history feed and completed
  /// rollup can colour each row by its source domain. Falls back to
  /// `ProgressionDomain.steps` when the node or its objective is not
  /// in the catalog (catalog drift, devtools synthetic grants).
  ProgressionDomain domainForNodeId(String id) {
    final node = ProgressionEntryCatalog.definitionForId(id);
    if (node == null) return ProgressionDomain.steps;
    final objectiveId = switch (node) {
      Quest() => node.objectiveId,
      Achievement() => node.objectiveId,
      Milestone() => node.objectiveId,
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
    String? authUid,
  }) {
    bindCloudUser(authUid);
    _source = ProviderEngineInputSource(
      goals: goalsProvider,
      fitness: fitnessProvider,
      nutrition: nutritionProvider,
      // Route the input source's clock through the same dev offset
      // so EngineEvaluationInput.evaluatedAt advances in lockstep
      // with the daily-rotation hash and ledger timestamps when
      // devtools bumps the day.
      clock: _engineNow,
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

  /// Wires the cloud-sync wrapper to the active user. No-op when
  /// [_cloudSync] is null (tests / Firestore disabled). On the first
  /// non-null uid this also kicks a pull-and-merge so a fresh install
  /// or second device picks up everything claimed elsewhere before
  /// the engine is asked for its first evaluation.
  ///
  /// Re-entrant: if [bind] fires again with the same uid it's cheap
  /// (the hybrid repo dedupes; pull is gated by [_boundCloudUid]).
  void bindCloudUser(String? uid) {
    final cloud = _cloudSync;
    if (cloud == null) return;
    cloud.bindUser(uid);
    if (uid == null || uid.isEmpty) {
      _boundCloudUid = null;
      return;
    }
    if (_boundCloudUid == uid) return;
    _boundCloudUid = uid;
    unawaited(_pullCloudLedger(uid, cloud));
  }

  Future<void> _pullCloudLedger(
    String uid,
    HybridProgressionEngineRepository cloud,
  ) async {
    if (_cloudPullInFlight) return;
    _cloudPullInFlight = true;
    try {
      final merged = await cloud.pullAndMerge(uid);
      // Only adopt the cloud snapshot if the user is still bound to the
      // same uid by the time the network round-trip resolves — sign-out
      // mid-pull would otherwise stamp another user's ledger over a
      // signed-out state.
      if (_boundCloudUid != uid) return;
      _ledger = merged;
      _lastEvaluatedAt = _mostRecentLedgerTimestamp(_ledger);
      _recomputeStreaks();
      // Replay historical cosmetic grants into the local CosmeticsProvider.
      // engine.evaluate() will not re-emit them (the events are already
      // in the ledger), so without this call a second device sees the
      // engine state restored but the cosmetics inventory empty.
      await _cosmeticBridge.reapplyHistoricalCosmetics(merged);
      // Force re-evaluation: the cloud may have brought new claims
      // that change available / completed sets.
      _lastEvaluatedSignature = null;
      notifyListeners();
      unawaited(refresh());
    } catch (error, stackTrace) {
      AppLog.sync.warn(
        'engine cloud pull failed',
        payload: 'uid=$uid error=$error',
      );
      AppLog.sync.debug('engine cloud pull stack', payload: stackTrace);
    } finally {
      _cloudPullInFlight = false;
    }
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
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

    // Bail when *both* the source state AND the ledger event count
    // have not moved since the previous run. `bind()` calls refresh()
    // on every proxy-provider rebuild, and the post-eval cosmetic
    // dispatch fires a CosmeticsProvider listener notification that
    // itself triggers another proxy rebuild — without this guard the
    // two close into an infinite re-evaluation cascade that inflates
    // `_pendingCelebrations` on every cycle.
    //
    // The ledger half of the signature is the key fix for UI delay:
    // devtools chip taps + manual claims write events directly to
    // the repo without touching the fitness/nutrition/goals input
    // sources, so the source-only signature stayed identical and
    // refresh would silently bail, leaving `_lastResult` stale and
    // the UI showing pre-action state. Including the ledger event
    // count in the signature guarantees every new event invalidates
    // the cache and triggers a fresh evaluation.
    final signature = '${source.auditSignature()}|${_ledgerEventSignature()}';
    if (_lastResult != null && signature == _lastEvaluatedSignature) {
      return;
    }

    final context = source.currentContext();
    final quests = _questCompletionsFromLedger();
    final input = source.buildInput(
      totalXpFromLedger: totalXp,
      levelFromLedger: level,
      totalRewardCount: _totalRewardCountFromLedger(),
      rewardCountByDomain: _rewardCountByDomainFromLedger(),
      nodeCompletionCounts: _nodeCompletionCountsFromLedger(),
      bestStreakByRule: _bestStreakByRuleFromLedger(),
      bestStreakByDomain: _bestStreakByDomainFromLedger(),
      totalQuestCompletions: quests.total,
      questCompletionsByBucket: quests.byBucket,
      distinctActiveDays: _distinctActiveDaysFromLedger(),
      nodesCompletedToday: _nodesCompletedTodayFromLedger(),
      comboPoolCompletionCounts: _comboPoolCompletionCountsFromLedger(),
      objectiveActualOverrides: _objectiveActualOverridesFromLedger(),
    );
    _lastEvaluatedSignature = signature;
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
      // Daily-section rotation events get written *after* the engine
      // pass so the resolver sees up-to-date quest-progress flags
      // (isCompleted, isAvailableForClaim) before deciding what to
      // pin in the slot. Idempotent — same-day repeat calls are no-ops.
      await _persistDailyOfferings();
      _lastEvaluatedAt = _engineNow();
      _recomputeStreaks();
      if (!result.isEmpty) _pendingCelebrations.add(result);
      // Cosmetic dispatch happens after ledger refresh so the
      // bridge sees a consistent picture.
      await _cosmeticBridge.dispatch(
        result,
        ledger: _ledger,
        level: profile.level,
      );
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
      _lastEvaluatedAt = _engineNow();
      _recomputeStreaks();
      if (!result.isEmpty) _pendingCelebrations.add(result);
      await _cosmeticBridge.dispatch(
        result,
        ledger: _ledger,
        level: profile.level,
      );
      // Second-pass refresh so combo steps + chapter steps that read
      // `input.nodesCompletedToday` pick up the freshly-completed
      // node. `engine.claim` evaluates with the input captured BEFORE
      // the NodeCompletionEvent was written, so any objective that
      // depends on "is this node done today" stayed at its pre-claim
      // value. Mirrors the two-pass pattern used by
      // [devToolsForceCompleteNode]. The audit-signature gate must be
      // cleared since no input source changed externally.
      _isEvaluating = false;
      _lastEvaluatedSignature = null;
      await refresh();
      return _lastResult;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isEvaluating = false;
      notifyListeners();
    }
  }

  // ── Per-activity claims (home expanded activity card) ─────────────

  /// Stable timestamp of the player's first day in the app — floor
  /// for every retroactive claim window so a fresh install never
  /// offers claims on days that predate the player joining.
  ///
  /// Persisted to SharedPreferences on first hydrate so it survives
  /// ledger wipes and engine schema changes; existing users get a
  /// one-time backfill from their earliest ledger event.
  DateTime get joinedAt => _joinedAtCache ?? _engineNow();

  /// Current retroactive claim window, derived from [joinedAt] and
  /// the engine clock. Exposed so UI surfaces can match their own
  /// filter ranges to the engine's authoritative window without
  /// recomputing the math themselves.
  HistoricalClaimWindow get historicalClaimWindow => makeHistoricalClaimWindow(
        now: _engineNow(),
        joinedAt: joinedAt,
      );

  /// Per-day list of [ActivityClaimState] for the home activity card
  /// and the activities screen. Pure derivation from the ledger plus
  /// the supplied [activities] — does not query HC itself, the caller
  /// passes whichever set of records is in scope.
  ///
  /// [date] filters by calendar day. Activities outside the
  /// retroactive claim window render with `isWithinWindow: false` —
  /// the pill should be locked, not hidden, so the player understands
  /// why historic data isn't claimable.
  List<ActivityClaimState> activityClaimsForDate({
    required DateTime date,
    required Iterable<ActivityRecord> activities,
  }) {
    final day = DateTime(date.year, date.month, date.day);
    final window = makeHistoricalClaimWindow(
      now: _engineNow(),
      joinedAt: joinedAt,
    );
    final isInWindow = window.contains(day);
    final claimedKeys = _claimedActivityKeys();
    final grantsByKey = _activityGrantsByKey();
    final currentLevel = level;
    final out = <ActivityClaimState>[];
    for (final a in activities) {
      final aDay =
          DateTime(a.startTime.year, a.startTime.month, a.startTime.day);
      if (aDay != day) continue;
      final key = activityClaimKey(a);
      final isClaimed = claimedKeys.contains(key);
      final baseXp = activityRewardXp(
        durationMinutes: a.duration.inMinutes,
        hcType: a.type,
      );
      // Claimed pill freezes on the historically granted amount so a
      // level-up after the claim does not retroactively change the
      // "+N XP" the player saw.
      final xp = isClaimed
          ? (grantsByKey[key] ??
              _levelPolicy.scaledRewardXp(
                baseXp: baseXp,
                level: currentLevel,
              ))
          : _levelPolicy.scaledRewardXp(
              baseXp: baseXp,
              level: currentLevel,
            );
      out.add(
        ActivityClaimState(
          record: a,
          claimKey: key,
          previewXp: xp,
          isClaimed: isClaimed,
          isWithinWindow: isInWindow,
        ),
      );
    }
    out.sort((a, b) => b.record.startTime.compareTo(a.record.startTime));
    return out;
  }

  /// Single-record variant of [activityClaimsForDate] — convenient
  /// when iterating a heterogenous list (activities screen across a
  /// week / month) where per-day filtering would force a regroup.
  ActivityClaimState activityClaim(ActivityRecord record) {
    final day = DateTime(
      record.startTime.year,
      record.startTime.month,
      record.startTime.day,
    );
    final window = makeHistoricalClaimWindow(
      now: _engineNow(),
      joinedAt: joinedAt,
    );
    final isInWindow = window.contains(day);
    final key = activityClaimKey(record);
    final isClaimed = _claimedActivityKeys().contains(key);
    final baseXp = activityRewardXp(
      durationMinutes: record.duration.inMinutes,
      hcType: record.type,
    );
    final granted = _activityGrantsByKey()[key];
    final xp = isClaimed
        ? (granted ??
            _levelPolicy.scaledRewardXp(baseXp: baseXp, level: level))
        : _levelPolicy.scaledRewardXp(baseXp: baseXp, level: level);
    return ActivityClaimState(
      record: record,
      claimKey: key,
      previewXp: xp,
      isClaimed: isClaimed,
      isWithinWindow: isInWindow,
    );
  }

  Set<String> _claimedActivityKeys() {
    final l = _ledger;
    if (l == null) return const {};
    final out = <String>{};
    for (final e in l.nodeClaims) {
      if (e.nodeId != kActivityWorkoutClaimNodeId) continue;
      final k = e.periodKey;
      if (k != null) out.add(k);
    }
    return out;
  }

  Map<String, int> _activityGrantsByKey() {
    final l = _ledger;
    if (l == null) return const {};
    final out = <String, int>{};
    for (final e in l.rewardGrants) {
      if (e.nodeId != kActivityWorkoutClaimNodeId) continue;
      if (e.rewardKind != RewardGrantKind.xp) continue;
      final k = e.periodKey;
      final xp = e.xpAmount;
      if (k == null || xp == null) continue;
      out.putIfAbsent(k, () => xp);
    }
    return out;
  }

  /// Player-initiated claim on a single workout. Writes a
  /// [NodeClaimEvent] + [RewardGrantEvent] under the synthetic
  /// [kActivityWorkoutClaimNodeId] with the activity's claim key as
  /// the event's `periodKey`. Bypasses the engine resolver — there is
  /// no catalog node to match — but reuses the standard ledger /
  /// reward-grant plumbing, so total XP / level / streaks update
  /// automatically and cloud sync replicates the event like any other
  /// grant.
  ///
  /// No-op when: another evaluation is in flight, the activity has no
  /// duration, the calendar day is outside [historicalClaimWindow],
  /// or a claim event already exists for this key.
  Future<void> claimActivity(ActivityRecord activity) async {
    if (_isEvaluating) return;
    final baseXp = activityRewardXp(
      durationMinutes: activity.duration.inMinutes,
      hcType: activity.type,
    );
    if (baseXp <= 0) return;

    final day = DateTime(
      activity.startTime.year,
      activity.startTime.month,
      activity.startTime.day,
    );
    final window = makeHistoricalClaimWindow(
      now: _engineNow(),
      joinedAt: joinedAt,
    );
    if (!window.contains(day)) return;

    final key = activityClaimKey(activity);
    if (_claimedActivityKeys().contains(key)) return;

    final currentLevel = level;
    final scaledXp = _levelPolicy.scaledRewardXp(
      baseXp: baseXp,
      level: currentLevel,
    );
    final multiplier = _levelPolicy.rewardMultiplierForLevel(currentLevel);
    final now = _engineNow();
    final ordinal = _ledger?.rewardGrants.length ?? 0;

    _isEvaluating = true;
    notifyListeners();
    try {
      await _repository.appendEvents([
        NodeClaimEvent(
          eventKey: 'node|$kActivityWorkoutClaimNodeId|$key|claim',
          timestamp: now,
          nodeId: kActivityWorkoutClaimNodeId,
          periodKey: key,
        ),
        RewardGrantEvent(
          eventKey:
              'reward|$kActivityWorkoutClaimNodeId|$ordinal|$key|grant',
          timestamp: now,
          nodeId: kActivityWorkoutClaimNodeId,
          rewardOrdinal: ordinal,
          rewardKind: RewardGrantKind.xp,
          periodKey: key,
          xpAmount: scaledXp,
          levelAtGrant: currentLevel,
          multiplierAtGrant: multiplier,
        ),
      ]);
      _ledger = await _repository.loadLedger();
      _lastEvaluatedAt = now;
      _recomputeStreaks();
      AppLog.app.info(
        'claimActivity: granted $scaledXp XP for "${activity.type}" key=$key',
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      AppLog.app.warn('claimActivity: failed — $e');
    } finally {
      _isEvaluating = false;
      notifyListeners();
    }
    // Refresh so any level-milestone unlock crossed by this grant
    // fires its celebration on the same turn (mirrors devToolsAddXp).
    _lastEvaluatedSignature = null;
    await refresh();
  }

  // ── Daily backfill (quest screen "K vyzvednutí · 14 dní") ─────────

  /// Catalog `nodeId`s for daily goals surfaced in the backfill
  /// section, in display order. The order is also the visual priority
  /// inside an expanded day card.
  static const List<String> _kDailyGoalBackfillNodeIds = <String>[
    'daily_steps_today',
    'daily_calories_today',
    'daily_protein_today',
    'daily_carbs_today',
    'daily_fat_today',
    'daily_fiber_today',
    'daily_sleep_today',
    'daily_weight_log_today',
    'daily_activity_today',
  ];

  /// Per-day rollup across every supported daily goal + per-activity
  /// claim. Pure derivation from cached fitness / KT / goals state and
  /// the engine ledger — no engine evaluation, no I/O.
  ///
  /// Returned days run newest-first and are clamped to [joinedAt] so
  /// pre-join days are dropped. The UI can hide empty days via
  /// [DailyBackfillEntry.hasAnyContent].
  List<DailyBackfillEntry> dailyBackfillForRange({
    required DateTime startDay,
    required DateTime endDay,
  }) {
    final start = DateTime(startDay.year, startDay.month, startDay.day);
    final end = DateTime(endDay.year, endDay.month, endDay.day);
    if (start.isAfter(end)) return const [];

    final window = historicalClaimWindow;
    final join = DateTime(joinedAt.year, joinedAt.month, joinedAt.day);

    // Pre-index the ledger per nodeId + periodKey. Per-day lookups
    // collapse to O(1) instead of scanning the entire claim / grant
    // lists for every (day × goal) cell.
    final claimedKeys = _claimedDailyGoalKeysByNodeId();
    final grantsByKey = _xpGrantsByNodeIdAndPeriodKey();

    // Pre-group activities by day so each entry can pull its list
    // without re-filtering all of fitness.activities.
    final activitiesByDay = <String, List<ActivityRecord>>{};
    final fitness = _subscribedFitness;
    if (fitness != null) {
      for (final a in fitness.activities) {
        final k = _periodDayKey(a.startTime);
        (activitiesByDay[k] ??= []).add(a);
      }
    }

    // Pre-group quest offerings by day so each entry can resolve its
    // daily-section quests with one map lookup.
    final offeringsByDay = <String, List<QuestOfferedEvent>>{};
    final ledger = _ledger;
    if (ledger != null) {
      for (final e in ledger.questOfferings) {
        (offeringsByDay[e.dayKey] ??= []).add(e);
      }
    }

    // Pre-index lifetime claims so quest-claim lookups don't scan the
    // whole ledger per cell. Today-scope claims still resolve via
    // [claimedKeys] (keyed by periodKey).
    final lifetimeClaims = <String>{};
    final lifetimeGrants = <String, int>{};
    if (ledger != null) {
      for (final e in ledger.nodeClaims) {
        if (e.periodKey == null) lifetimeClaims.add(e.nodeId);
      }
      for (final e in ledger.rewardGrants) {
        if (e.rewardKind != RewardGrantKind.xp) continue;
        if (e.periodKey != null) continue;
        final xp = e.xpAmount;
        if (xp == null) continue;
        lifetimeGrants.putIfAbsent(e.nodeId, () => xp);
      }
    }

    final out = <DailyBackfillEntry>[];
    var cursor = end;
    while (!cursor.isBefore(start)) {
      final day = DateTime(cursor.year, cursor.month, cursor.day);
      if (day.isBefore(join)) break;
      final dKey = _periodDayKey(day);
      final inWindow = window.contains(day);

      final goals = <DailyGoalClaimItem>[];
      for (final nodeId in _kDailyGoalBackfillNodeIds) {
        final item = _evaluateDailyGoal(
          nodeId: nodeId,
          day: day,
          dayKey: dKey,
          isWithinWindow: inWindow,
          claimedKeysByNode: claimedKeys,
          grantsByKey: grantsByKey,
        );
        if (item != null) goals.add(item);
      }

      final quests = <DailyQuestClaimItem>[];
      for (final offering in offeringsByDay[dKey] ?? const []) {
        final item = _evaluateDailyQuest(
          nodeId: offering.nodeId,
          dayKey: dKey,
          isWithinWindow: inWindow,
          claimedKeysByNode: claimedKeys,
          grantsByKey: grantsByKey,
          lifetimeClaims: lifetimeClaims,
          lifetimeGrants: lifetimeGrants,
        );
        if (item != null) quests.add(item);
      }

      final dayActivities =
          activitiesByDay[dKey] ?? const <ActivityRecord>[];
      final acts = [
        for (final a in dayActivities) activityClaim(a),
      ]..sort((a, b) => b.record.startTime.compareTo(a.record.startTime));

      out.add(DailyBackfillEntry(
        date: day,
        isWithinWindow: inWindow,
        dailyGoals: goals,
        dailyQuests: quests,
        activities: acts,
      ));
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return out;
  }

  /// Player-initiated retroactive claim on one daily goal for one
  /// specific day. Writes the full 4-event sequence the engine emits
  /// for a same-day claim — `ObjectiveCompletionEvent`,
  /// `NodeCompletionEvent`, `NodeClaimEvent`, `RewardGrantEvent` —
  /// keyed by `periodKey = "yyyy-MM-dd"`. This keeps the ledger shape
  /// consistent so any `RewardCountMetric` achievement that counts
  /// past completions picks up the increment.
  ///
  /// No-op when: another evaluation is in flight, the node is not a
  /// known daily-goal node, the goal wasn't actually met that day,
  /// the day is outside [historicalClaimWindow], or the day is
  /// already claimed.
  Future<void> claimDailyGoal({
    required String nodeId,
    required DateTime day,
  }) async {
    if (_isEvaluating) return;
    if (!_kDailyGoalBackfillNodeIds.contains(nodeId)) return;

    final normalisedDay = DateTime(day.year, day.month, day.day);
    final window = historicalClaimWindow;
    if (!window.contains(normalisedDay)) return;

    final dayKey = _periodDayKey(normalisedDay);
    final claimedKeys = _claimedDailyGoalKeysByNodeId();
    if (claimedKeys[nodeId]?.contains(dayKey) ?? false) return;

    final node = ProgressionEntryCatalog.definitionForId(nodeId);
    if (node is! Quest) return;
    final objectiveId = node.objectiveId;
    final objective = objectiveById(objectiveId);
    if (objective == null) return;

    final goals = _subscribedGoals;
    final fitness = _subscribedFitness;
    final kt = _subscribedNutrition;
    final spec = _dailyGoalData(
      nodeId: nodeId,
      day: normalisedDay,
      fitness: fitness,
      kt: kt,
      goals: goals,
    );
    if (spec == null || !spec.hasData) return;
    final isMet = _objectiveSatisfied(
      actual: spec.actual,
      target: spec.target,
      operator: objective.operator,
      tolerance: objective.toleranceRatio,
    );
    if (!isMet) return;

    final baseXp = _baseXpForNode(node);
    if (baseXp <= 0) return;
    final currentLevel = level;
    final scaledXp = _levelPolicy.scaledRewardXp(
      baseXp: baseXp,
      level: currentLevel,
    );
    final multiplier = _levelPolicy.rewardMultiplierForLevel(currentLevel);
    final now = _engineNow();
    final ordinal = _ledger?.rewardGrants.length ?? 0;

    _isEvaluating = true;
    notifyListeners();
    try {
      await _repository.appendEvents([
        ObjectiveCompletionEvent(
          eventKey: 'objective|$objectiveId|$dayKey|completed',
          timestamp: now,
          objectiveId: objectiveId,
          actualValue: spec.actual,
          periodKey: dayKey,
        ),
        NodeCompletionEvent(
          eventKey: 'node|$nodeId|$dayKey|complete',
          timestamp: now,
          nodeId: nodeId,
          periodKey: dayKey,
        ),
        NodeClaimEvent(
          eventKey: 'node|$nodeId|$dayKey|claim',
          timestamp: now,
          nodeId: nodeId,
          periodKey: dayKey,
        ),
        RewardGrantEvent(
          eventKey: 'reward|$nodeId|$ordinal|$dayKey|grant',
          timestamp: now,
          nodeId: nodeId,
          rewardOrdinal: ordinal,
          rewardKind: RewardGrantKind.xp,
          periodKey: dayKey,
          xpAmount: scaledXp,
          levelAtGrant: currentLevel,
          multiplierAtGrant: multiplier,
        ),
      ]);
      _ledger = await _repository.loadLedger();
      _lastEvaluatedAt = now;
      _recomputeStreaks();
      AppLog.app.info(
        'claimDailyGoal: granted $scaledXp XP for $nodeId on $dayKey',
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      AppLog.app.warn('claimDailyGoal: failed — $e');
    } finally {
      _isEvaluating = false;
      notifyListeners();
    }
    _lastEvaluatedSignature = null;
    await refresh();
  }

  /// Retroactive claim on a daily-section quest (daily challenge,
  /// combo chain step, or chapter side quest) that was offered on
  /// [day]. Parallels [claimDailyGoal] for daily-goal atoms — both
  /// bypass the engine's standard `claim` flow and write the four
  /// canonical ledger events directly so the claim is correctly
  /// associated with the historical day.
  ///
  /// `periodKey` follows the bound objective's scope: TodayScope
  /// nodes (daily challenges after Phase 2) anchor on `yyyy-MM-dd`,
  /// LifetimeScope nodes (combo chain steps, side quests) write null
  /// so the once-and-done semantics hold.
  ///
  /// No-op when: another evaluation is in flight, the node isn't a
  /// claimable quest, the day is outside [historicalClaimWindow], no
  /// [QuestOfferedEvent] exists for (nodeId, day), or the node was
  /// already claimed for that period.
  Future<void> claimDailyQuest({
    required String nodeId,
    required DateTime day,
  }) async {
    if (_isEvaluating) return;

    final normalisedDay = DateTime(day.year, day.month, day.day);
    final window = historicalClaimWindow;
    if (!window.contains(normalisedDay)) return;

    final dayKey = _periodDayKey(normalisedDay);
    final ledger = _ledger;
    if (ledger == null) return;

    // Sanity guard: only claim quests that were actually offered on
    // this day. Prevents UI bugs from forging claims on quests the
    // rotation never picked.
    final offeringExists = ledger.questOfferings.any(
      (e) => e.nodeId == nodeId && e.dayKey == dayKey,
    );
    if (!offeringExists) return;

    final node = ProgressionEntryCatalog.definitionForId(nodeId);
    if (node is! Quest) return;
    if (node.claimPolicy != ClaimPolicy.manual) return;
    final objective = objectiveById(node.objectiveId);
    if (objective == null) return;

    // periodKey + eventKey shape mirror what the engine writes for
    // a live claim of the same scope.
    final scope = objective.scope;
    String? periodKey;
    String suffix;
    if (scope is TodayScope) {
      periodKey = dayKey;
      suffix = '|$dayKey';
    } else if (scope is LifetimeScope) {
      periodKey = null;
      suffix = '';
    } else {
      // Other scopes (ThisWeek / Range / Stretch) aren't expected on
      // daily-section nodes today; bail rather than guess.
      return;
    }

    final claimKey = 'node|$nodeId$suffix|claim';
    if (ledger.hasEventKey(claimKey)) return;

    final baseXp = _baseXpForNode(node);
    if (baseXp <= 0) return;
    final currentLevel = level;
    final scaledXp = _levelPolicy.scaledRewardXp(
      baseXp: baseXp,
      level: currentLevel,
    );
    final multiplier = _levelPolicy.rewardMultiplierForLevel(currentLevel);
    final now = _engineNow();
    final ordinal = ledger.rewardGrants.length;
    final actualValue = objectiveActualValue(node.objectiveId);

    _isEvaluating = true;
    notifyListeners();
    try {
      await _repository.appendEvents([
        ObjectiveCompletionEvent(
          eventKey: 'objective|${node.objectiveId}$suffix|completed',
          timestamp: now,
          objectiveId: node.objectiveId,
          actualValue: actualValue,
          periodKey: periodKey,
        ),
        NodeCompletionEvent(
          eventKey: 'node|$nodeId$suffix|complete',
          timestamp: now,
          nodeId: nodeId,
          periodKey: periodKey,
        ),
        NodeClaimEvent(
          eventKey: claimKey,
          timestamp: now,
          nodeId: nodeId,
          periodKey: periodKey,
        ),
        RewardGrantEvent(
          eventKey: 'reward|$nodeId|$ordinal$suffix|grant',
          timestamp: now,
          nodeId: nodeId,
          rewardOrdinal: ordinal,
          rewardKind: RewardGrantKind.xp,
          periodKey: periodKey,
          xpAmount: scaledXp,
          levelAtGrant: currentLevel,
          multiplierAtGrant: multiplier,
        ),
      ]);
      _ledger = await _repository.loadLedger();
      _lastEvaluatedAt = now;
      _recomputeStreaks();
      AppLog.app.info(
        'claimDailyQuest: granted $scaledXp XP for $nodeId on $dayKey '
        '(scope=${scope.runtimeType})',
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      AppLog.app.warn('claimDailyQuest: failed — $e');
    } finally {
      _isEvaluating = false;
      notifyListeners();
    }
    _lastEvaluatedSignature = null;
    await refresh();
  }

  // ── Daily-backfill helpers ────────────────────────────────────────

  String _periodDayKey(DateTime t) {
    final m = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    return '${t.year}-$m-$d';
  }

  Map<String, Set<String>> _claimedDailyGoalKeysByNodeId() {
    final l = _ledger;
    if (l == null) return const {};
    final out = <String, Set<String>>{};
    for (final e in l.nodeClaims) {
      final pk = e.periodKey;
      if (pk == null) continue;
      (out[e.nodeId] ??= <String>{}).add(pk);
    }
    return out;
  }

  Map<String, Map<String, int>> _xpGrantsByNodeIdAndPeriodKey() {
    final l = _ledger;
    if (l == null) return const {};
    final out = <String, Map<String, int>>{};
    for (final e in l.rewardGrants) {
      if (e.rewardKind != RewardGrantKind.xp) continue;
      final pk = e.periodKey;
      final xp = e.xpAmount;
      if (pk == null || xp == null) continue;
      final m = out[e.nodeId] ??= <String, int>{};
      m.putIfAbsent(pk, () => xp);
    }
    return out;
  }

  DailyGoalClaimItem? _evaluateDailyGoal({
    required String nodeId,
    required DateTime day,
    required String dayKey,
    required bool isWithinWindow,
    required Map<String, Set<String>> claimedKeysByNode,
    required Map<String, Map<String, int>> grantsByKey,
  }) {
    final node = ProgressionEntryCatalog.definitionForId(nodeId);
    if (node is! Quest) return null;
    final objective = objectiveById(node.objectiveId);
    if (objective == null) return null;

    final spec = _dailyGoalData(
      nodeId: nodeId,
      day: day,
      fitness: _subscribedFitness,
      kt: _subscribedNutrition,
      goals: _subscribedGoals,
    );
    if (spec == null) return null;

    final isMet = _objectiveSatisfied(
      actual: spec.actual,
      target: spec.target,
      operator: objective.operator,
      tolerance: objective.toleranceRatio,
    );
    final isClaimed =
        claimedKeysByNode[nodeId]?.contains(dayKey) ?? false;
    final baseXp = _baseXpForNode(node);
    // Claimed pills freeze on the historically granted amount.
    final xp = isClaimed
        ? (grantsByKey[nodeId]?[dayKey] ??
            _levelPolicy.scaledRewardXp(baseXp: baseXp, level: level))
        : _levelPolicy.scaledRewardXp(baseXp: baseXp, level: level);

    return DailyGoalClaimItem(
      node: node,
      domain: objective.domain ?? ProgressionDomain.steps,
      actualValue: spec.actual,
      targetValue: spec.target,
      valueUnit: spec.unit,
      isMet: isMet,
      previewXp: xp,
      isClaimed: isClaimed,
      isWithinWindow: isWithinWindow,
      hasData: spec.hasData,
    );
  }

  /// Resolves the backfill view model for one daily-section quest
  /// offered on [dayKey]. Reads the bound objective's scope to know
  /// whether to look up the claim by periodKey (TodayScope) or by
  /// the lifetime-claim set (LifetimeScope).
  DailyQuestClaimItem? _evaluateDailyQuest({
    required String nodeId,
    required String dayKey,
    required bool isWithinWindow,
    required Map<String, Set<String>> claimedKeysByNode,
    required Map<String, Map<String, int>> grantsByKey,
    required Set<String> lifetimeClaims,
    required Map<String, int> lifetimeGrants,
  }) {
    final node = ProgressionEntryCatalog.definitionForId(nodeId);
    if (node is! Quest) return null;
    final objective = objectiveById(node.objectiveId);
    if (objective == null) return null;
    final scope = objective.scope;

    bool isClaimed;
    int? grantedXp;
    if (scope is TodayScope) {
      isClaimed = claimedKeysByNode[nodeId]?.contains(dayKey) ?? false;
      grantedXp = grantsByKey[nodeId]?[dayKey];
    } else if (scope is LifetimeScope) {
      isClaimed = lifetimeClaims.contains(nodeId);
      grantedXp = lifetimeGrants[nodeId];
    } else {
      // Other scopes (ThisWeek / Range / Stretch) aren't expected on
      // daily-section nodes today — surface nothing rather than
      // guess at the right periodKey.
      return null;
    }

    // Engine flags come from the most recent resolution. When no
    // resolution exists yet (cold-start) the quest reads as
    // incomplete / unavailable — that's fine for the backfill view,
    // which only acts on isClaimed + isClaimable anyway.
    final progress = _findQuestProgress(nodeId);
    final isCompleted = progress?.isCompleted ?? false;
    final isAvailableForClaim = progress?.isAvailableForClaim ?? false;

    final baseXp = _baseXpForNode(node);
    final currentLevel = level;
    final xp = isClaimed
        ? (grantedXp ??
            _levelPolicy.scaledRewardXp(
              baseXp: baseXp,
              level: currentLevel,
            ))
        : _levelPolicy.scaledRewardXp(baseXp: baseXp, level: currentLevel);

    return DailyQuestClaimItem(
      node: node,
      domain: objective.domain ?? ProgressionDomain.steps,
      isCompleted: isCompleted,
      isAvailableForClaim: isAvailableForClaim,
      previewXp: xp,
      isClaimed: isClaimed,
      isWithinWindow: isWithinWindow,
    );
  }

  /// Looks up an [EngineQuestProgress] for a node id by scanning the
  /// most recent resolution. O(N) over visible quests; the backfill
  /// list calls this a handful of times per day so a map cache isn't
  /// worth the bookkeeping.
  EngineQuestProgress? _findQuestProgress(String nodeId) {
    final result = _lastResult;
    if (result == null) return null;
    for (final q in allDailyQuests) {
      if (q.nodeId == nodeId) return q;
    }
    for (final bucket in [
      QuestDisplayBucket.dailyChallenge,
      QuestDisplayBucket.chapterSideQuest,
      QuestDisplayBucket.combo,
    ]) {
      for (final q in _questsForBucket(bucket)) {
        if (q.nodeId == nodeId) return q;
      }
    }
    return null;
  }

  /// Sum of base XP across every `XpReward` in [node]'s reward list.
  /// `BonusXpReward`s are skipped — they depend on time-of-day
  /// conditions like `CompletedBeforeHour(12)` which don't translate
  /// to retroactive claims fired now for a past day.
  int _baseXpForNode(Quest node) {
    var sum = 0;
    for (final r in node.rewards) {
      if (r is XpReward) sum += r.amount;
    }
    return sum;
  }

  /// Inlined copy of [ObjectiveEvaluator]'s operator dispatch. Pure
  /// helper so the backfill list can decide "was this objective met
  /// on day X" without spinning up a full engine evaluation pass.
  bool _objectiveSatisfied({
    required double actual,
    required double target,
    required ObjectiveOperator operator,
    required double tolerance,
  }) {
    switch (operator) {
      case ObjectiveOperator.atLeast:
        return actual >= target;
      case ObjectiveOperator.atMost:
        return actual <= target;
      case ObjectiveOperator.betweenInclusive:
        // Daily-goal nodes don't use `betweenInclusive` today (it
        // ships with `upperTargetValue` on the objective which we
        // don't read here). Treat as atLeast as a safe fallback.
        return actual >= target;
      case ObjectiveOperator.withinTolerance:
        final lower = target - (target * tolerance);
        final upper = target + (target * tolerance);
        return actual >= lower && actual <= upper;
      case ObjectiveOperator.atLeastWithTolerance:
        final lower = target - (target * tolerance);
        return actual >= lower;
    }
  }

  /// Per-`nodeId` data resolver — pulls the player's recorded value
  /// for [day] from the relevant cached provider and the goal target
  /// from the historized goal where available (steps / kcal /
  /// protein / sleep). Carbs / fat / fiber goals are not yet
  /// historized; we fall back to the current goal value with a known
  /// loss of accuracy when the player has changed those goals
  /// recently.
  _DailyGoalSpec? _dailyGoalData({
    required String nodeId,
    required DateTime day,
    required FitnessProvider? fitness,
    required KalorickeTabulkyProvider? kt,
    required GoalsProvider? goals,
  }) {
    if (goals == null) return null;
    switch (nodeId) {
      case 'daily_steps_today':
        if (fitness == null) return null;
        final actual = fitness.stepsForDate(day).toDouble();
        final target = goals.progressionDailyStepsForDate(day).toDouble();
        return _DailyGoalSpec(
          actual: actual,
          target: target,
          unit: DailyGoalValueUnit.count,
          hasData: actual > 0,
        );
      case 'daily_calories_today':
        if (kt == null) return null;
        final n = kt.nutritionForDate(day);
        return _DailyGoalSpec(
          actual: n?.calories ?? 0,
          target: goals.progressionDailyCaloriesForDate(day),
          unit: DailyGoalValueUnit.count,
          hasData: n != null,
        );
      case 'daily_protein_today':
        if (kt == null) return null;
        final n = kt.nutritionForDate(day);
        return _DailyGoalSpec(
          actual: n?.protein ?? 0,
          target: goals.progressionDailyProteinForDate(day),
          unit: DailyGoalValueUnit.count,
          hasData: n != null,
        );
      case 'daily_carbs_today':
        if (kt == null) return null;
        final n = kt.nutritionForDate(day);
        return _DailyGoalSpec(
          actual: n?.carbs ?? 0,
          target: goals.progressionDailyCarbsForDate(day),
          unit: DailyGoalValueUnit.count,
          hasData: n != null,
        );
      case 'daily_fat_today':
        if (kt == null) return null;
        final n = kt.nutritionForDate(day);
        return _DailyGoalSpec(
          actual: n?.fat ?? 0,
          target: goals.progressionDailyFatForDate(day),
          unit: DailyGoalValueUnit.count,
          hasData: n != null,
        );
      case 'daily_fiber_today':
        if (kt == null) return null;
        final n = kt.nutritionForDate(day);
        return _DailyGoalSpec(
          actual: n?.fiber ?? 0,
          target: goals.progressionDailyFiberForDate(day),
          unit: DailyGoalValueUnit.count,
          hasData: n != null,
        );
      case 'daily_sleep_today':
        if (fitness == null) return null;
        final s = fitness.sleepForDate(day);
        final minutes = (s?.totalDuration.inMinutes ?? 0).toDouble();
        final target = goals.progressionSleepHoursForDate(day) * 60;
        return _DailyGoalSpec(
          actual: minutes,
          target: target,
          unit: DailyGoalValueUnit.minutes,
          hasData: s != null,
        );
      case 'daily_weight_log_today':
        if (fitness == null) return null;
        final w = fitness.weightForDate(day);
        return _DailyGoalSpec(
          actual: w != null ? 1 : 0,
          target: 1,
          unit: DailyGoalValueUnit.flag,
          // A "weight logged" goal is always actionable — even on a
          // day the player skipped, the locked pill reads "missed
          // this one" rather than no-op.
          hasData: true,
        );
      case 'daily_activity_today':
        if (fitness == null) return null;
        var minutes = 0;
        for (final a in fitness.activities) {
          final aDay =
              DateTime(a.startTime.year, a.startTime.month, a.startTime.day);
          if (aDay == day) minutes += a.duration.inMinutes;
        }
        return _DailyGoalSpec(
          actual: minutes.toDouble(),
          // Matches the hardcoded 30-min target in activity_content.
          target: 30,
          unit: DailyGoalValueUnit.minutes,
          hasData: minutes > 0,
        );
    }
    return null;
  }

  /// Devtools — override the persisted join date. Useful when
  /// testing retroactive claim windows on activities older than the
  /// real install date (e.g. backfilling 5 days into the past to
  /// verify the 7-day window edge). Pass `null` to clear the prefs
  /// key entirely; the next [_resolveJoinedAt] will reseed from
  /// `min(now, earliestLedgerEvent)` as on a fresh install.
  ///
  /// Writes through to SharedPreferences immediately so a hot-restart
  /// preserves the override.
  Future<void> devToolsSetJoinedAt(DateTime? date) async {
    final prefs = await SharedPreferences.getInstance();
    if (date == null) {
      await prefs.remove(_prefsJoinedAtKey);
      _joinedAtCache = await _resolveJoinedAt(_ledger);
    } else {
      await prefs.setString(_prefsJoinedAtKey, date.toIso8601String());
      _joinedAtCache = date;
    }
    AppLog.app.info('progression: devToolsSetJoinedAt $_joinedAtCache');
    notifyListeners();
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
            timestamp: _engineNow(),
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

  /// Devtools — append a synthetic XP grant on top of existing
  /// ledger state (additive, unlike [devToolsSetTotalXp] which
  /// wipes first). Triggers a downstream evaluation so any new
  /// level milestone fires its celebration.
  Future<void> devToolsAddXp(int amount) async {
    if (amount <= 0) return;
    final repo = _repository;
    if (repo is! ProgressionEngineLocalRepository) return;

    _isEvaluating = true;
    notifyListeners();
    try {
      final ordinal = (_ledger?.rewardGrants.length ?? 0);
      await repo.appendEvents([
        RewardGrantEvent(
          eventKey: 'reward|devtools_xp_add|$ordinal|grant',
          timestamp: _engineNow(),
          nodeId: 'devtools_xp_add',
          rewardOrdinal: ordinal,
          rewardKind: RewardGrantKind.xp,
          xpAmount: amount,
          levelAtGrant: level,
          multiplierAtGrant: 1.0,
        ),
      ]);
      _ledger = await _repository.loadLedger();
      _recomputeStreaks();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isEvaluating = false;
      notifyListeners();
    }
    await refresh();
  }

  /// Devtools — set the player's level by deriving the matching
  /// total XP via [ProgressionLevelPolicy] and calling
  /// [devToolsSetTotalXp].
  Future<void> devToolsSetLevel(int targetLevel) async {
    const policy = ProgressionLevelPolicy();
    final safe = targetLevel < 1 ? 1 : targetLevel;
    final xp = policy.xpRequiredForLevel(safe);
    await devToolsSetTotalXp(xp);
  }

  /// Devtools — force a node into the "completed" state. For
  /// manual-claim quests (e.g. daily quests) we inject an
  /// `ObjectiveCompletionEvent` + `NodeClaimEvent` with the proper
  /// per-period key and let the engine's next evaluation generate
  /// the `NodeCompletionEvent` + reward grants naturally (so the
  /// celebration fires once). For automatic-claim nodes
  /// (achievements, level milestones) we inject the
  /// `NodeCompletionEvent` + reward grants directly since there is
  /// no "claim" step in their flow.
  ///
  /// Daily quests live on a `TodayScope` objective whose `periodKey`
  /// is today's `yyyy-MM-dd` date; the resolver short-circuits to
  /// `completed` only when ledger event keys embed that period, so
  /// `null`-keyed completions silently miss and the quest stays
  /// "available" forever. This method does the period math the
  /// engine does internally (see [ObjectiveEvaluator._periodKey]).
  /// Thin delegate over [ProgressionEngine.simulateClaim] — the engine
  /// owns the ledger-write surface, the provider just supplies the
  /// freshest input + level for XP scaling and runs the standard
  /// two-pass cascade so combo steps gated on
  /// `TodayCompletionsAmongMetric` see the new completion on the
  /// same turn.
  Future<void> devToolsForceCompleteNode(String nodeId) async {
    final node = ProgressionEntryCatalog.definitionForId(nodeId);
    if (node == null) return;
    final source = _source;
    if (source == null) return;
    final input = currentInput;
    if (input == null) return;

    _isEvaluating = true;
    notifyListeners();
    try {
      final result = await _engine.simulateClaim(
        nodeId: nodeId,
        input: input,
        levelAtGrant: level,
        catalogContext: source.currentContext(),
      );
      _lastResult = result;
      _ledger = await _repository.loadLedger();
      _recomputeStreaks();
      if (!result.isEmpty) _pendingCelebrations.add(result);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isEvaluating = false;
      notifyListeners();
    }
    // Two-pass cascade — see claimNode for the rationale: the second
    // refresh rebuilds currentInput from the now-updated ledger so
    // any combo step whose objective is TodayCompletionsAmongMetric
    // picks up the new node-id on this turn.
    _lastEvaluatedSignature = null;
    await refresh();
  }

  /// Devtools — wipe the local ledger. No-op when the bound
  /// repository is not the local Isar variant.
  /// Thin delegate over [ProgressionEngine.simulateObjectiveMet].
  /// The chapter-step devtools shortcut routes through this so the
  /// chapter card surfaces the normal "Vyzvednout XP" claim pill
  /// after the nudge — the player taps through the real claim flow
  /// (XP grant + celebration) instead of devtools finalising the
  /// whole transaction silently.
  Future<void> devToolsMarkObjectiveMet(String nodeId) async {
    final node = ProgressionEntryCatalog.definitionForId(nodeId);
    if (node == null) return;
    final source = _source;
    if (source == null) return;
    final input = currentInput;
    if (input == null) return;

    _isEvaluating = true;
    notifyListeners();
    try {
      final result = await _engine.simulateObjectiveMet(
        nodeId: nodeId,
        input: input,
        catalogContext: source.currentContext(),
      );
      _lastResult = result;
      _ledger = await _repository.loadLedger();
      _recomputeStreaks();
      if (!result.isEmpty) _pendingCelebrations.add(result);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isEvaluating = false;
      notifyListeners();
    }
    _lastEvaluatedSignature = null;
    await refresh();
  }

  /// Devtools-only: shifts the engine's notion of "today" forward by
  /// one day, then re-evaluates. After this call:
  ///
  /// * the daily-rotation hash picks a new pair (yesterday's quests
  ///   are no longer in the slot — they were "yesterday's"),
  /// * combo chain steps gated by `NodeCompletedBeforeToday` open up
  ///   because yesterday's claim now sits strictly before the new
  ///   "today" boundary,
  /// * period keys roll forward — yesterday's daily completions
  ///   retire from the "completed today" set, leaving fresh slots
  ///   for new claims,
  /// * `evaluatedAt` on the next engine pass reflects the shifted
  ///   day so chapter-side-quest progress can resume tomorrow.
  ///
  /// Production never calls this — the offset stays at 0 unless
  /// devtools touches it.
  Future<void> devToolsAdvanceDay() async {
    _devDayOffset += 1;
    _lastEvaluatedSignature = null;
    await refresh();
  }

  /// Devtools-only: snaps the day offset back to 0. Used to return
  /// to wall-clock behaviour after testing future-day rotation.
  Future<void> devToolsResetDayOffset() async {
    if (_devDayOffset == 0) return;
    _devDayOffset = 0;
    _lastEvaluatedSignature = null;
    await refresh();
  }

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
      _lastEvaluatedAt = _mostRecentLedgerTimestamp(_ledger);
      _joinedAtCache = await _resolveJoinedAt(_ledger);
      _recomputeStreaks();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _scheduleMidnightRefresh();
      notifyListeners();
    }
  }

  /// Wall-clock midnight watcher. Refreshes the engine right after
  /// 00:00 local time so day-scoped rotations roll forward without
  /// waiting for the next input-source change.
  ///
  /// Without this, an app left open across midnight kept yesterday's
  /// `QuestOfferedEvent`s pinning the daily slot until the user
  /// touched something that triggered a refresh — daily challenges
  /// would visually "miss midnight" by hours.
  ///
  /// Fires once per day and re-schedules itself so a single instance
  /// keeps the rollover alive forever; `dispose()` cancels the timer
  /// so widget trees rebuilding the provider don't leak.
  Timer? _midnightTimer;

  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    // 5-second buffer past midnight so any wall-clock drift between
    // Timer and DateTime.now() doesn't fire on the previous day.
    final nextMidnight = DateTime(now.year, now.month, now.day + 1, 0, 0, 5);
    final delay = nextMidnight.difference(now);
    _midnightTimer = Timer(delay, _onMidnightTick);
  }

  Future<void> _onMidnightTick() async {
    AppLog.app.info(
      'progression: midnight tick — re-evaluating daily rotation',
    );
    // Force the engine to re-run regardless of source-signature
    // staleness — the calendar day changed but no source dispatched
    // a notify, so the audit-signature gate would otherwise reject
    // the refresh.
    _lastEvaluatedSignature = null;
    try {
      await refresh();
    } finally {
      // Even if refresh threw, schedule the next tick so we don't
      // permanently abandon midnight watching.
      _scheduleMidnightRefresh();
    }
  }

  /// Reads the player's join timestamp from prefs. On first read,
  /// seeds prefs with `min(now, earliestLedgerEvent)` so existing
  /// users — whose ledger history predates this feature — get a
  /// retroactive join date that matches their actual first day in
  /// the engine, not the day this prefs key was introduced.
  ///
  /// Factory reset (`prefs.clear()`) drops this key alongside the
  /// rest of app state, which is the right behavior for a "treat
  /// this as a fresh install" reset.
  Future<DateTime> _resolveJoinedAt(LedgerSnapshot? ledger) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsJoinedAtKey);
    if (stored != null) {
      final parsed = DateTime.tryParse(stored);
      if (parsed != null) return parsed;
    }
    final now = _engineNow();
    DateTime joinedAt = now;
    if (ledger != null) {
      for (final e in ledger.all) {
        if (e.timestamp.isBefore(joinedAt)) joinedAt = e.timestamp;
      }
    }
    await prefs.setString(_prefsJoinedAtKey, joinedAt.toIso8601String());
    AppLog.app.info(
      'progression: seeded joinedAt=$joinedAt',
    );
    return joinedAt;
  }

  /// Newest event timestamp across the ledger's reward grants and node
  /// completions. Lets [_hydrate] seed [lastEvaluatedAt] with something
  /// meaningful after an app restart instead of waiting for the next
  /// live evaluation.
  DateTime? _mostRecentLedgerTimestamp(LedgerSnapshot? ledger) {
    if (ledger == null) return null;
    DateTime? best;
    void consider(DateTime t) {
      if (best == null || t.isAfter(best!)) best = t;
    }
    for (final g in ledger.rewardGrants) {
      consider(g.timestamp);
    }
    for (final e in ledger.nodeCompletions) {
      consider(e.timestamp);
    }
    return best;
  }

  int _totalClaimedXp(LedgerSnapshot ledger) =>
      Player.totalXpFromGrants(ledger.rewardGrants);

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
    final locked = lockedNodeIds;

    final out = <EngineQuestProgress>[];
    for (final node in _nodeCatalog.build()) {
      if (node is! Quest) continue;
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
      // Period-aware completion: a daily quest claimed yesterday
      // should read as "not yet done today", and the same goes for
      // weekly quests across the week boundary. The flat
      // `completedNodeIds` set ignores periodKey and would keep
      // every once-completed daily quest pinned to the "done" state
      // forever, which is exactly the "auto-completed after advance
      // day" symptom the user reported. Use the period-keyed event
      // key from the outcome so the UI honours the actual period.
      final completionKey = ProgressionNodeResolver.completionEventKey(
        node.id,
        outcome?.periodKey,
      );
      final isCompleted = _ledger?.hasEventKey(completionKey) ?? false;
      final isAvailable = available.contains(node.id);

      // Always derive the bar from the live actual/target ratio.
      // The earlier `isCompleted → 1.0` shortcut backfired with the
      // devtools force-complete shortcut (and any future flow that
      // marks a node done without seeding matching metric data):
      // the card displayed "0 / 8 h" but the bar was full. Drop the
      // shortcut so the bar always agrees with the label.
      final double progress = target <= 0
          ? (isCompleted ? 1.0 : 0.0)
          : (actual / target).clamp(0.0, 1.0).toDouble();

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
        // Sleep objectives store the target in minutes. Without
        // this hint the UI shows "0 / 480" for the daily sleep
        // quest; the formatter renders "0 / 8 h" when the unit is
        // minutes.
        valueUnit: objective.metric is SleepMinutesMetric
            ? EngineQuestValueUnit.minutes
            : EngineQuestValueUnit.count,
        isLockedByConditions: locked.contains(node.id),
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
  final List<ProgressionEntry> companions;

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
  final List<ProgressionEntry> companions;
  final DateTime lastEventAt;
  final int totalXpClaimed;
  final int pendingXp;
  final bool hasClaimable;

  bool get isChain => chainQuests.length > 1;
}

/// A quest node paired with its most recent completion timestamp.
/// Built by [ProgressionEngineProvider.allCompletedQuests] — feeds the
/// journey event feed (V2 analog of legacy
/// `ProgressionProvider.completedQuests`).
@immutable
class EngineQuestCompletion {
  const EngineQuestCompletion({
    required this.node,
    required this.completedAt,
  });

  final Quest node;
  final DateTime completedAt;

  String get nodeId => node.id;
}

/// Synthetic fallback used when a quest references an objective that
/// is no longer in the catalog (catalog drift / stale build). Returns
/// a zero-target objective so progress falls back to 0 instead of
/// throwing.
Objective objectiveCatalogFallback(String id) => Objective(
      id: ObjectiveId(id),
      metric: const StepsMetric(),
      scope: const TodayScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 0,
      debugLabel: 'fallback for missing objective',
    );

/// Compact result tuple from
/// [ProgressionEngineProvider._dailyGoalData] — the player's measured
/// value, the goal target, the display unit, and whether the source
/// has any record for that day. Kept private to the provider since no
/// caller outside `dailyBackfillForRange` / `claimDailyGoal` reads it.
class _DailyGoalSpec {
  const _DailyGoalSpec({
    required this.actual,
    required this.target,
    required this.unit,
    required this.hasData,
  });

  final double actual;
  final double target;
  final DailyGoalValueUnit unit;
  final bool hasData;
}
