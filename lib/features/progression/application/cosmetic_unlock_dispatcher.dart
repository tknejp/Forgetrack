import '../../../core/logging/app_log.dart';
import '../../cosmetics/application/cosmetics_provider.dart';
import '../../cosmetics/domain/cosmetic_models.dart';
import '../../cosmetics/domain/cosmetic_unlock_evaluator.dart';
import '../../cosmetics/domain/cosmetic_unlock_rules.dart';
import '../domain/models/quest_models.dart';
import '../domain/policy/level_config.dart';
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
/// unlocks. There are four passes per call:
///
/// 1. **Tier-1 achievement catch-up** — every currently-unlocked achievement
///    is checked against its own `cosmeticRewards`; any cosmetic not yet in
///    the player's `unlocked` map is granted. This catches up users whose
///    achievement was unlocked before a new mapping was added (or for whom
///    `previous == null` on cold start).
/// 2. **Tier-1 level catch-up** — same idea using
///    [cosmeticsForLevel] (which reads off [ProgressionLevelTier]
///    or the decorative-level map) iterated 1..currentLevel.
/// 3. **Tier-1 quest catch-up** — same idea using
///    `quest.cosmeticRewards` for every claimed quest grant.
/// 4. **Tier-2 rule evaluator** — runs in a bounded fixed-point loop so
///    compound rules whose dependencies were just granted by passes 1–3
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
    CosmeticUnlockSnapshotExtractor? snapshotExtractor,
    CosmeticUnlockEvaluator? evaluator,
  })  : _snapshotExtractor =
            snapshotExtractor ?? CosmeticUnlockSnapshotExtractor(),
        _evaluator = evaluator ?? CosmeticUnlockEvaluator(kCosmeticUnlockRules);

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
    // Reads `cosmeticRewards` directly off the runtime achievement (which is
    // mirrored from the catalog definition). One source of truth: adding a
    // cosmetic drop to an achievement is one catalog edit.
    final unlockedAchievements =
        current.achievements.where((a) => a.unlocked).toList(growable: false);
    for (final achievement in unlockedAchievements) {
      for (final cosmeticId in achievement.cosmeticRewards) {
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
    // Level cosmetics live on the level tier (anchor levels) or the
    // decorative-level map; [cosmeticsForLevel] hides that distinction so
    // the dispatcher just iterates 1..currentLevel.
    final currentLevel = current.profile.level;
    for (var level = 1; level <= currentLevel; level++) {
      for (final cosmeticId in cosmeticsForLevel(level)) {
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

    // -- Pass 3: quest catch-up --------------------------------------------
    // Reads `cosmeticRewards` from the runtime quest (mirrored from the
    // catalog). Index quests by id so we can resolve from claimed grants
    // without iterating the whole list per grant.
    final questsById = <String, ProgressionQuest>{
      for (final quest in current.quests) quest.id: quest,
    };
    final claimedQuestIds = current.questRewardGrants
        .where((grant) => grant.isClaimed)
        .map((grant) => grant.questId)
        .toSet();
    for (final questId in claimedQuestIds) {
      final quest = questsById[questId];
      if (quest == null) continue;
      for (final cosmeticId in quest.cosmeticRewards) {
        if (_alreadyUnlocked(cosmetics, cosmeticId)) continue;
        final didUnlock = await _unlock(
          cosmetics,
          cosmeticId: cosmeticId,
          sourceType: CosmeticUnlockSource.quest.name,
          sourceId: questId,
        );
        if (didUnlock) {
          unlockedItems.add(
            CosmeticUnlockDispatchItem(
              cosmeticId: cosmeticId,
              sourceType: CosmeticUnlockSource.quest.name,
              sourceId: questId,
            ),
          );
        }
      }
    }

    // -- Pass 4: Tier-2 rule evaluator (bounded fixed-point) ---------------
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
