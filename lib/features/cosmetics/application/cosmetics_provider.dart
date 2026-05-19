import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/logging/app_log.dart';
import '../../../core/result/result.dart';
import '../data/cosmetic_entitlements_source.dart';
import '../domain/cosmetic_catalog.dart';
import '../domain/cosmetic_models.dart';
import '../domain/cosmetic_reveal_evaluator.dart';
import '../domain/cosmetic_reveal_state.dart';
import '../domain/cosmetic_unlock_rule.dart';
import '../domain/cosmetic_unlock_rules.dart';
import '../domain/cosmetic_unlock_snapshot.dart';
import '../domain/inventory.dart';
import '../domain/player_cosmetic_lifecycle.dart';
import 'cosmetics_service.dart';
import 'player_cosmetic_lifecycle_service.dart';

const _log = AppLogger('COSMETICS', scope: 'provider');

/// UI-facing state holder for the cosmetics feature.
///
/// Mirrors the bind() pattern used by `SocialProvider`: a single uid is
/// bound (typically from AuthProvider in `main.dart`) and the provider
/// lazily loads state on first bind. No streams — all reads/writes are
/// Futures and listeners are notified after each completion.
///
/// Progression input flow: cosmetic unlocks are driven by
/// `ProgressionEngineProvider` via `CosmeticUnlockBridge`, which
/// translates V2 `CosmeticReward` grants into [unlock] calls and pushes
/// a [CosmeticUnlockSnapshot] for the partial-reveal UI through
/// [cacheSnapshot]. This provider does not re-evaluate achievements,
/// quests, milestones, or level rules — V2 is the source of truth for
/// progression rewards.
class CosmeticsProvider extends ChangeNotifier {
  CosmeticsProvider({
    required CosmeticsService service,
    CosmeticEntitlementsSource entitlementsSource =
        const NoopCosmeticEntitlementsSource(),
  })  : _service = service,
        _entitlementsSource = entitlementsSource;

  final CosmeticsService _service;
  final CosmeticEntitlementsSource _entitlementsSource;

  bool _isLoading = false;
  String? _currentUid;
  UserCosmeticsState? _state;
  String? _errorMessage;
  CosmeticUnlockSnapshot? _revealSnapshot;

  bool get isLoading => _isLoading;
  String? get currentUid => _currentUid;
  UserCosmeticsState? get state => _state;
  String? get errorMessage => _errorMessage;

  CosmeticsService get service => _service;

  /// Called by the progression dispatcher after each sync to enable accurate
  /// partial-reveal evaluation for level/quest/active-days conditions.
  ///
  /// Without a cached snapshot the reveal evaluator falls back to a minimal
  /// snapshot derived from owned cosmetics, which still correctly evaluates
  /// `ownsCosmetic(...)` conditions but treats level/quest counters as zero.
  ///
  /// Does **not** call [notifyListeners]: the snapshot is read on the
  /// inventory screen's next render via [computeRevealResults], and any
  /// observable change (a new unlock, a level-up grant) already flowed
  /// through [unlock] which itself notified. Firing a second notification
  /// here closes a feedback loop with [ProgressionEngineProvider] — the
  /// V2 provider listens to [CosmeticsProvider] via its proxy and would
  /// re-evaluate on the spot, which itself runs another dispatch → another
  /// snapshot → another notify → infinite cascade. Skipping the notify
  /// keeps the cache lazy: consumers see the new value when they next
  /// rebuild for an unrelated reason.
  void cacheSnapshot(CosmeticUnlockSnapshot snapshot) {
    _revealSnapshot = snapshot;
  }

  /// Returns a [CosmeticRevealResult] for every enabled catalog item.
  ///
  /// [rules] is typically [kCosmeticUnlockRules]. The method uses the last
  /// snapshot cached via [cacheSnapshot], falling back to a minimal snapshot
  /// built from owned cosmetics when no progression data has been loaded yet.
  Map<String, CosmeticRevealResult> computeRevealResults(
    List<CosmeticUnlockRule> rules,
  ) {
    final currentState = _state;
    if (currentState == null) return {};
    final ownedIds = currentState.unlocked.keys.toSet();
    final snapshot = _revealSnapshot ?? _minimalSnapshot(ownedIds);
    return CosmeticRevealEvaluator.evaluateAll(
      catalog: _service.catalog,
      rules: rules,
      snapshot: snapshot,
      ownedIds: ownedIds,
    );
  }

