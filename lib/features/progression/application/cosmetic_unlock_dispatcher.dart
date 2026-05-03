import '../../../core/logging/app_log.dart';
import '../../cosmetics/application/cosmetics_provider.dart';
import '../../cosmetics/domain/cosmetic_models.dart';
import '../../cosmetics/domain/cosmetic_unlock_evaluator.dart';
import '../../cosmetics/domain/cosmetic_unlock_rules.dart';
import '../domain/cosmetic_reward_table.dart';
import 'cosmetic_unlock_snapshot_extractor.dart';
import 'progression_engine.dart';

const _log = AppLogger('COSMETICS', scope: 'dispatch');

/// Three is more than enough for the depth of compound chains in the current
/// catalog (the longest is two cosmetics deep — e.g. relic_dragon_scale
/// → companion_dragonling). Bounding iteration keeps log noise + runtime in
/// check.
const int _kMaxTier2Iterations = 3;

class CosmeticUnlockDispatchItem {
  const CosmeticUnlockDispatchItem({
    required this.cosmeticId,
    required this.sourceType,
    this.sourceId,
  });

  final String cosmeticId;
  final String sourceType;
  final String? sourceId;
}

class CosmeticUnlockDispatchResult {
  const CosmeticUnlockDispatchResult({this.items = const []});

  static const empty = CosmeticUnlockDispatchResult();

  final List<CosmeticUnlockDispatchItem> items;

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
}

/// Diffs two [ProgressionEngineState] snapshots and dispatches cosmetic
/// unlocks. There are three passes per call:
///
/// 1. **Tier-1 achievement catch-up** — every currently-unlocked achievement
///    is checked against [CosmeticRewardTable]; any cosmetic not yet in the
///    player's `unlocked` map is granted. This catches up users whose
///    achievement was unlocked before a new mapping was added (or for whom
///    `previous == null` on cold start).
/// 2. **Tier-1 level catch-up** — same idea for `cosmeticsForLevel(...)`
///    iterated 1..currentLevel.
/// 3. **Tier-2 rule evaluator** — runs in a bounded fixed-point loop so
///    compound rules whose dependencies were just granted by passes 1–2
///    fire in the same dispatch.
///
/// Dependency direction: `progression` → `cosmetics`. The cosmetics feature
/// knows nothing about progression; this dispatcher is the only seam.
///
/// `unlock` is idempotent at the cosmetics repository layer (re-unlocking
/// an already-unlocked cosmetic is a no-op), so accidental double dispatch
/// is harmless.
class CosmeticUnlockDispatcher {
  CosmeticUnlockDispatcher({
    CosmeticRewardTable table = const CosmeticRewardTable(),
    CosmeticUnlockSnapshotExtractor? snapshotExtractor,
    CosmeticUnlockEvaluator? evaluator,
  })  : _table = table,
        _snapshotExtractor =
            snapshotExtractor ?? CosmeticUnlockSnapshotExtractor(),
        _evaluator = evaluator ?? CosmeticUnlockEvaluator(kCosmeticUnlockRules);

  final CosmeticRewardTable _table;
  final CosmeticUnlockSnapshotExtractor _snapshotExtractor;
  final CosmeticUnlockEvaluator _evaluator;
  CosmeticsProvider? _cosmetics;

  /// Wires the dispatcher to the live [CosmeticsProvider]. Until bound,
  /// [dispatch] is a no-op (we don't queue — unlocks earned while signed
  /// out / unbound are simply not dispatched).
  void bindCosmetics(CosmeticsProvider provider) {
    _cosmetics = provider;
  }

