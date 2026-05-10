import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../cosmetics/application/cosmetics_provider.dart';
import '../../health_connect/application/fitness_provider.dart';
import '../../health_connect/application/goals_provider.dart';
import '../../nutrition/application/kaloricke_tabulky_provider.dart';
import '../../progression/domain/policy/level_policy.dart';
import '../data/provider_engine_input_source.dart';
import '../domain/catalog/engine_catalog_context.dart';
import '../domain/models/engine_evaluation_input.dart';
import '../domain/models/ledger_event.dart';
import '../domain/models/progression_resolution_reason.dart';
import '../domain/models/progression_resolution_result.dart';
import '../domain/repository/ledger_snapshot.dart';
import '../domain/repository/progression_engine_repository.dart';
import 'cosmetic_unlock_bridge.dart';
import 'progression_engine.dart';

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

  ProviderEngineInputSource? _source;
  String? _lastEvaluatedSignature;
  bool _evaluateQueued = false;

  ProgressionResolutionResult? _lastResult;
  LedgerSnapshot? _ledger;
  bool _isLoading = true;
  bool _isEvaluating = false;
  String? _error;

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
  /// the most recent resolution.
  Set<String> get availableNodeIds {
    final r = _lastResult;
    if (r == null) return const {};
    return {for (final a in r.availableNodes) a.nodeId};
  }

  /// Resolution results that have not yet been consumed by the
  /// celebration overlay host.
  List<ProgressionResolutionResult> get pendingCelebrations =>
      List.unmodifiable(_pendingCelebrations);

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
}