  static const PlayerCosmeticLifecycleService _lifecycleService =
      PlayerCosmeticLifecycleService();

  /// Build an [Inventory] read projection of every enabled cosmetic.
  ///
  /// Phase 10 surface for the cosmetic lifecycle (`docs/domain_model
  /// /migration_plan.md` §Phase 10). The widget tree calls this once
  /// per build with the engine-surfaced manually-claimable node ids
  /// (`ProgressionEngineProvider.availableNodeIds`) so the Inventory
  /// captures `CosmeticClaimable` for companions whose availability
  /// gate fired. Returns [Inventory.empty] when the provider has no
  /// loaded state yet (pre-bind / pre-first-load).
  ///
  /// Not cached: the inputs (`_state`, `_revealSnapshot`,
  /// `claimableNodeIds` from a peer provider) change with every
  /// progression dispatch, and the build is O(catalog size) — well
  /// inside the same budget as [computeRevealResults] which the
  /// inventory builds on top of. A cache layer can land later if a
  /// profiler flags it (proposal §Phase 20 JournalProjection makes
  /// caching uniform across all read projections).
  Inventory buildInventory({
    required Set<String> claimableNodeIds,
    DateTime? evaluatedAt,
  }) {
    final currentState = _state;
    if (currentState == null) return Inventory.empty;
    final revealResults = computeRevealResults(kCosmeticUnlockRules);
    return _lifecycleService.build(
      catalog: _service.catalog,
      unlocked: currentState.unlocked,
      revealResults: revealResults,
      claimableNodeIds: claimableNodeIds,
      evaluatedAt: evaluatedAt ?? DateTime.now(),
    );
  }

  /// Returns the ordered list of [Cosmetic] entries the cosmetics
  /// grid should display, with the same filter + sort policy the
  /// pre-extraction `cosmetics_screen.build()` applied inline.
  ///
  /// Phase 19 of the domain refactor moved this off the widget into
  /// the provider per proposal §7 anti-pattern #1 — `build()` must
  /// not run domain logic. The widget now reads the projection +
  /// renders cards; lifecycle-based decisions stay here.
  ///
  /// **Display policy (non-devtools).**
  ///   - Owned cosmetics always show.
  ///   - [Companion] cosmetics surface for `teased` + `claimable` too
  ///     so the player sees what's brewing.
  ///   - Frames / relics / backgrounds / emblems stay hidden until
  ///     owned (Tier-1 rewards where a locked preview would be
  ///     clutter).
  ///   - Hidden lifecycles are always culled.
  ///
  /// **Sort policy (non-devtools).**
  ///   - Sorted by lifecycle precedence: Owned < Claimable < Teased
  ///     (with progress) < Teased (no progress) < Hidden.
  ///   - Within Owned: rarity desc → unlockedAt desc → sortOrder asc
  ///     → id asc.
  ///   - Within Teased / others: by sortOrder asc.
  ///
  /// **Devtools mode** bypasses the filter (every catalog entry
  /// surfaces) and sorts by [CosmeticType] index → sortOrder.
  List<Cosmetic> displayCosmeticsForGrid({
    required Set<String> claimableNodeIds,
    required bool devTools,
    Inventory? inventory,
  }) {
    final currentState = _state;
    if (currentState == null) return const [];

    if (devTools) {
      return _service.catalog.all.toList()
        ..sort(_byTypeThenSortOrder);
    }

    final inv = inventory ??
        buildInventory(claimableNodeIds: claimableNodeIds);

    return _service.catalog.enabled
        .where((def) {
          final lifecycle = inv.byIdString(def.id)?.lifecycle;
          if (lifecycle == null) return false;
          if (lifecycle is CosmeticOwned) return true;
          if (def is Companion) {
            return lifecycle is! CosmeticHidden;
          }
          return false;
        })
        .toList()
      ..sort((a, b) => _sortByLifecycle(a, b, currentState, inv));
  }

  static int _byTypeThenSortOrder(Cosmetic a, Cosmetic b) {
    final typeRank = CosmeticType.values
        .indexOf(a.type)
        .compareTo(CosmeticType.values.indexOf(b.type));
    if (typeRank != 0) return typeRank;
    return a.sortOrder.compareTo(b.sortOrder);
  }