  Future<CosmeticUnlockDispatchResult> dispatch({
    ProgressionEngineState? previous,
    required ProgressionEngineState current,
  }) async {
    final cosmetics = _cosmetics;
    if (cosmetics == null) {
      _log.debug('dispatch skipped — no CosmeticsProvider bound');
      return CosmeticUnlockDispatchResult.empty;
    }
    if (cosmetics.currentUid == null) {
      _log.debug('dispatch skipped — no uid bound on CosmeticsProvider');
      return CosmeticUnlockDispatchResult.empty;
    }

    _log.info(
      'dispatch — checking unlocks',
      payload: 'level=${current.profile.level} uid=${cosmetics.currentUid}',
    );

    final unlockedItems = <CosmeticUnlockDispatchItem>[];

    // -- Pass 1: achievement catch-up ---------------------------------------
    final unlockedAchievements = current.achievements
        .where((a) => a.unlocked)
        .toList(growable: false);
    for (final achievement in unlockedAchievements) {
      for (final cosmeticId in _table.cosmeticsForAchievement(achievement.id)) {
        if (_alreadyUnlocked(cosmetics, cosmeticId)) continue;
        final didUnlock = await _unlock(
          cosmetics,
          cosmeticId: cosmeticId,
          sourceType: CosmeticUnlockSource.achievement.name,
          sourceId: achievement.id,
        );
        if (didUnlock) {
          unlockedItems.add(
            CosmeticUnlockDispatchItem(
              cosmeticId: cosmeticId,
              sourceType: CosmeticUnlockSource.achievement.name,
              sourceId: achievement.id,
            ),
          );
        }
      }
    }

    // -- Pass 2: level catch-up --------------------------------------------
    final currentLevel = current.profile.level;
    for (var level = 1; level <= currentLevel; level++) {
      for (final cosmeticId in _table.cosmeticsForLevel(level)) {
        if (_alreadyUnlocked(cosmetics, cosmeticId)) continue;
        final sourceId = 'level_$level';
        final didUnlock = await _unlock(
          cosmetics,
          cosmeticId: cosmeticId,
          sourceType: CosmeticUnlockSource.progressionLevel.name,
          sourceId: sourceId,
        );
        if (didUnlock) {
          unlockedItems.add(
            CosmeticUnlockDispatchItem(
              cosmeticId: cosmeticId,
              sourceType: CosmeticUnlockSource.progressionLevel.name,
              sourceId: sourceId,
            ),
          );
        }
      }
    }

    // -- Pass 3: Tier-2 rule evaluator (bounded fixed-point) ---------------
    for (var iteration = 0; iteration < _kMaxTier2Iterations; iteration++) {
      final ownedIds = cosmetics.state?.unlocked.keys.toSet() ?? <String>{};
      final snapshot = _snapshotExtractor.extract(
        state: current,
        ownedCosmeticIds: ownedIds,
      );
      final tuples = _evaluator.evaluate(snapshot, ownedIds);
      if (tuples.isEmpty) break;

      for (final tuple in tuples) {
        final didUnlock = await _unlock(
          cosmetics,
          cosmeticId: tuple.cosmeticId,
          sourceType: tuple.sourceType,
          sourceId: tuple.sourceId,
        );
        if (didUnlock) {
          unlockedItems.add(
            CosmeticUnlockDispatchItem(
              cosmeticId: tuple.cosmeticId,
              sourceType: tuple.sourceType,
              sourceId: tuple.sourceId,
            ),
          );
          _log.info(
            'tier-2 rule unlocked',
            payload:
                'id=${tuple.cosmeticId} via=${tuple.sourceType}/${tuple.sourceId} pass=$iteration',
          );
        }
      }
    }

    return CosmeticUnlockDispatchResult(items: unlockedItems);
  }

  bool _alreadyUnlocked(CosmeticsProvider cosmetics, String cosmeticId) {
    return cosmetics.state?.unlocked.containsKey(cosmeticId) ?? false;
  }

  Future<bool> _unlock(
    CosmeticsProvider cosmetics, {
    required String cosmeticId,
    required String sourceType,
    String? sourceId,
  }) async {
    final alreadyUnlocked = _alreadyUnlocked(cosmetics, cosmeticId);
    _log.info(
      'unlock attempt',
      payload:
          'id=$cosmeticId source=$sourceType:${sourceId ?? '-'} alreadyUnlocked=$alreadyUnlocked',
    );
    try {
      await cosmetics.unlock(
        cosmeticId,
        sourceType: sourceType,
        sourceId: sourceId,
      );
      // CosmeticsProvider catches CosmeticsException and stores it in
      // errorMessage; surface it here so a bad mapping is visible in logs.
      final error = cosmetics.errorMessage;
      if (error != null) {
        _log.warn(
          'unlock reported error',
          payload: 'id=$cosmeticId source=$sourceType code=$error',
        );
        return false;
      }
      return !alreadyUnlocked;
    } catch (e, st) {
      _log.error(
        'unlock crashed',
        payload: 'id=$cosmeticId source=$sourceType',
        err: e,
        stackTrace: st,
      );
      return false;
    }
  }
}