  static int _sortByLifecycle(
    Cosmetic a,
    Cosmetic b,
    UserCosmeticsState state,
    Inventory inventory,
  ) {
    final lifecycleA = inventory.byIdString(a.id)?.lifecycle;
    final lifecycleB = inventory.byIdString(b.id)?.lifecycle;

    final rankA = _lifecycleSortRank(lifecycleA);
    final rankB = _lifecycleSortRank(lifecycleB);
    if (rankA != rankB) return rankA.compareTo(rankB);

    if (lifecycleA is CosmeticOwned) {
      return _compareUnlockedCosmetics(a, b, state);
    }
    return a.sortOrder.compareTo(b.sortOrder);
  }

  static int _lifecycleSortRank(PlayerCosmeticLifecycle? lifecycle) {
    return switch (lifecycle) {
      CosmeticOwned() => 0,
      CosmeticClaimable() => 1,
      CosmeticTeased(:final totalConditions) when totalConditions > 0 => 2,
      CosmeticTeased() => 3,
      CosmeticHidden() => 4,
      null => 3,
    };
  }

  static int _compareUnlockedCosmetics(
    Cosmetic a,
    Cosmetic b,
    UserCosmeticsState state,
  ) {
    final rarity = b.rarity.index.compareTo(a.rarity.index);
    if (rarity != 0) return rarity;
    final unlockedAtA = state.unlocked[a.id]?.unlockedAt;
    final unlockedAtB = state.unlocked[b.id]?.unlockedAt;
    if (unlockedAtA != null && unlockedAtB != null) {
      final unlockedAt = unlockedAtB.compareTo(unlockedAtA);
      if (unlockedAt != 0) return unlockedAt;
    }
    final sortOrder = a.sortOrder.compareTo(b.sortOrder);
    if (sortOrder != 0) return sortOrder;
    return a.id.compareTo(b.id);
  }

  static CosmeticUnlockSnapshot _minimalSnapshot(Set<String> ownedIds) {
    return CosmeticUnlockSnapshot(
      level: 0,
      activeDaysCount: 0,
      completedDailyQuests: 0,
      completedWeeklyQuests: 0,
      totalCompletedQuests: 0,
      firstDailyQuestEver: false,
      firstWeeklyQuestEver: false,
      perfectDaysCount: 0,
      perfectWeeksCount: 0,
      ownedCosmeticIds: ownedIds,
    );
  }

  /// Binds (or re-binds) the provider to a uid. No-op if [uid] matches the
  /// already-bound user. Pass null on sign-out to clear state.
  ///
  /// Synchronous on purpose so it can be called from a
  /// `ChangeNotifierProxyProvider.update` callback without producing an
  /// unawaited future. The repository load is fire-and-forget; listeners
  /// are notified once it resolves.
  void bindUser(String? uid) {
    if (uid == _currentUid) return;
    _log.info('bindUser', payload: 'uid=${uid ?? "<null>"}');
    _currentUid = uid;
    _state = null;
    _errorMessage = null;
    if (uid == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    unawaited(_load(uid));
  }

  /// Reloads the bound user's state from the repository. No-op if no user is
  /// bound.
  Future<void> refresh() async {
    final uid = _currentUid;
    if (uid == null) return;
    await _load(uid);
  }

  Future<void> unlock(
    String cosmeticId, {
    required String sourceType,
    String? sourceId,
  }) async {
    final uid = _currentUid;
    if (uid == null) {
      _log.warn(
        'unlock skipped — no uid bound',
        payload: 'id=$cosmeticId source=$sourceType:${sourceId ?? "-"}',
      );
      _errorMessage = 'no_user_bound';
      notifyListeners();
      return;
    }
    final wasUnlocked = _state?.unlocked.containsKey(cosmeticId) ?? false;
    try {
      _state = await _service.unlock(
        uid,
        cosmeticId,
        sourceType: sourceType,
        sourceId: sourceId,
      );
      _errorMessage = null;
      if (!wasUnlocked) {
        _log.info(
          'unlock OK',
          payload:
              'id=$cosmeticId source=$sourceType:${sourceId ?? "-"} uid=$uid',
        );
      } else {
        _log.debug(
          'unlock no-op (already unlocked)',
          payload: 'id=$cosmeticId',
        );
      }
    } on CosmeticsException catch (error) {
      _errorMessage = error.code;
      _log.warn(
        'unlock rejected',
        payload: 'id=$cosmeticId code=${error.code} message=${error.message}',
      );
    } catch (error, st) {
      _errorMessage = error.toString();
      _log.error(
        'unlock crashed',
        payload: 'id=$cosmeticId source=$sourceType',
        err: error,
        stackTrace: st,
      );
    }
    notifyListeners();
  }

  /// DevTools: grant a single cosmetic via the manual unlock source. Idempotent.
  Future<void> debugGrantCosmetic(String cosmeticId) {
    return unlock(
      cosmeticId,
      sourceType: CosmeticUnlockSource.manual.name,
      sourceId: 'devtools',
    );
  }

  /// DevTools: grant every cosmetic in the catalog. Returns the number of
  /// items that were newly unlocked (already-unlocked items are skipped).
  Future<int> devToolsGrantAllCosmetics() async {
    final ids = CosmeticCatalog.definitions.map((d) => d.id).toList();
    var granted = 0;
    final before = state?.unlocked.length ?? 0;
    for (final id in ids) {
      await debugGrantCosmetic(id);
    }
    final after = state?.unlocked.length ?? 0;
    granted = after - before;
    return granted;
  }

  /// DevTools: revoke a single cosmetic. Clears the equipped slot if the
  /// cosmetic is currently equipped so the app never sees a locked-but-equipped
  /// state. No-op if the cosmetic isn't unlocked.
  Future<void> debugRevokeCosmetic(String cosmeticId) async {
    final uid = _currentUid;
    if (uid == null) {
      _log.warn(
        'debug revoke skipped — no uid bound',
        payload: 'id=$cosmeticId',
      );
      _errorMessage = 'no_user_bound';
      notifyListeners();
      return;
    }
    try {
      _state = await _service.revoke(uid, cosmeticId);
      _errorMessage = null;
      _log.info('debug revoke OK', payload: 'id=$cosmeticId uid=$uid');
    } on CosmeticsException catch (error) {
      _errorMessage = error.code;
      _log.warn(
        'debug revoke rejected',
        payload: 'id=$cosmeticId code=${error.code}',
      );
    } catch (error, st) {
      _errorMessage = error.toString();
      _log.error(
        'debug revoke crashed',
        payload: 'id=$cosmeticId',
        err: error,
        stackTrace: st,
      );
    }
    notifyListeners();
  }

  /// DevTools: wipe every unlock + every equipped slot for the bound user.
  /// Returns the number of unlock rows removed. Defaults are NOT re-seeded —
  /// the dev can re-grant items individually or trigger a progression sync.
  Future<int> devToolsClearAllUnlocks() async {
    final uid = _currentUid;
    if (uid == null) {
      _log.warn('devtools clear-all skipped — no uid bound');
      _errorMessage = 'no_user_bound';
      notifyListeners();
      return 0;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _service.clearAllUnlocks(uid);
      if (_currentUid != uid) return result.removedCount;
      _state = result.state;
      _log.info(
        'devtools clear-all OK',
        payload: 'uid=$uid removed=${result.removedCount}',
      );
      return result.removedCount;
    } catch (error, st) {
      _errorMessage = error.toString();
      _log.error(
        'devtools clear-all crashed',
        payload: 'uid=$uid',
        err: error,
        stackTrace: st,
      );
      return 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int> devToolsResetProgressionUnlocks() async {
    final uid = _currentUid;
    if (uid == null) {
      _log.warn('devtools progression inventory reset skipped - no uid bound');
      _errorMessage = 'no_user_bound';
      notifyListeners();
      return 0;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _service.resetProgressionUnlocks(uid);
      if (_currentUid != uid) return result.removedCount;
      _state = result.state;
      _log.info(
        'devtools progression inventory reset OK',
        payload: 'uid=$uid removed=${result.removedCount}',
      );
      return result.removedCount;
    } catch (error, st) {
      _errorMessage = error.toString();
      _log.error(
        'devtools progression inventory reset crashed',
        payload: 'uid=$uid',
        err: error,
        stackTrace: st,
      );
      return 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> equip(String cosmeticId) async {
    final uid = _currentUid;
    if (uid == null) {
      _log.warn('equip skipped — no uid bound', payload: 'id=$cosmeticId');
      _errorMessage = 'no_user_bound';
      notifyListeners();
      return;
    }
    try {
      _state = await _service.equip(uid, cosmeticId);
      _errorMessage = null;
      _log.info('equip OK', payload: 'id=$cosmeticId uid=$uid');
    } on CosmeticsException catch (error) {
      _errorMessage = error.code;
      _log.warn(
        'equip rejected',
        payload: 'id=$cosmeticId code=${error.code} message=${error.message}',
      );
    } catch (error, st) {
      _errorMessage = error.toString();
      _log.error(
        'equip crashed',
        payload: 'id=$cosmeticId',
        err: error,
        stackTrace: st,
      );
    }
    notifyListeners();
  }

  Future<void> unequip(CosmeticType type) async {
    final uid = _currentUid;
    if (uid == null) {
      _log.warn('unequip skipped — no uid bound', payload: 'type=${type.name}');
      _errorMessage = 'no_user_bound';
      notifyListeners();
      return;
    }
    try {
      _state = await _service.unequip(uid, type);
      _errorMessage = null;
      _log.info('unequip OK', payload: 'type=${type.name} uid=$uid');
    } on CosmeticsException catch (error) {
      _errorMessage = error.code;
      _log.warn(
        'unequip rejected',
        payload: 'type=${type.name} code=${error.code}',
      );
    } catch (error, st) {
      _errorMessage = error.toString();
      _log.error(
        'unequip crashed',
        payload: 'type=${type.name}',
        err: error,
        stackTrace: st,
      );
    }
    notifyListeners();
  }

  Future<void> _load(String uid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      var nextState = await _service.load(uid);
      nextState = await _applyEntitlements(uid, nextState);
      if (_currentUid != uid) return;
      _state = nextState;
      _log.info(
        'load OK',
        payload:
            'uid=$uid unlocked=${_state?.unlocked.length ?? 0} equipped=${_state?.equipped.frameId ?? "-"}',
      );
    } on CosmeticsException catch (error) {
      _errorMessage = error.code;
      _log.warn(
        'load rejected',
        payload: 'uid=$uid code=${error.code} message=${error.message}',
      );
    } catch (error, st) {
      _errorMessage = error.toString();
      _log.error(
        'load crashed',
        payload: 'uid=$uid',
        err: error,
        stackTrace: st,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserCosmeticsState> _applyEntitlements(
    String uid,
    UserCosmeticsState state,
  ) async {
    final loadResult = await _entitlementsSource.loadForUser(uid);
    final List<CosmeticEntitlement> entitlements;
    switch (loadResult) {
      case Success(value: final v):
        entitlements = v;
      case Failure(error: final e):
        // R.4 (2026-05-19): typed failure surfacing. Transient Firestore
        // outages stay at `warn` so AppLog stops bleeding red — they
        // self-heal on the next bind. Permanent failures (permission
        // denied, schema-drift validation) log at `error` so devtools /
        // crash reports surface them.
        if (e.isTransient) {
          _log.warn(
            'entitlement load skipped (transient)',
            payload: 'uid=$uid error=${e.label}',
          );
        } else {
          _log.error(
            'entitlement load skipped (permanent)',
            payload: 'uid=$uid error=${e.label}',
            err: e.originalError,
            stackTrace: e.stackTrace,
          );
        }
        return state;
    }

    var nextState = state;
    for (final entitlement in entitlements) {
      if (nextState.unlocked.containsKey(entitlement.cosmeticId)) continue;
      try {
        nextState = await _service.unlock(
          uid,
          entitlement.cosmeticId,
          sourceType: entitlement.sourceType,
          sourceId: entitlement.sourceId,
        );
        _log.info(
          'entitlement unlock OK',
          payload:
              'uid=$uid id=${entitlement.cosmeticId} source=${entitlement.sourceType}:${entitlement.sourceId ?? "-"}',
        );
      } on CosmeticsException catch (error) {
        _log.warn(
          'entitlement unlock rejected',
          payload: 'uid=$uid id=${entitlement.cosmeticId} code=${error.code}',
        );
      } catch (error, st) {
        _log.error(
          'entitlement unlock crashed',
          payload: 'uid=$uid id=${entitlement.cosmeticId}',
          err: error,
          stackTrace: st,
        );
      }
    }
    return nextState;
  }
}
